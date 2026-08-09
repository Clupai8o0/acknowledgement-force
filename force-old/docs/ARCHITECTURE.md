# Force — Swift architecture

The Swift codebase is one SwiftPM package with three targets, layered so that
everything that *can* be platform-neutral *is*:

```
┌────────────────────┐   ┌─────────────────────┐
│  Force (macOS app) │   │  ForceCLI (Linux /  │
│  SwiftUI + AppKit  │   │  Windows / macOS)   │
└─────────┬──────────┘   └──────────┬──────────┘
          │                         │
          └──────────┬──────────────┘
                     ▼
            ┌─────────────────┐
            │    ForceKit     │  pure Foundation, no UI
            └─────────────────┘
```

## ForceKit (`Sources/ForceKit`)

Platform-agnostic core. Pure Foundation (plus `FoundationNetworking` on
Linux/Windows); no SwiftUI, no AppKit, no singletons.

| Area | Files | Responsibility |
| --- | --- | --- |
| Models | `Models/Models.swift` | `Acknowledgement`, `HistoryEntry`, `NonNegotiable`, `Frequency`, default copy |
| Dates | `Models/AppDate.swift` | Canonical `yyyy-MM-dd` day keys + display formats |
| Contract | `Models/Contract.swift` | Markdown → `[ContractBlock]` parser, `{{DATE}}`/`{{NAME}}` substitution, default contract |
| Gate | `Engine/AcknowledgementGate.swift` | Pure policy: is the contract locked right now? |
| Journal | `Engine/AcknowledgementJournal.swift` | Acknowledgements, 30-day history, daily checklist persistence |
| Persistence | `Persistence/KeyValueStore.swift` | `KeyValueStore` protocol + `UserDefaults` adapter + JSON-file store (0600) |
| Settings | `Persistence/SettingsStorage.swift` | Typed accessors over the persisted settings keys |
| Sync | `Sync/SupabaseClient.swift` | Stateless HTTPS client for GoTrue + PostgREST (HTTPS enforced) |
| Sync | `Sync/SyncEngine.swift` | Session lifecycle: login/logout, refresh-on-401-once, fetch/push |
| Sync | `Sync/SessionStore.swift` | `SessionStore` protocol + owner-only file implementation |
| Sync | `Sync/SupabaseConfig.swift` | Build-time baked connection (placeholders substituted by `install.sh`) |

Design rules:

- **Dependency inversion.** Engines depend on `KeyValueStore` / `SessionStore`
  protocols, never concrete storage. Front ends choose the implementation
  (UserDefaults + Keychain on macOS, JSON files on Linux/Windows).
- **Pure policy.** `AcknowledgementGate` takes every input as a parameter
  (clock included) — no hidden reads, trivially testable, identical behaviour
  on every platform.
- **Storage-key compatibility.** `SettingsStorage` and
  `AcknowledgementJournal` reuse the original `af-*` UserDefaults keys, so a
  pre-refactor macOS install keeps all of its data.
- **Credentials are special.** Sessions only move through `SessionStore`
  implementations (Keychain / 0600 file); they never touch UserDefaults or
  world-readable plists.

## Force (`Sources/Force`, macOS only)

The SwiftUI app. The Package manifest declares this target only when evaluated
on macOS, so `swift build` on Linux/Windows never sees it.

- `Store`, `SettingsStore`, `RemoteSync` are thin `@MainActor
  ObservableObject` façades over ForceKit: they add `@Published` state,
  platform side effects (LaunchAgent install, gate re-check on app
  activation), and UI status — the logic itself lives in the kit.
- `Support/KeychainSessionStore.swift` keeps the Supabase session in the
  Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`). `RemoteSync`
  migrates legacy plaintext UserDefaults tokens into the Keychain once, then
  scrubs them.
- Views (`RootView`, `ContractView`, `AppView`, …), the design system
  (`DesignSystem.swift`, `Theme.swift`), single-instance handling, and the
  launchd integration are macOS-specific by nature and stay here.

## ForceCLI (`Sources/ForceCLI`, all platforms)

`force-cli` — the Linux/Windows version of Force (also handy on macOS for
scripting). ~4 small files:

- `ForceCLIMain.swift` — command dispatch (`status`, `contract`, `ack`,
  `check`, `history`, `login`, `logout`, `sync`, `config`).
- `CLIEnvironment.swift` — wires ForceKit stores to the per-user state
  directory (`FORCE_STATE_DIR` override).
- `ContractRenderer.swift` — `[ContractBlock]` → terminal text (ANSI when
  stdout is a TTY).
- `Terminal.swift` — prompts, no-echo password input (POSIX termios).

Semantics that differ from the GUI, by design:

- Each invocation is a fresh process, so `everyLaunch`/`onLogin` frequencies
  always require an acknowledgement.
- The CLI never edits synced fields, so `sync` is pull-only.
- `status` exits with code 3 while locked, so schedulers/shell profiles can
  enforce the gate (`force-cli status || force-cli ack`).

## Sync security model

- The app talks **directly to Supabase** over HTTPS (enforced in
  `SupabaseClient.init`): GoTrue for email+password auth, PostgREST for the
  `contents` row. Row-level security scopes every query to the signed-in
  user; the client additionally filters on `user_id` as defense in depth.
- The **anon key is public by design** — safe to bake into binaries. The
  session tokens are the real credential: Keychain on macOS, 0600 file
  elsewhere, never in UserDefaults.
- Logout revokes the session server-side (best effort) and always clears the
  local credential.
