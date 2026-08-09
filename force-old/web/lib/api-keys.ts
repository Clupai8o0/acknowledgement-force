import { createHash, randomBytes } from "node:crypto";

export const KEY_PREFIX = "fc_live_";
export const RAW_SECRET_BYTES = 24;

export const ALL_SCOPES = [
  "contract:read",
  "contract:write",
  "quotes:read",
  "quotes:write",
  "goals:read",
  "goals:write",
  "reflection:read",
  "reflection:write",
] as const;

export type Scope = (typeof ALL_SCOPES)[number];

export function generateKey(): { raw: string; prefix: string; hash: string } {
  // base64url is URL-safe and avoids ambiguous characters; ~32 chars for 24
  // bytes — well above the 128-bit entropy threshold.
  const secret = randomBytes(RAW_SECRET_BYTES).toString("base64url");
  const raw = `${KEY_PREFIX}${secret}`;
  // Public prefix shown in the UI list: "fc_live_a1b2".
  const prefix = `${KEY_PREFIX}${secret.slice(0, 4)}`;
  const hash = hashKey(raw);
  return { raw, prefix, hash };
}

export function hashKey(raw: string): string {
  return createHash("sha256").update(raw).digest("hex");
}

export function maskKey(prefix: string): string {
  // "fc_live_a1b2" → "fc_live_a1b2••••"
  return `${prefix}••••`;
}
