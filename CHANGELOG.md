# Changelog

Every notable change to Force lands here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**There is no v2 code yet.** Nothing has been built, nothing has been released. What exists
on 2026-08-04 is a decision record, four spikes with measurements attached, and this
documentation set. The Unreleased section below is a record of that work, not a preview of
a build.

The releases under [Previously, as Acknowledgement Force](#previously-as-acknowledgement-force)
belong to v1, which is a different app. See [v2 is a rewrite, not an
upgrade](#v2-is-a-rewrite-not-an-upgrade).

## [Unreleased]

### Added

**The decision record — D1 through D24.** Produced in one design session on 2026-08-04 and
written down in [FORCE-V2.md](FORCE-V2.md) with the full argument for each, including what
was rejected and why. The one-line versions:

| | Decision | Why |
|---|---|---|
| **D1** | The disease is a missing feedback loop; habituation is the symptom | v1's gate said the same thing on day 1 and day 40. Its 145 acknowledgements carry a timestamp and nothing else, so the app could not tell its best day from its worst |
| **D2** | The atomic unit is an identity claim, not a habit | A claim must name its own evidence and be capable of being false. *"I train when I don't feel like it"* — today either contained that moment or it didn't |
| **D3** | Evidence is produced, not asserted | Spoken testimony is the floor; numbers come from Tempo. A checkbox can be ticked with your mind elsewhere, which is the entire problem |
| **D4** | One primary claim, up to two background, 28-day pursuit | Force covers only what nothing else enforces: health, job hunt, relationships. Wording is editable any time; retirement costs a spoken receipt |
| **D5** | Two beats a day, exactly one of them a gate | v1 ran 6–9 gates a day in week one. Scarcity is the only thing that makes a gate mean anything. The evening beat fires on day close, not on a clock |
| **D6** | The gate is adaptive: one prompt by default, conversation when earned | It opens up on five triggers — broken day, vague testimony, Tempo contradiction, second consecutive miss, 28-day review. Fixed intensity trains you to it however high you set it |
| **D7** | "Not tonight" is one tap, and the day logs as `unsettled` | `unsettled` is not `broken`: one means you didn't show up, the other means you showed up and lost. The moment quitting the night gets expensive, you quit the app |
| **D8** | Gate state is derived from persisted wall-clock facts, never process memory | v1's `sessionAcknowledged` was a per-process `Bool`. A `Bool` has no clock, so the gate never re-locked for the life of the process. Logical day boundary defaults to 4am |
| **D9** | Onboarding commits on night one and sharpens on day seven | Day-one you and tired-you on day nineteen don't know each other. Every proposed claim ships with the quote it came from; if the AI can't cite you, it doesn't get to propose it |
| **D10** | The name is Force | Force is not what the app applies to you. It's what you apply to your own life; the app keeps the record honest |
| **D11** | No persona — a voice and a register, nothing to fanboy | Character comes from what it knows, not how it talks. Four voices chosen for stance. ElevenLabs pipelined behind your own speech, on-device fallback mandatory, always interruptible |
| **D12** | Escalation: nothing, then a question, then a trial | First miss produces silence — no colour change, no word. If one bad day triggers a visible reaction, the cheapest way to avoid it is to stop opening the app |
| **D13** | Platform is Flutter | Decided by spike, against the initial Tauri recommendation. See the measurements below |
| **D14** | The web dashboard reads the record; it can never settle the day | A gate you can face in a browser tab while half-watching something else is reflex-ticking in a new medium |
| **D15** | Phase discipline: functionality now, design later | The spike deliberately reuses v1's theme so the comparison measures the stack, not taste. The experiment's throwaway styling does not survive into the product |
| **D16** | Illustration is engraving line art, knocked out and recoloured | It inherits the palette instead of dictating one, and it carries a thread from v1's hand-drawn marks. Never on the evening gate |
| **D17** | Minimum legibility is a hard requirement | 15px floor, 17px body, 4.5:1 contrast, no text under 0.7 opacity, `textScaler` honoured. Force is designed to be opened on your worst nights — poor legibility is the core case here, not an edge case |
| **D18** | Strict mode: what each OS actually permits, tested | 100% of it is platform code. The macOS gate must be a second `NSPanel`, not the main window. Enabling it takes Force off the Mac App Store — the call D21 then makes |
| **D19** | The palette is **Ash** | Ten tokens, chosen from three live directions in the motion lab. v1's system mapped `accent`, `info` and `sale` all to `ink`, so it physically could not render three day-states — and two of its colours failed measurement outright |
| **D20** | Motion: four locked moments | Ink Bloom (whole sentence out of blur, no stagger), Italic + rule, the layered ring (solid bodies, gradient rejected), Fling (real spring, interruptible). The spring constants stay in `settle_scene.dart` and are deliberately not restated |
| **D21** | Distribution: **GitHub + Developer ID, not the App Store** | Signed and notarised, with Gatekeeper bypass instructions in the README, the way v1 already shipped. Strict mode needs the sandbox off and the App Store forbids that; the interruption feature was the original point of Force |
| **D22** | v1 scope includes the **Counsel** | Time is not the bottleneck, iteration quality is. One ordering rule attaches: macOS ships first and alone, and nothing touches Windows or Android until 28 consecutive days have been run on it personally |
| **D23** | Copy voice — and *"short sentences" is not the principle* | Plain words and something picturable is. Length is allowed where the reader chose to read; what killed v1 was *passive* length, 160 lines scrolled past. Say **stop**, **wrong for you**, **quit** — never *deprioritise*, *miscalibrated*, *retire a claim* |
| **D24** | Image generation: stay with what produced the approved samples | Native transparency turned out unnecessary — luminance thresholding beats a segmentation model on cross-hatching. One provider, one pipeline. Also corrects D11's example: Force has no sleep data, so the line is *"you closed this app after 1am on all three of those nights"* |

**The stack spike — three builds of the same screen.** One evening-gate wireframe
([spikes/SPEC.md](spikes/SPEC.md)) implemented three times on the same Mac and judged side
by side: claim in Fraunces, a 40-bar live microphone meter at 60fps, a spring settle into
the record strip, and one-tap *Not tonight*. Results in
[spikes/RESULTS.md](spikes/RESULTS.md).

| | SwiftUI | Tauri v2 + React | Flutter |
|---|---|---|---|
| Cold start → first paint, median of 5 | 212 ms | 458 ms | **208 ms** |
| spread across runs | 174–318 ms | 418–470 ms | **196–223 ms** |
| Idle RSS | 103–107 MB | 111 MB | **99 MB** |
| Release bundle | **1.7 MB** | 10 MB | 36 MB |
| Lines of code, same screen | **799** | 881 | 944 |

Then Android, which was the tiebreaker. Flutter built the same source with zero changes and
produced a 39 MB release APK first try. Tauri needed a `#[cfg(desktop)]` guard for
`set_always_on_top`, hit a Gradle 8.14.3 / Java 25 conflict, broke its own `buildSrc` when
Gradle was bumped, and never produced an APK — three toolchain blockers on a screen with one
window API call.

**The strict-mode spike — what the OS actually allows.** Executed, not read: 25 screenshots
and a persistent event log, driven over a loopback control port so every result is a
recorded command and response. Full detail in
[spikes/strict-mode/FINDINGS.md](spikes/strict-mode/FINDINGS.md), consequences summarised in
[docs/PLATFORM.md](docs/PLATFORM.md).

| Capability | macOS | Android | iOS |
|---|---|---|---|
| Raise itself unprompted | yes, ~5 lines of Swift (fails while the screen is locked) | yes, via overlay | no API exists |
| Cover another app's full-screen space | yes — only from a separate `NSPanel` | yes, except over Settings | no |
| Launch itself on a schedule | yes, LaunchAgent — requires the sandbox off | yes, `BOOT_COMPLETED` + foreground service | no |
| Wake-from-sleep events reaching Dart | `screensDidWake` verified end to end; real `didWake` (system sleep) **not tested** | not tested | n/a — the process is suspended |
| Non-Dart code required | ~155 lines Swift | ~165 Kotlin + 35 XML | ~20 Swift, for a notification |

Three findings changed the plan. The wall remembered from v1 — *"my window can't get above a
full-screen app"* — was not a wall, it was the wrong window: six attempts to fix
`MainFlutterWindow` all reported `isOnActiveSpace: false`, while a hand-written AppKit app
with identical flags overlaid instantly. `kill -TERM` always wins, so Force Quit and Activity
Monitor can never be blocked, which is exactly the escape D7 requires. And `AppLifecycleState`
never fired for sleep or wake at all, which means D8 cannot be satisfied in Dart and the nine
native observers are mandatory.

**The illustration direction and its costing.** Four directions generated
([spikes/illustration/](spikes/illustration/)); engraving won. Abstract and cinematic were
rejected on sight — *"the abstract one didn't make sense to me"*, *"cinematic is just a
street with a kid in it"* — and risograph read as a generic agency poster. `proof-recolour.png`
shows the same three engravings composited onto dark, paper and deep-teal grounds, with
luminance used as alpha so the cross-hatching keeps its anti-aliased edges. Live pricing
research is in [spikes/illustration/COSTS.md](spikes/illustration/COSTS.md):

| Option | $/image | $/1,000 users/yr | Note |
|---|---|---|---|
| Recraft V3 Vector | $0.08 | $1,040 | Ships a literal `Engraving` style and returns true SVG. Spike it before committing |
| Ideogram 3.0 Turbo `generate-transparent` | $0.04 | $520 | The only provider with native-alpha generation. `style_code` is a persistent style ID |
| FLUX.1 [schnell] via Together | $0.0027 | $39 | 15× cheaper, Apache-2.0, no style ID, do your own knockout |

**The motion lab.** Six scenes in [spikes/flutter-showcase/](spikes/flutter-showcase/), each
one stressing a different class of motion rather than a different feature: the claim arriving
word by word out of blur, the record strip's staggered spring entrance, a live voice
visualiser over real microphone PCM, a velocity-carrying settle you can throw and then change
your mind about mid-flight, a full-screen GLSL field that also fills the display serif, and a
word-level diff that rewrites one sentence into another. Measured over a 6.5-minute
hands-free run: 14,884 frames, 3 frames (0.02%) over the 60 Hz budget, zero exceptions, zero
layout overflows, and memory that peaked at 355.8 MB in the first ten seconds then plateaued
flat at 262.8 MB. Notes and caveats in
[spikes/flutter-showcase/NOTES.md](spikes/flutter-showcase/NOTES.md). The verdict recorded
there: *"Flutter is not the constraint. My taste is."*

**`design/` — the five review surfaces, recovered 2026-08-07.** The desktop demo, the flow
chart, the screens, the motion lab and the wireframe walkthrough had been published as
claude.ai artifacts on 2026-08-04/05 and were all five later **deleted server-side**. Their
build source had never been copied into the repo. It was recovered from
`~/.claude/file-history/` — 119 byte-exact snapshots, one per Write of every part file — with
the original filenames and concatenation order confirmed against the 41 MB session transcript.
Only `fonts_b64.json` and `masks_b64.json` were unrecoverable, having been produced with Bash
rather than Write; `design/build.py` regenerates both from fonts and images still in the repo.
Rebuilt and verified by rendering: 27 demo states, 24 flow nodes, 34 screen plates with zero
unresolved anchors, both engraving masks intact. Detail in
[design/README.md](design/README.md). Nothing was decided or redesigned — this is recovery,
not new work, and the seven unauthorised things the demo shows remain `open`.

### Changed

- **Stack recommendation reversed: Tauri → Flutter (D13).** The spike overturned its own
  starting recommendation on its own evidence. Tauri is 2.2× slower to first paint on the one
  screen faced every night, and it cost three toolchain fixes on Android where Flutter cost
  zero. The price of choosing Flutter is stated plainly rather than waved away: the design
  system now lives in two places, Dart for the app and React for the Vercel surfaces. That is
  a tax paid once at the token level, against a platform-divergence tax charged forever.
- **Two long-standing worries about Flutter were killed by measurement, not argument.**
  Serif rendering: all three builds render Fraunces cleanly and near-identically, so the main
  qualitative case against shipping your own renderer is dead. Bundle bloat: the Electron fear
  was misdirected — Tauri's webview costs about 8 MB more memory than native, not 200 MB.
  Latency was the real cost all along.
- **Name: Acknowledgement Force → Force (D10).** Not just a shortening. The reframe is that
  Force is what you apply to your own life, and the app is the thing that keeps the record
  honest. That reading matches the product actually designed — one that refuses to coerce.
- **The macOS gate is a second window, not a mode (D5 via D18).** A borderless
  `.nonactivatingPanel` at `.screenSaver` level, hosting a `FlutterViewController` on its own
  engine and Dart entrypoint, roughly 35 lines. It covers another app's full-screen Space
  without stealing focus or switching Spaces, which hands D7's "insistent but always
  escapable" over for free.
- **Type scale rebuilt against a hard floor mid-showcase (D17).** Prose went 14 → 17,
  supporting prose 12.5 → 16, the smallest readable text 9–11 → 15, uppercase labels 10 → 14
  with real tracking. `stone` `#60646A` was retired as a text colour outright — it measures
  3.07:1 against `base` and fails 4.5:1. It survives only as the fill of a `broken` mark,
  where the 3:1 non-text minimum applies.
- **The palette and the motion language moved from open questions to decisions (D19, D20).**
  Ash replaces v1's monochrome system, which mapped `accent`, `info` and `sale` all to `ink` and
  so could not render `kept` / `broken` / `unsettled` at all. Motion locks four moments and
  points at `spikes/flutter-showcase/lib/scenes/settle_scene.dart` for the settle's spring
  constants rather than copying them into prose, where they would drift.
- **Distribution settled against the App Store (D21).** GitHub Releases, Developer ID signing,
  Apple notarization, Gatekeeper bypass instructions in the README, and an updater we host. This
  is what D18 flagged as UNRESOLVED and it resolved in strict mode's favour.
- **First-release scope settled (D22).** The Counsel is in v1. Ordering is unchanged: macOS
  first and alone, 28 consecutive days before any second platform.

### Removed

These are v1 behaviours that v2 will not reproduce. No code was deleted, because no v2 code
exists — this is the list of things the design record now forbids.

- **The checkbox as evidence (D3).** It is literally v1. A box can be ticked while your mind
  is elsewhere.
- **The no-escape rule (D7).** `force-old/Sources/Force/App.swift:30` carries the comment
  `// the "no escape" rule` and `windowShouldClose` returning `false`. It produced exactly one
  outcome: total escape. The strict-mode spike confirms the OS still offers that refusal, and
  the recommendation is to leave it on the table untouched.
- **Multiple gates a day (D5).** Six to nine in week one is the direct cause of "I scrolled
  through without reading."
- **Process-scoped booleans anywhere in gate logic (D8).** Named as a standing trap to
  re-check before shipping.
- **Any visible reaction to a first miss (D12).** Not a colour, not a word.
- **Celebrity mentor personas (D11).** Borrowed authority; Hormozi has never seen your record.

### Open

Undecided as of 2026-08-04. Listed so nothing gets quietly invented later.

Open questions 12 through 15 are all closed. Scope is D22, the palette is D19, motion is D20,
distribution is D21, and rewrite-versus-evolve resolved as a full rewrite with `force-old/` as
reference only. What is left:

- **Speed versus the model.** Flagged in the hard constraints: if a model call sits in the
  critical path of the nightly gate, the gate is only ever as fast as the network. Any design
  where you wait on a spinner before you can speak is disqualified. Likely shape is
  local-first writes with responses streaming in after the day has already settled — but it
  is not decided. Same question for speech-to-text, on-device versus cloud.
- **The image model's exact ID.** The provider itself is settled by D24 — stay with what
  produced the approved samples, one provider and one pipeline, revisit at thousands of users.
  Confirm the model ID at wiring time: Imagen 4 shut down 2026-08-17 and it is a different model
  from the Gemini image model the samples came from.
- **Whether voice choice and register are the same control.** Worth prototyping — you'd pick
  a voice and hear what you're signing up for instead of reading an adjective.
- **Version numbering for the first v2 release.** Not decided, and deliberately not assumed
  here.

Three things from the spikes are unmeasured rather than undecided, and should not be treated
as proven: Windows (needs CI, cannot be felt from this Mac), physical Android hardware and
OEM battery-killer behaviour (emulator only so far), and `NSWorkspace.didWakeNotification`
from real system sleep — the exact event that killed v1 — which needed `sudo` to trigger. The
log at `spikes/strict-mode/evidence/macos-events.log` is left wired for a two-minute manual
confirmation: run the app, close the lid, reopen, check for the line.

## Previously, as Acknowledgement Force

v1 lived in [force-old/](force-old/). It was a macOS SwiftUI app that gated its own window
behind a 160-line contract: read it, tick the acknowledgement box, name the day's single
highest-leverage action, and only then could you close the window. Swift 6, MIT licensed,
one SwiftPM package with a platform-neutral `ForceKit` core, a `force-cli` front end for
Linux and Windows, an optional Supabase sync for contract, quotes, goals and reflection, and
a Next.js web editor.

### [0.3.0] — 2026-05-23

Tagged `v0.3` in git; `VERSION` reads `0.3.0`.

- Light and dark mode in the web editor
- Account management in the web app
- Quote update fix, a crash fix, and an install fix

### [0.2.0] — 2026-05-21

- Release packaging: `install.sh`, `uninstall.sh`, `stop.sh` and their docs
- `install.sh` detects copies in other locations and offers to remove them, so `--system` and
  the default install can't quietly accumulate duplicates
- Landing page and logo

### [0.1.0] — 2026-01-02

- The first working macOS gate, from a 2025-12-31 commit reading `v0.1 of acknowledgement-force`
- Auto-launch via a user LaunchAgent, with six re-lock frequencies: every launch, hourly,
  every 12 hours, daily, weekly, and on login or restart
- README and MIT licence

### After 0.3.0

Work continued and was never released: an MCP server (`mcp beta-v0.4`, 2026-05-23), a landing
page update, and an Android client with system-wide app blocking that reached a commit named
`android: pre-test` on 2026-05-25. That was the last commit.

The usage log at `~/Library/Application Support/Force/acknowledgements.log` records what
happened next. 145 acknowledgements across 38 days, from 2026-05-21 to 2026-07-10. Six to
nine opens a day for the first two weeks, all fourteen days. The first two-day gap on June
4–5. One to three opens a day after that, with the gaps widening. An eight-day gap from June
26. A last acknowledgement on July 10, and then nothing. By 2026-08-04 the app had been dead
for 25 days and was no longer installed anywhere.

Two facts do all the work in explaining that curve, and both are recorded in D1. The research
already sitting in the repo — `force-old/docs/research-affirmations-habits-ai-mentor-v2.md` —
says weeks one to five predict long-term adherence and names *never miss twice* as the core
mechanic. The two-day gap in early June is where the curve broke, and v1 had no response to
it because it had no way to see it. And the 145 entries carry a timestamp and nothing else,
so compliance and non-compliance were indistinguishable to the app that recorded them.

### v2 is a rewrite, not an upgrade

Nothing carries over as code, and that is now on the record rather than inferred —
`FORCE-V2.md` §4 closes open question 15 as a **full rewrite, with `force-old/` as reference
only.** This is not a version bump of Acknowledgement Force; it is a different app that happens
to be for the same person.

| | v1 — Acknowledgement Force 0.3.0 | v2 — Force |
|---|---|---|
| Name | Acknowledgement Force | Force (D10) |
| Stack | Swift 6, SwiftUI + AppKit, `force-cli` for Linux/Windows | Flutter, with Swift and Kotlin where the OS demands it (D13) |
| Data model | A 160-line markdown contract, plus a log of bare timestamps | Identity claims, spoken evidence, and days that settle as `kept` / `broken` / `unsettled` (D2, D3, D7) |
| Rhythm | Up to nine gates a day, clock-driven | Two beats, exactly one gate, fired on day close (D5) |
| Exit | `windowShouldClose` returning `false` | One tap, no confirm dialog, logged as `unsettled` (D7) |
| Reach | macOS, with a terminal client elsewhere | macOS → Windows → Android (D13) |

A migration path exists, but it runs one way and it carries content, not structure: v1's
contract is read as onboarding material for the first session, so you don't start from zero
when you've already written 160 lines about yourself (D9). The old `acknowledgements.log` is
input to that same session. The v1 MCP server and the Android app-blocking work are parked,
not ported — they return only once there is a v2 data model to point them at.

For how v2 is put together, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and
[docs/DATA-MODEL.md](docs/DATA-MODEL.md). For what it says and how, see
[docs/COPY.md](docs/COPY.md) and [docs/DESIGN.md](docs/DESIGN.md). For what gets built and in
what order, see [plans/ROADMAP.md](plans/ROADMAP.md).
