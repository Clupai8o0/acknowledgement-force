// Lightweight in-memory rate limiter (fixed window) for the public API.
//
// Scope and honesty: this protects a single serverless instance / dev server.
// It reliably blunts brute-force loops and naive bots, but it is NOT
// distributed DDoS protection — instances don't share memory. Volumetric
// protection belongs at the platform edge (Vercel WAF / Attack Challenge
// Mode, or Cloudflare in front); see docs/SECURITY.md. For distributed
// API rate limiting, swap this for Upstash Ratelimit or Vercel KV.

type Window = { count: number; resetAt: number };

const windows = new Map<string, Window>();

/** Caps map growth if something sprays unique keys at us. */
const MAX_TRACKED_KEYS = 10_000;

export type RateLimitResult = {
  ok: boolean;
  /** Seconds until the window resets — for the Retry-After header. */
  retryAfterSeconds: number;
};

/**
 * Counts a hit against `key` and reports whether it stays within `limit`
 * per `windowMs` window.
 */
export function rateLimit(
  key: string,
  limit: number,
  windowMs: number
): RateLimitResult {
  const now = Date.now();
  const current = windows.get(key);

  if (!current || current.resetAt <= now) {
    if (windows.size >= MAX_TRACKED_KEYS) windows.clear();
    windows.set(key, { count: 1, resetAt: now + windowMs });
    return { ok: true, retryAfterSeconds: 0 };
  }

  current.count += 1;
  if (current.count > limit) {
    return {
      ok: false,
      retryAfterSeconds: Math.ceil((current.resetAt - now) / 1000),
    };
  }
  return { ok: true, retryAfterSeconds: 0 };
}

/** Best-effort client IP for rate-limit keys (Vercel sets x-forwarded-for). */
export function clientIp(req: Request): string {
  const fwd = req.headers.get("x-forwarded-for");
  if (fwd) return fwd.split(",")[0].trim();
  return req.headers.get("x-real-ip") ?? "unknown";
}

/** 429 response with a Retry-After header. */
export function tooManyRequests(retryAfterSeconds: number): Response {
  return Response.json(
    { error: "Too many requests" },
    {
      status: 429,
      headers: { "Retry-After": String(Math.max(1, retryAfterSeconds)) },
    }
  );
}
