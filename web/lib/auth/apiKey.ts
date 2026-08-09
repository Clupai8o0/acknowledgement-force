import { createAdminClient } from "@/lib/supabase/admin";
import { hashKey, type Scope } from "@/lib/api-keys";
import { clientIp, rateLimit } from "@/lib/rate-limit";

export type AuthOk = {
  ok: true;
  userId: string;
  scopes: string[];
  keyId: string;
};

export type AuthErr = {
  ok: false;
  status: number;
  error: string;
  retryAfterSeconds?: number;
};

const LAST_USED_DEBOUNCE_MS = 60_000;
const lastTouch = new Map<string, number>();

// Per-IP budgets for the public API (best-effort per instance; volumetric
// protection lives at the platform edge — see docs/SECURITY.md).
const REQUESTS_PER_MINUTE = 120;
// Much tighter budget for *failed* auth: a valid key never trips this, while
// a brute-force loop or key-spraying bot does almost immediately.
const FAILURES_PER_MINUTE = 10;
const WINDOW_MS = 60_000;

export async function authenticate(
  req: Request,
  required: Scope | null
): Promise<AuthOk | AuthErr> {
  const ip = clientIp(req);

  const overall = rateLimit(`api:${ip}`, REQUESTS_PER_MINUTE, WINDOW_MS);
  if (!overall.ok) {
    return {
      ok: false,
      status: 429,
      error: "Too many requests",
      retryAfterSeconds: overall.retryAfterSeconds,
    };
  }

  const header = req.headers.get("authorization") ?? "";
  const match = header.match(/^Bearer\s+(\S+)$/i);
  if (!match) {
    return failure(ip, "Missing bearer token");
  }
  const raw = match[1];
  const supabase = createAdminClient();
  const hash = hashKey(raw);

  const { data, error } = await supabase
    .from("api_keys")
    .select("id, user_id, scopes, revoked_at, expires_at")
    .eq("key_hash", hash)
    .maybeSingle();

  // Uniform message for unknown, revoked, and expired keys: telling a caller
  // a key is "revoked" confirms that a leaked old key used to be valid.
  if (error || !data || data.revoked_at) {
    return failure(ip, "Invalid API key");
  }
  if (data.expires_at && new Date(data.expires_at).getTime() <= Date.now()) {
    return failure(ip, "Invalid API key");
  }

  const scopes = (data.scopes as string[]) ?? [];
  if (required && !scopes.includes(required)) {
    return {
      ok: false,
      status: 403,
      error: `Key is missing the '${required}' scope`,
    };
  }

  const now = Date.now();
  const last = lastTouch.get(data.id) ?? 0;
  if (now - last >= LAST_USED_DEBOUNCE_MS) {
    lastTouch.set(data.id, now);
    // Awaited: last_used_at is the user's audit trail for spotting a stolen
    // key. A fire-and-forget write can be dropped when the serverless
    // function freezes right after responding.
    const { error: touchErr } = await supabase
      .from("api_keys")
      .update({ last_used_at: new Date(now).toISOString() })
      .eq("id", data.id);
    if (touchErr) console.error("[auth] last_used_at update failed:", touchErr.message);
  }

  return {
    ok: true,
    userId: data.user_id as string,
    scopes,
    keyId: data.id as string,
  };
}

/** Counts a failed auth against the per-IP failure budget and returns 401 —
 * or 429 once the budget is exhausted. */
function failure(ip: string, message: string): AuthErr {
  const failures = rateLimit(`api-fail:${ip}`, FAILURES_PER_MINUTE, WINDOW_MS);
  if (!failures.ok) {
    return {
      ok: false,
      status: 429,
      error: "Too many requests",
      retryAfterSeconds: failures.retryAfterSeconds,
    };
  }
  return { ok: false, status: 401, error: message };
}

export function authError(auth: AuthErr): Response {
  const headers: Record<string, string> = {};
  if (auth.status === 429) {
    headers["Retry-After"] = String(Math.max(1, auth.retryAfterSeconds ?? 1));
  }
  return Response.json({ error: auth.error }, { status: auth.status, headers });
}
