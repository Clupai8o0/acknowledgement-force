# Force — Roadmap

Two parallel tracks: a public API + MCP server, and a native Android client with system-wide app blocking. Both build on the existing Next.js + Supabase web app (single `contents` row per user containing `contract_md`, `quotes[]`, `goals[]`, `reflection`).

Product framing: Force is a personal accountability app. Users write a contract with themselves, collect motivational quotes, set goals, and reflect daily. The Android app additionally blocks distracting apps until the user re-acknowledges their contract.

---

## Track 1 — MCP server + API keys

**Goal:** generate an API key in the web app, paste it into Claude (or any MCP client), read/update contract, quotes, goals, reflection.

### A. Database — new migration `web/supabase/migrations/0002_api_keys.sql`

```
api_keys
  id            uuid pk
  user_id       uuid references auth.users(id) on delete cascade
  name          text                       -- "Claude Desktop", "Personal laptop"
  prefix        text  not null             -- "fc_live_a1b2"  (shown in UI)
  key_hash      text  not null unique      -- sha256(raw_key)
  scopes        text[] not null default '{contract:read,contract:write,quotes:read,quotes:write,goals:read,goals:write,reflection:read,reflection:write}'
  last_used_at  timestamptz
  expires_at    timestamptz                -- nullable
  revoked_at    timestamptz                -- nullable
  created_at    timestamptz default now()
```

RLS: users can only see their own rows (`auth.uid() = user_id`). Inserts/revokes happen via the web app under a normal session — no service role from the browser.

### B. Web — settings UI

New routes under `web/app/settings/`:

- `settings/layout.tsx` — sidebar shell (room for account/billing later)
- `settings/api-keys/page.tsx` — list + create + revoke
  - **Create form:** name (required), scope checkboxes (default all on), optional expiry
  - **On create:** generate `fc_live_<24-byte-base62>`, hash with sha256, insert row, return raw key once — display in a modal with copy button and "you won't see this again" warning. Never store raw.
  - **List:** name, prefix + `••••last4`, scopes, last used, created, revoke button
- Add an "API keys" entry to the nav (the editor currently has only a logout button — settle on a single nav source)

### C. Web — public HTTP API (`web/app/api/v1/`)

All routes guarded by the same middleware.

```
GET    /api/v1/me                       → { user_id, email }
GET    /api/v1/contract                 → { contract_md, updated_at }
PUT    /api/v1/contract                 → body: { contract_md }
GET    /api/v1/quotes                   → { quotes: Quote[] }
POST   /api/v1/quotes                   → body: { text, author? }
DELETE /api/v1/quotes/:id
GET    /api/v1/goals                    → { goals: Goal[] }
PUT    /api/v1/goals                    → body: { goals: Goal[] }     (replace-all; simpler than diff)
GET    /api/v1/reflection               → { reflection, updated_at }
PUT    /api/v1/reflection               → body: { reflection }
```

**Middleware** (`web/lib/auth/apiKey.ts`):

1. Pull `Authorization: Bearer fc_...` header
2. sha256 the raw key, look up in `api_keys` where `revoked_at is null and (expires_at is null or expires_at > now())`
3. Check scope matches the route; return 401/403 otherwise
4. Update `last_used_at` (debounced — at most every 60s per key)
5. Return `{ userId, scopes }` for the route to use

**Supabase client inside route handlers:** use the service role key from server env, scope every query with `.eq("user_id", userId)`. RLS isn't doing the work here — we resolved the user ourselves.

### D. MCP server — new top-level `mcp/` directory (separate package)

- Node + TypeScript, `@modelcontextprotocol/sdk`
- Thin client wrapping `/api/v1/*`, used by all tools
- **Tools** (1:1 with API methods, plus a couple of conveniences):
  - `get_contract`, `update_contract`
  - `list_quotes`, `add_quote`, `delete_quote`
  - `list_goals`, `set_goals`
  - `get_reflection`, `set_reflection`
  - `append_to_contract` (convenience — read, append, write) so the model doesn't have to round-trip
- **Config:** reads `FORCE_API_KEY` and `FORCE_API_BASE` (default `https://force.app`) from env
- **Phase 1 — local stdio:** `npx -y @force/mcp`. Claude Desktop config:
  ```json
  {
    "mcpServers": {
      "force": { "command": "npx", "args": ["-y", "@force/mcp"], "env": { "FORCE_API_KEY": "fc_live_..." } }
    }
  }
  ```
- **Phase 2 — hosted:** same server, HTTP/SSE transport, deployed (Vercel or Fly). Users add `{ "url": "https://mcp.force.app", "headers": { "Authorization": "Bearer fc_live_..." } }`. No infra needed until phase 1 has users.

### E. Phasing

1. Migration + middleware + `/api/v1/contract` end-to-end (one route proves the pattern)
2. Remaining `/api/v1/*` routes
3. Settings UI
4. MCP package (local stdio)
5. Publish to npm + docs
6. *(later)* Hosted MCP

### Open questions

- Single scope set vs. per-resource (current plan does per-resource — keep?)
- Do you want key expiry now or punt (default to never-expires for simplicity)?
- Package name on npm — `@force/mcp`, `force-mcp`, something else?

---

## Track 2 — Android (Kotlin) client with system-wide blocking

**Goal:** native Android app that (a) lets the user view/edit their Force content and (b) detects when a blocked app launches and overlays a full-screen acknowledgement of their contract + today's quote until they confirm.

### A. Project shape

New top-level `android/` directory, Gradle multi-module:

```
android/
  settings.gradle.kts
  build.gradle.kts            (root)
  app/                        (UI module, depends on :data + :blocking)
  data/                       (Supabase client, repositories, models)
  blocking/                   (AccessibilityService, overlay, foreground service)
```

Single product flavor at first. Min SDK 26 (overlay APIs), target current.

### Tech stack

- **Kotlin** + **Jetpack Compose** + Material 3
- **DI:** Hilt
- **Auth + DB:** [supabase-kt](https://github.com/supabase-community/supabase-kt) — `auth-kt` + `postgrest-kt`. Reuses existing email/password accounts; RLS protects data. No need to involve the new API-key system on mobile (the user is signed in as themselves).
- **Token storage:** `EncryptedSharedPreferences` (or DataStore + Tink)
- **Settings storage:** Proto DataStore — blocked apps, schedule, cooldown
- **Async:** Kotlin coroutines + Flow

### B. Screens (Compose)

1. **Auth** — login + signup (email/password, same as web)
2. **Home** — today's contract preview, quotes carousel, goals checklist (toggle done), reflection textfield. Pull-to-refresh, auto-save with debounce.
3. **Blocklist** — picker of installed apps with search; per-app toggle
4. **Block settings** — schedule (start/end time, days), cooldown duration (default e.g. 5 min), acknowledgement gesture choice
5. **Permissions onboarding** — explainer cards that deep-link into system settings for each permission (overlay, accessibility, usage stats, notifications). Each card shows green check once granted.
6. **Account** — email, sign out

### C. Native blocking architecture

Three components working together:

```
[ForceAccessibilityService]
  - subscribes to TYPE_WINDOW_STATE_CHANGED
  - on event: read event.packageName
  - if pkg ∈ blocklist
       AND within active schedule
       AND not in cooldown
    → startActivity(BlockOverlayActivity, NEW_TASK | CLEAR_TOP)
  - writes ack timestamps to DataStore (starts cooldown)

[BlockOverlayActivity]
  - full-screen Compose UI: contract markdown + today's quote
  - acknowledgement gesture: scroll through full contract, then type a short phrase
    (more friction = better; configurable)
  - on ack: write cooldown timestamp for that package, finish(); user returns to original app

[ForceForegroundService]
  - persistent low-priority notification "Force is watching"
  - keeps the process alive across Doze
  - holds the in-memory cooldown map + schedule
```

Plus:

- `BootCompletedReceiver` → re-arms the foreground service after reboot
- `PackageReplacedReceiver` → re-arms after app update
- Optional `UsageStatsManager` for an "apps opened today" stat on Home

### Permissions (Manifest)

- `SYSTEM_ALERT_WINDOW`
- `BIND_ACCESSIBILITY_SERVICE` (declared on the service; user grants via Settings)
- `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE` (Android 14+; verify category against current Play policy)
- `POST_NOTIFICATIONS` (Android 13+)
- `RECEIVE_BOOT_COMPLETED`
- `PACKAGE_USAGE_STATS` (optional)
- `QUERY_ALL_PACKAGES` (needed for the blocklist picker; Play requires you justify it in store listing)

### D. Phasing

1. **P0** — Gradle scaffold, Compose theming, Supabase auth, Home screen reading/writing `contents` via supabase-kt
2. **P1** — Settings screens, blocklist picker, permission onboarding flow
3. **P2** — AccessibilityService + BlockOverlayActivity + ForegroundService + cooldown logic. Test on a real device — emulators are unreliable for overlays.
4. **P3** — Polish: schedules, stats, share quote, widgets, daily reflection reminder

### Open issues / risks

- **Play Store review:** apps using `AccessibilityService` for non-accessibility purposes get reviewed harder. Need a clear in-app explainer of why the service is needed, plus a video for review. Real risk of rejection; have a fallback distribution plan (sideload + maybe Samsung Galaxy Store).
- **OEM aggressiveness:** Xiaomi/Oppo/Vivo kill background services aggressively. Foreground service + battery-optimization-exemption prompt + clear instructions will be needed.
- **Acknowledgement design** is the product question, not the engineering one. Too easy = no impact. Too hard = users uninstall. Suggest making the gesture configurable from day one.
- **Reusing API keys on mobile** is technically possible but worse UX (would require web login + paste). Recommend direct Supabase auth; API keys stay for programmatic/3rd-party clients (MCP, future Zapier, etc).

---

## Track 3 — Force Guide (optional, future)

**Goal:** an in-app chatbot that knows your contract and can answer questions to help you stay aligned.

### Concept

A conversational assistant embedded in the web (and eventually Android) app. The user can ask things like "am I staying true to my goals?", "what does my contract say about X?", or "help me think through this decision." The guide has full read access to the user's contract, quotes, goals, and reflection — no manual copy-paste.

### Implementation sketch

- **API route:** `POST /api/v1/guide/chat` — accepts `{ messages: Message[] }`, streams a response. Server-side, it prefixes the conversation with a system prompt that injects the user's current contract, goals, and quotes.
- **Model:** Claude (Anthropic SDK), streaming via SSE. System prompt is built fresh per request from the user's `contents` row so it always reflects the latest contract.
- **UI:** a chat drawer or dedicated `/guide` route. Minimal — message list + input. No history persistence required in v1 (stateless per session).
- **Auth:** same session cookie as the rest of the web app. No new API-key scope needed for this feature.

### Scope boundaries (keep it simple)

- Read-only access to user data inside the system prompt — the guide does not write back to the contract
- No persistent chat history in the database (v1)
- No tool calls or agentic behavior — pure conversational assistant

### Phasing

1. Backend: `/api/v1/guide/chat` route with streaming, contract injection
2. Web UI: chat panel (drawer or page), basic message rendering + markdown support
3. Android: same endpoint, native chat UI in a new screen
4. *(later)* Persistent history, context-aware suggestions, proactive nudges

---

## Suggested execution order across both tracks

1. Track 1 — step E.1 (migration + middleware + one `/api/v1/contract` route). Proves the API-key pattern, unblocks the rest of Track 1.
2. Track 1 — step E.2–E.3 (remaining routes + settings UI). Users can now create keys.
3. Track 1 — step E.4–E.5 (MCP package, local stdio). Shippable to early users.
4. Track 2 in parallel from this point — Android client uses Supabase auth directly, doesn't depend on Track 1.
