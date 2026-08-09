// Shared helpers for the /api/v1 route handlers.

/** Hard ceiling on request bodies. Contract/reflection text tops out well
 * below this; anything bigger is abuse, not content. */
export const MAX_BODY_BYTES = 256 * 1024;

/** Per-field content limits enforced by the routes. */
export const LIMITS = {
  contractChars: 100_000,
  reflectionChars: 100_000,
  quoteChars: 500,
  maxQuotes: 200,
  maxGoals: 100,
  goalLabelChars: 200,
} as const;

/**
 * Parses a JSON request body with a size cap. Returns null for invalid JSON
 * or a body exceeding MAX_BODY_BYTES (checked against both the declared
 * Content-Length and the actual bytes read, since the header can lie).
 */
export async function readJson(
  req: Request
): Promise<Record<string, unknown> | null> {
  const declared = Number(req.headers.get("content-length") ?? 0);
  if (declared > MAX_BODY_BYTES) return null;
  try {
    const text = await req.text();
    if (text.length > MAX_BODY_BYTES) return null;
    return JSON.parse(text) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export function badRequest(message: string): Response {
  return Response.json({ error: message }, { status: 400 });
}

/**
 * Logs the real error server-side and returns a generic message — database
 * error strings leak schema details (constraint/column names) to clients.
 */
export function serverError(detail: string): Response {
  console.error("[api] server error:", detail);
  return Response.json({ error: "Internal error" }, { status: 500 });
}
