# Force — Android

A Kotlin/Jetpack Compose port of the macOS Acknowledgement Force app. Same
"Digital Curator" design system, same daily-contract gating, same Supabase
sync, packaged for Android phones.

## What's included

- **Onboarding** — five-step intro mirroring the macOS flow.
- **Daily contract** — Markdown-rendered contract with scroll-to-unlock,
  acknowledgement checkbox, and today's single highest-leverage action.
- **Dashboard** — today's action card, non-negotiables checklist with progress
  badge, reflection block (web-edited), motivation quote, contract preview.
- **History** — last seven acknowledged actions.
- **Settings** — profile, appearance (light/dark/follow-system, swatch preview),
  schedule (every-launch → weekly), Supabase sync (email/password login, push,
  pull, edit-connection), contract editor, non-negotiable list, emergency stop.

## Project layout

```
android/
├── app/
│   ├── build.gradle.kts
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── java/com/clupai/force/
│       │   ├── ForceApp.kt              ⟵ Application — singletons live here
│       │   ├── MainActivity.kt          ⟵ root composition + RootRouter
│       │   ├── AppDeps.kt
│       │   ├── data/                    ⟵ models, Contract parser, stores, RemoteSync
│       │   └── ui/
│       │       ├── theme/               ⟵ Theme/ThemeManager, tokens, buttons, components
│       │       ├── components/          ⟵ InlineText, ContractBlocks (shared)
│       │       └── screens/             ⟵ Onboarding/Contract/Dashboard/History/Settings
│       └── res/
│           ├── font/                    ⟵ Fraunces, Inter (TTF)
│           └── values/                  ⟵ strings.xml, themes.xml
├── build.gradle.kts
├── settings.gradle.kts
├── gradle/libs.versions.toml
└── gradle/wrapper/gradle-wrapper.properties
```

## Build & run

Open the `android/` directory in **Android Studio (Ladybug or newer)**. Studio
will sync Gradle and fetch the wrapper jar automatically. Then **Run ▸ app**
against an emulator or a physical device on Android 8.0 (API 26) or newer.

To build from the command line you first need to materialise the Gradle wrapper
jar (only required once; Studio does this for you):

```sh
cd android
gradle wrapper                  # any local Gradle ≥ 8.10 will do
./gradlew assembleDebug
```

The debug APK lands at `app/build/outputs/apk/debug/app-debug.apk`.

## Supabase sync

By default the app ships with empty `SUPABASE_URL` / `SUPABASE_ANON_KEY` build
config fields, so out-of-the-box sync shows "Needs config" and prompts the user
to enter their own project URL and anon key in Settings → Sync. To bake-in
defaults for a hosted distribution, edit `app/build.gradle.kts`:

```kotlin
buildConfigField("String", "SUPABASE_URL", "\"https://yourproject.supabase.co\"")
buildConfigField("String", "SUPABASE_ANON_KEY", "\"eyJhbGc…\"")
```

This mirrors the macOS `SupabaseConfig.swift` mechanism. User-entered overrides
in Settings always win over the build-time defaults.

The expected Supabase schema is the same `contents` table that the macOS app
and web editor use: `contract_md text`, `quotes text[]`, `goals jsonb`,
`reflection text`, `updated_at timestamptz`, plus RLS that scopes rows to the
authenticated `user_id`.

## Design system

Token names and values match the macOS port one-to-one:

| Swift                       | Kotlin                                  |
|-----------------------------|-----------------------------------------|
| `Ink.base`, `Ink.bright`…   | `LocalInk.current.base`, `.bright`…     |
| `Type.display(44)`          | `AppType.display(44)`                   |
| `Type.headingXL`            | `AppType.headingXL`                     |
| `Space.lg`, `Radius.md`     | `Space.lg`, `Radius.md`                 |
| `PrimaryPillStyle`          | `PrimaryButton`                         |
| `SecondaryPillStyle`        | `SecondaryButton`                       |
| `GhostTextStyle`            | `GhostTextButton`                       |
| `TonalCard`                 | `TonalCard`                             |
| `primaryGradient`           | `primaryGradient()`                     |
| `ThemeManager.shared`       | `LocalAppDeps.current.themeManager`     |

## What differs from macOS

- **No LaunchAgent.** Background relaunch on a schedule is a desktop concept;
  on Android the schedule field controls the in-app gate only. Hooking it up
  to `WorkManager` for periodic notifications is a natural follow-up.
- **No app-quit gate.** Android can't prevent its own task from being swiped
  away. Emergency stop calls `Process.killProcess(myPid())`.
- **No system color picker.** Settings shows colour swatches read-only; the
  underlying `ThemeManager.updateActive` API is in place and can drive a Compose
  colour picker (e.g. `ColorPickerDialog`) if you want full parity.
- **Layout is single-column.** The macOS sidebar is folded into a stacked
  dashboard better suited to phone widths.
