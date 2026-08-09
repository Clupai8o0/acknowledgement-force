# Force — security model & hardening guide

How the pieces authenticate to each other, what the code enforces, and the
platform-level switches that complete the picture.

## Architecture & trust boundaries

```
macOS app / force-cli ──HTTPS──► Supabase (GoTrue auth + PostgREST, RLS)
web editor (browser)  ──HTTPS──► Next.js on Vercel ──► Supabase
MCP / scripts         ──HTTPS──► Next.js /api/v1/* (fc_live_ API keys)
```

- **Apps talk directly to Supabase** with the *public* anon key plus a per-user
  JWT from email+password login. Row-level security (`auth.uid() = user_id`)
  is the authorization boundary; clients additionally filter on `user_id` as
  defense in depth.
- **The /api/v1 routes** authenticate `fc_live_` keys by SHA-256 hash lookup
  (CSPRNG, 192-bit, hash-only storage, shown once at creation) and use the
  service-role client — every query is explicitly scoped to the key's user.

## What the code enforces

### Credentials at rest
- macOS: Supabase session lives in the **Keychain**
  (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`). Legacy plaintext
  UserDefaults tokens are migrated and scrubbed on first launch.
- CLI (Linux/Windows/macOS): session file written atomically with **0600**
  permissions. Logout revokes the session server-side (GoTrue `/logout`).
- `SupabaseClient` refuses non-HTTPS base URLs outright.

### Web/API input handling
- Request bodies capped at **256 KB** (`web/lib/api-utils.ts`), with per-field
  limits: contract/reflection 100k chars, quotes 500 chars × 200, goals
  100 × 200 chars with slug-validated ids.
- Database error messages are logged server-side and **never returned** to
  clients (generic `Internal error` / `Could not create the key`).
- Unknown, revoked, and expired API keys all return the same
  `401 Invalid API key` — no oracle for "this leaked key used to work".

### Abuse resistance (in code)
- Per-IP rate limiting on `/api/v1/*`: 120 req/min overall, **10 failed auth
  attempts/min** before 429 + `Retry-After` (`web/lib/rate-limit.ts`).
  In-memory and per-instance — it blunts brute force and naive bots, and is
  honest about not being distributed DDoS protection (see below).
- API keys are capped at **20 active per account**.

### Browser hardening
- Security headers on every route (`web/next.config.ts`): CSP (self-only
  scripts, Supabase-only connections), `frame-ancestors 'none'` +
  `X-Frame-Options: DENY` (the API-key reveal modal must never be framable),
  HSTS, `nosniff`, `Referrer-Policy`, `Permissions-Policy`.
- Supabase auth cookies are set `Secure` (production) and `SameSite=Lax`.
  They are signed JWTs, not secrets-in-plaintext; they **cannot be httpOnly**
  because the browser Supabase client reads them. If httpOnly cookies become
  a requirement, all auth flows must move into server actions first.
- Mutations go through Next server actions (built-in origin checks) or
  bearer-token routes (cookie-less) — minimal CSRF surface. No CORS headers
  are set on the API, so browsers can't make cross-origin authenticated calls.

## Platform switches to flip (not in code)

DDoS and sophisticated bot protection are edge concerns; do these once per
deployment:

1. **Vercel → Firewall**: enable **Attack Challenge Mode** during an attack;
   add WAF rules to challenge or rate-limit `/api/*` and `/login`/`/signup`
   beyond the in-code limits. (Vercel KV/Upstash can replace the in-memory
   limiter if/when the API needs distributed rate limiting.)
2. **Supabase → Auth → Rate limits**: tune the built-in per-IP limits for
   sign-in/sign-up/token-refresh (these protect the password endpoint the
   desktop apps use, which never touches our Next.js server).
3. **Supabase → Auth → Bot and abuse protection**: enable **CAPTCHA**
   (Turnstile/hCaptcha) on sign-up and password sign-in, and **leaked password
   protection**. Set the minimum password length ≥ 8 server-side (the signup
   form's check is client-side only).
4. **Distribution**: prefer Developer ID-signed + notarized builds for the
   macOS zip; `install.sh --package` now emits a SHA-256 alongside the zip —
   publish it next to the download.

## Reporting

Found something? Open a GitHub issue with minimal details and a way to reach
you privately, or email the maintainer. Don't post working exploits publicly.
