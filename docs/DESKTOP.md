# Force on Windows & Linux (`force-desktop`)

The native desktop GUI for Windows and Linux. It is an exact-behaviour port of
the macOS app — same lock screen, daily acknowledgement, checklist, history, and
re-lock schedule — built on the **same `ForceKit` core** the Mac app and CLI
use. The macOS client stays the `Force` SwiftUI target; this is a separate
`ForceDesktop` target so neither affects the other.

| Platform | Renderer | Source of truth |
|----------|----------|-----------------|
| macOS    | SwiftUI (`Force`) | `ForceKit` |
| Windows  | WinUI via SwiftCrossUI (`force-desktop`) | `ForceKit` |
| Linux    | GTK4 / libadwaita via SwiftCrossUI (`force-desktop`) | `ForceKit` |
| CLI      | Terminal (`force-cli`) | `ForceKit` |

## Why SwiftCrossUI

`ForceKit` is pure Foundation and already compiles on Windows and Linux (it
backs `force-cli`). The only missing piece on those platforms was a GUI, so the
desktop client is written in Swift against
[SwiftCrossUI](https://github.com/stackotter/swift-cross-ui) and links `ForceKit`
**directly**. There is no second copy of the gate/journal/sync logic — the
desktop app and the Mac app stay in lockstep by construction.

## Build & run

The GUI and its (large, platform-specific) dependency are **opt-in** so a bare
`swift build` keeps building only the portable targets. Enable it with the
`FORCE_DESKTOP=1` environment variable:

```sh
FORCE_DESKTOP=1 swift build --product force-desktop
FORCE_DESKTOP=1 swift run   force-desktop
```

### Linux prerequisites

GTK4 + libadwaita development packages:

```sh
# Debian / Ubuntu
sudo apt install libgtk-4-dev libadwaita-1-dev clang

# Fedora
sudo dnf install gtk4-devel libadwaita-devel clang

# Arch
sudo pacman -S gtk4 libadwaita
```

Then a Swift 6 toolchain from [swift.org](https://www.swift.org/install/linux/).

### Windows prerequisites

- Swift toolchain for Windows (swift.org) + Visual Studio Build Tools.
- The WinUI backend pulls the Windows App SDK headers via SwiftCrossUI's
  dependencies; building requires the Windows SDK to be installed.

```powershell
$env:FORCE_DESKTOP=1
swift build --product force-desktop
```

## State & sync

`force-desktop` shares its on-disk state with `force-cli` on the same machine
(so the two stay consistent), under:

- Linux: `~/.local/share/Force/` (or `$XDG_DATA_HOME`)
- Windows: `%APPDATA%\Force\`
- Override anywhere with `FORCE_STATE_DIR`.

Files: `state.json` (settings + journal) and `session.json` (Supabase session),
both written `0600` on POSIX. Cloud sync (contract / goals / quotes /
reflection) uses the same Supabase project as the web editor and the Mac app —
configure the URL + anon key and sign in from **Settings → Cloud Sync** in the
app.

## MVP scope & known gaps

This is the first iteration. It implements the full local loop — onboarding,
the locked contract, acknowledgement, the dashboard (checklist, today's action
with inline edit, motivation, contract, history), schedule selection, and
cloud login/sync. Not yet ported from the Mac app:

- **Scroll-to-bottom gate.** The Mac app unlocks acknowledgement only after you
  scroll the contract to the end; SwiftCrossUI 0.7 doesn't expose scroll
  position, so the desktop gate currently requires the checkbox + a non-empty
  action (the full contract is still shown).
- **Window-close gating.** The Mac app blocks closing the window until you
  acknowledge ("no escape"). Desktop closing the window quits; the gate still
  shows on next launch / re-lock.
- **Auto-launch on a schedule.** No XDG-autostart / Windows-startup entry yet
  (Mac uses a LaunchAgent). Re-lock still works while the app is running.
- **Inline bold, custom fonts, intro/focus animations.** SwiftCrossUI 0.7 has
  no rich-text runs or custom-font API, so `**bold**` inside a paragraph renders
  as plain text and the editorial Fraunces/Inter type is approximated with the
  system family at matching weights.
- **Single-instance lock** and native installers (`.msi` / `.deb` / AppImage)
  are future work — see packaging below.

## Packaging (next steps)

For distributable installers, [Swift Bundler](https://github.com/stackotter/swift-bundler)
(same author as SwiftCrossUI) produces `.app`/`.AppImage`/`.exe` bundles, or use
platform tooling (`.deb`/`.rpm` via fpm, MSIX/Inno Setup on Windows).
