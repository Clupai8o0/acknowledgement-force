# Acknowledgement Force

A daily contract for your Mac. Acknowledgement Force gates your screen behind
your own words: the window won't close until you've read today's contract,
ticked the box, and named the one thing that matters most. Free, open source,
and native to macOS.

Optionally, sign in to **sync your contract, quotes, goals, and reflection**
from a web editor — edit from anywhere and it lands on your Mac on launch.

It also ships with a **Focus mode** that puts today's highest-leverage action
on a quiet full-screen canvas.

![macOS](https://img.shields.io/badge/macOS-14%2B-black)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## Two ways to run it

**Hosted (no setup).** Download the prebuilt app (see Releases), create an
account at [force.clupai.com](https://force.clupai.com), and log in. It comes
pre-connected to the hosted backend — edit your contract on the web and it syncs
to your Mac. Best for non-technical users.

**Open source (your backend, or none).** Build from source below. Run it fully
local with no account, or point it at **your own Supabase project** so you own
all your data. Same app, your infrastructure. See
[Sync — edit from anywhere](#sync--edit-from-anywhere).

---

## Requirements

- macOS 14 (Sonoma) or newer, Apple Silicon or Intel
- Xcode or the Command Line Tools (provides the `swift` compiler):

  ```sh
  xcode-select --install
  ```

## Install

Clone the repo and run the installer. It builds a release binary, packages it
into a native `Acknowledgement Force.app`, and installs it.

```sh
git clone https://github.com/Clupai8o0/force.git
cd force
./install.sh
```

By default the app is installed to `~/Applications` (no `sudo` needed) and
launches when the build finishes.

| Command | What it does |
| --- | --- |
| `./install.sh` | Install to `~/Applications` |
| `./install.sh --system` | Install to `/Applications` (prompts for `sudo`) |
| `./install.sh --prefix DIR` | Install into a custom directory |
| `./install.sh --update` | Re-build and replace the existing install in place (auto-detects current location) |
| `./install.sh --no-open` | Don't launch the app after installing |
| `./install.sh --replace-others` | Remove copies in other locations without asking |
| `./install.sh --keep-others` | Leave copies in other locations in place |
| `./install.sh --package` | Build a shareable `.zip` in `./dist` instead of installing |

`install.sh` is safe to re-run — it cleanly replaces any previous copy, so it
doubles as the upgrade path. For the ergonomic one-liner upgrade, use
`./install.sh --update`: it finds your current install (in `~/Applications`,
`/Applications`, or any custom prefix you've used before) and refreshes it in
place without prompts.

### No accidental duplicates

Before installing, the script checks the common locations (`~/Applications`,
`/Applications`) and anywhere it has installed before for an existing
`Acknowledgement Force.app` outside the current target. If it finds one — e.g.
you ran the default once and `--system` later — it offers to remove the stray
copy so you don't accumulate duplicates. In an interactive shell it asks;
otherwise pass `--replace-others` or `--keep-others` to decide up front.

Note that even if duplicate bundles exist on disk, the app enforces a
single-instance lock at runtime, so only one copy can ever actually run.

> The app is **ad-hoc signed** for local use. It is not notarized, so if you
> move the `.app` to another Mac, Gatekeeper may warn you. Building from source
> on the target machine (the steps above) avoids that.

## Usage

1. Launch **Acknowledgement Force** from Spotlight or Launchpad.
2. Read the day's contract, tick the acknowledgement box, and write your single
   highest-leverage action. The window stays locked until you do.
3. Once acknowledged, the gate opens and you can close the window.

### Focus mode

On the dashboard, the today's-action card has a small **Focus** button. It
expands the action into a quiet, full-canvas view — just the words, a
breathing radial wash, and your signature. Press **ESC** to come back.

### Auto-launch

Enable auto-launch from the app's onboarding screen or **Settings**. This
installs a user LaunchAgent (`~/Library/LaunchAgents/com.acknowledgementforce.agent.plist`)
so Force resurfaces on your chosen cadence:

| Frequency | Behaviour |
| --- | --- |
| Every launch | Re-acknowledge each time Force opens |
| Every hour | Re-locks one hour after each acknowledgement |
| Every 12 hours | Re-locks twelve hours after each acknowledgement |
| Once a day | One acknowledgement carries the whole day |
| Once a week | One acknowledgement carries the whole week |
| On login / restart | Re-acknowledge on every login and restart |

Your acknowledgement history is stored locally at
`~/Library/Application Support/Force/acknowledgements.log`.

## Sync — edit from anywhere

Force can pull your **contract, quotes, daily goals, and reflection** from a
Supabase project and push contract/goal edits back — so you can edit on the web
and have it land on your Mac, and vice versa (last edit wins). Acknowledgements,
checklist ticks, and history always stay local to each device.

There's no separate config to maintain: **Settings → 03 — SYNC**. If the build
was pre-connected, you'll just see a login form; otherwise you enter a Supabase
URL + key first.

### Option A — use the hosted backend

Sign up at [force.clupai.com](https://force.clupai.com), then in the app:
**Settings → Sync → log in**. Prebuilt distributable builds are already wired to
the hosted backend, so there are no keys to enter — just log in.

### Option B — bring your own Supabase (open source)

Own all your data by pointing the app at your own project:

1. Create a project at [supabase.com](https://supabase.com).
2. In the SQL editor, run `web/supabase/migrations/0001_init.sql` (creates the
   `contents` table, row-level security, and a signup trigger). Safe to re-run.
3. *(Optional)* Deploy the web editor in `web/` to Vercel — set **Root
   Directory = `web`** and the env vars `NEXT_PUBLIC_SUPABASE_URL` +
   `NEXT_PUBLIC_SUPABASE_ANON_KEY`. Or run it locally with `cd web && pnpm dev`.
4. In the app: **Settings → Sync** → paste your **Project URL** + **anon /
   publishable** key → log in.

The key you enter is the **public** key (anon / publishable), protected by
row-level security — never the `service_role` secret.

### Building a pre-connected distributable

To hand someone a build that's already wired to *your* Supabase (they only log
in or sign up — no keys), bake the credentials at build time:

```sh
FORCE_SUPABASE_URL=https://YOUR-REF.supabase.co \
FORCE_SUPABASE_ANON_KEY=sb_publishable_... \
./install.sh --package
```

This embeds the keys, restores the placeholder afterward (**keys never touch
git**), and writes `dist/Acknowledgement-Force-<version>.zip`. The recipient
unzips and drags the app to `Applications`. Because the build is ad-hoc signed
(not notarized), on first open they right-click the app and choose **Open** (or
run `xattr -dr com.apple.quarantine "<app>"`). Running `./install.sh` with no
`FORCE_SUPABASE_*` vars produces the plain open-source build (no baked keys).

### Make it stop

If you need to immediately quit the app and stop it from relaunching without a
full uninstall, run:

```sh
./stop.sh
```

## Uninstall

```sh
./uninstall.sh            # remove the app + auto-launch agent (keeps your data)
./uninstall.sh --purge    # also delete saved history and preferences
./uninstall.sh --system   # also look in /Applications
```

## Linux & Windows — `force-cli`

The Swift code is split into a cross-platform core (`ForceKit`) and front
ends. On Linux and Windows, Force runs as a terminal app with the same
contract, gate policy, and cloud sync as the Mac app:

```sh
# Linux (Swift 6 toolchain: https://swift.org/install)
swift build -c release --product force-cli
.build/release/force-cli help
```

```powershell
# Windows (Swift 6 toolchain via swift.org or winget)
swift build -c release --product force-cli
.build\release\force-cli.exe help
```

Daily flow:

```sh
force-cli              # status: locked or open? (exit code 3 when locked)
force-cli ack          # read the contract, type "I ACKNOWLEDGE", name your action
force-cli check        # show the daily checklist; `check 3` toggles item 3
force-cli history      # past actions
```

Cloud sync (same account as the Mac app / web editor):

```sh
force-cli config set url https://YOUR-REF.supabase.co
force-cli config set key sb_publishable_...
force-cli login you@example.com
force-cli sync
```

State lives in the platform's per-user data directory (`force-cli config`
prints the path; override with `FORCE_STATE_DIR`). Files holding credentials
are written owner-only (0600). To re-lock on a schedule, hook `force-cli
status` into your shell profile, a systemd user timer, or Windows Task
Scheduler — exit code 3 means "locked".

> On Windows the interactive password prompt echoes; use
> `force-cli login you@example.com --password-stdin` and pipe the password
> instead.

## Build from source (development)

```sh
swift build                          # debug build (all targets)
swift run Force                      # build & run the macOS app
swift run force-cli status           # build & run the CLI
swift build -c release               # optimized release binaries
```

The release binary and its resource bundle (`Force_Force.bundle`) land in the
directory printed by `swift build -c release --show-bin-path`.

## Project layout

```
Sources/ForceKit/   Cross-platform core: models, contract parser, gate logic,
                    persistence, Supabase sync (builds on macOS/Linux/Windows)
Sources/Force/      macOS SwiftUI app + bundled fonts
Sources/ForceCLI/   force-cli — terminal front end for Linux/Windows (and macOS)
web/                Next.js web editor + Supabase migration (optional cloud sync)
landing/            Legacy static marketing site (superseded by web/)
docs/               Architecture and design notes
install.sh          Build + package + install the macOS .app
uninstall.sh        Remove the app, agent, and (optionally) data
stop.sh             Quit now + disable auto-launch (no uninstall)
VERSION             Release version (drives the bundle version)
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how the targets fit
together.

## Releasing

1. Bump `VERSION` (e.g. `0.2.0`).
2. Commit the change.
3. Tag and push:

   ```sh
   git tag -a "v$(cat VERSION)" -m "Release v$(cat VERSION)"
   git push origin "v$(cat VERSION)"
   ```

The version in `VERSION` is baked into the `.app` bundle's
`CFBundleShortVersionString` at install time.

## License

Released under the [MIT License](LICENSE) — free to use, modify, and
distribute.

The bundled fonts are licensed separately under the
[SIL Open Font License 1.1](https://openfontlicense.org): **Fraunces**
(© The Fraunces Project Authors) and **Inter** (© The Inter Project Authors).
