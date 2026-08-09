# Force — project instructions

Read this first, then read [`FORCE-V2.md`](FORCE-V2.md) in full before you touch anything.

## What Force is

Force is a personal accountability app built around **identity claims** — sentences like
*"I am someone who trains when I don't feel like it"* — instead of habits or checkboxes (D2).
Each evening you speak one sentence of testimony about what actually happened, and the day
settles as `kept`, `broken`, or `unsettled` (D7). The app's job is to keep the record honest;
the *force* is what you apply to your own life, not what the app applies to you (D10).

v1 shipped, was used 145 times over 38 days, and died in week 7. Nearly every decision in
this repo is traceable to a specific way that happened. If you find yourself about to
re-decide something, the reason it was decided is usually one paragraph away.

## The authority rule

**`FORCE-V2.md` is the decision record and it wins.** D1 through D24, each with the reasoning
that produced it. Nothing in this file, in `docs/`, in `plans/`, or in code comments overrides it.

- If a decision is in `FORCE-V2.md`, it is settled. Implement it; don't relitigate it. If you
  think it's wrong, say so out loud to the user and wait — do not quietly build the other thing.
- If a decision is **not** in `FORCE-V2.md`, it is not decided. Do not invent it and do not let
  it appear in a doc as though it were settled. Ask, or write it under an explicit "Open" heading.
- When something new gets decided, it goes into `FORCE-V2.md` as a numbered decision **with its
  reasoning**, because that file exists so "future-us can tell the difference between a
  considered choice and an accident" (its own words, line 7).

Open items are listed at the end of this file. They are open on purpose.

## Repo layout

```
force/
  FORCE-V2.md          the decision record — D1..D24, authoritative
  CLAUDE.md            this file
  HANDOFF.md           where the work was left. Read it second, after FORCE-V2.md
  README.md            what Force is, for a human arriving cold
  CHANGELOG.md
  docs/
    ARCHITECTURE.md    surfaces, data flow, where the LLM sits
    DESIGN.md          visual system, motion, illustration (D16)
    COPY.md            the voice rules in full
    PLATFORM.md        per-OS capabilities and limits (D18)
    DATA-MODEL.md      claims, days, testimony, the record
  design/              the five clickable review surfaces + build.py. Decides nothing
  plans/ROADMAP.md
  .claude/skills/      project skills — see below
  spikes/              throwaway proofs. Do not build on them.
  force-old/           v1. Dead. Reference only.
```

`HANDOFF.md` is a snapshot, not an authority — it carries verified facts, doc quotations with
line numbers, and questions that need a call. `design/` holds the demo, the flow chart, the
screens, the motion lab and the wireframe walkthrough, rebuilt from part files after all five
published copies were deleted; several of those pages deliberately show things `FORCE-V2.md`
does not authorise, and [`design/README.md`](design/README.md) lists which.

**The real app does not exist yet.** As of the last update to `FORCE-V2.md`: "Nothing built
yet." When it lands, it goes in a new top-level directory, not inside `spikes/` and not by
editing `force-old/`.

The root is not a git repo. `force-old/` carries its own `.git`.

### `spikes/` — proofs, not foundations

Five throwaway builds that answered specific questions. `spikes/SPEC.md` states it plainly:
*"This is a throwaway... None of this code survives."*

| Path | What it answered |
|---|---|
| `SPEC.md` | the one screen all three stacks had to build |
| `RESULTS.md` | the macOS measurements, and the Android tiebreaker that chose Flutter |
| `swift-gate/` `tauri-gate/` `flutter-gate/` | the three builds |
| `flutter-showcase/` + `NOTES.md` | six scenes; the motion ceiling, the legibility rebuild, a 6.5-minute memory and frame-rate soak |
| `strict-mode/` + `FINDINGS.md` + `evidence/` | what macOS, Android and iOS actually permit; 25 screenshots and a persistent event log |
| `illustration/` + `COSTS.md` + `proof-recolour.png` | the four illustration directions, and live image-API pricing |

**Copy the findings and the techniques; never the code and never the theme.** The spikes
deliberately reuse v1's monochrome palette and fonts so the comparison measured the *stack*,
not the design (D15). That styling is not allowed to survive into the product.

### `force-old/` — v1, dead, reference only

Do not build on it, do not port it, do not "evolve" it. `FORCE-V2.md` §4 closes that question:
**full rewrite, and `force-old/` is reference only.** Read it for these:

| Path | Why it matters |
|---|---|
| `docs/research-affirmations-habits-ai-mentor-v2.md` | weeks 1–5 predict long-term adherence; "never miss twice" is the core mechanic. The research was right and v1 didn't implement it. |
| `Sources/ForceKit/Engine/AcknowledgementGate.swift:31` | the bug that produced D8 — a per-process `Bool` standing in for gate state |
| `Sources/Force/App.swift:30` | `// the "no escape" rule`, which produced exactly one outcome: total escape |
| `Sources/Force/Theme.swift:69` | `accent`, `info` and `sale` all map to `ink`. The palette is not "wrong colours" — there are no colours. |
| `Sources/Force/Store.swift:50` | the 30s timer that papered over `daily`/`hourly` and could not help the other two modes |
| `android/` | the Kotlin `AccessibilityService` app-blocking work — the most interesting engineering in the old repo, parked until strict mode is real |
| `plans/roadmap.md` | Track 1 (MCP + API keys), Track 2 (Android blocking), Track 3 (Force Guide) |
| `mcp/` | the v1 MCP server, to be re-pointed at the v2 data model later |
| the 160-line contract | onboarding input, not history — D9 mechanic 2 says the first session reads it and brings it as material |

The real usage log lived at `~/Library/Application Support/Force/acknowledgements.log`. Every
number in `FORCE-V2.md` §0 came from it. The app is no longer installed anywhere.

## The stack, settled

**Flutter.** Decided 2026-08-04 by spike, against the initial recommendation (D13). Full
measurements in [`spikes/RESULTS.md`](spikes/RESULTS.md).

| | SwiftUI | Tauri v2 | Flutter |
|---|---|---|---|
| cold start → first paint (median of 5) | 212 ms | 458 ms | **208 ms** |
| spread | 174–318 | 418–470 | **196–223** |
| idle RSS | 103–107 MB | 111 MB | **99 MB** |
| Android build | n/a | never produced, 3 toolchain blockers | **39 MB APK, first attempt, zero source changes** |

Three things settle it and none of them need re-testing: Flutter matched native on cold start
with half the variance and the lowest memory; the serif-rendering worry was false (Fraunces
renders indistinguishably); and Android built first try while Tauri needed three toolchain
fixes on a screen with *one* window API call.

The cost is real and was accepted knowingly: the design system lives in two places, Dart for
the app and React for the Vercel web surfaces. That was Tauri's best argument. It is a tax paid
once at the design-token level, against a platform-divergence tax charged forever plus a 2.2×
slower launch on the one screen faced every night.

Other fixed points from §1b: **hosting is Vercel**; **state syncs to a server**, not device-only;
**speed and UI quality are primary requirements, not finishes**.

## Non-negotiables

These fail review on sight. Each one is a scar.

### D8 — the lifecycle law

**Gate state is derived from persisted wall-clock facts. Never from process memory.** No
process-scoped booleans anywhere in gate logic, ever. This is the bug that killed v1 and it
killed it silently.

- The **logical day** is the unit, with a configurable boundary defaulting to **4am, not
  midnight**. A 12:30am evening beat belongs to that day.
- Recompute on all of: launch, `didBecomeActive`, wake, day change, significant time change,
  plus a coarse timer as backstop. v1 observed none of the middle three.
- Recomputation is **idempotent** — a hundred runs equal one.
- Must survive wake from sleep, restart mid-day after the morning beat, and the app sitting in
  the background for days without quitting.
- **This cannot be done in Dart.** The strict-mode spike proved `AppLifecycleState` never fires
  for sleep or wake. Nine native `NSWorkspace` observers, ~35 lines of Swift, one MethodChannel.
  Mandatory, not optional.
- `NSWorkspace.didWakeNotification` — the real system-sleep one, the exact event that killed v1
  — was **never verified**; the spike could not trigger it without sudo. `spikes/strict-mode/
  evidence/macos-events.log` is wired to catch it. Confirm it by hand before building on it.

### D5 — one gate per day, exactly one

The morning beat is a ~10-second briefing with no lock. The evening beat is the wall, 60–90
seconds, and it is the only gate. v1 ran 6–9 gates a day in week one and that is the direct
cause of "I scrolled through without reading". Scarcity is what makes a gate mean anything.

The evening beat is **day-close-based, not clock-based** — it fires when you close the day,
whenever that is, including 1am.

### D7 — failure must always be closeable

- Three day states: `kept`, `broken`, `unsettled`. **`unsettled` is not `broken`.** Broken means
  you showed up and lost; unsettled means you didn't show up. Conflating them corrupts the
  record, and a run of `unsettled` days is the app dying — the one thing v1 could never see
  about itself.
- *"I didn't"* is a complete, valid, closeable answer. If the only exit is success, you lie or
  you stop opening it.
- There is no close button. There is **"Not tonight"**: one tap, no confirm dialog, no guilt
  copy, no "are you sure". The moment quitting the night gets expensive, you quit the app instead.
- **Never hard-lock the machine.** The OS offers `windowShouldClose -> false` and
  `.terminateCancel` and both work — the spike verified it. **Do not take them.** The macOS gate
  is a borderless non-activating `NSPanel` at `.screenSaver` level on its own Flutter engine: it
  covers another app's full-screen Space without stealing focus or switching Spaces, which hands
  you "insistent but always escapable" for free (D18).
- On Android the OS enforces the escape for you — Settings force-hides overlays. Any copy
  claiming "you can't get past it" would be a lie.

### D17 — minimum legibility, a hard requirement

| Element | Minimum |
|---|---|
| Any readable text | **15px** |
| Body / conversational text | **17px** |
| Uppercase tracked labels | **14px** + real letter-spacing |
| Text contrast | **4.5:1**, and no text below 0.7 opacity at rest |
| OS text-size setting | respected via `MediaQuery.textScaler`, never hard-clamped |

Force is designed to be opened on the user's worst nights, when they are tired and not sharp.
Poor legibility isn't an edge case for this product, it's the core case. **If a composition
depends on tiny type, the composition changes, not the type.**

Already established by the showcase pass: `stone` `#60646A` is 3.07:1 and is **retired as a text
colour** — it survives only as the fill of a `broken` mark, where the 3:1 non-text minimum
applies. `mute` `#9A9E9F` at 6.77:1 is the quietest voice available.

### Voice and copy

Full rules in [`docs/COPY.md`](docs/COPY.md). The ones that fail review:

- **The AI may only say things that are impossible without your record** (Principle 3). Generic
  encouragement — *"that's okay, just make sure to..."* — is the canned mantra again with audio.
  **Silence is a valid output.**
- **The user authors; the AI proposes** (Principle 5). Every proposed claim is shown with the
  quote it came from. **If the AI can't cite you, it doesn't get to propose it** (D9).
- **No persona, no character, no celebrity mentor, and never "your future self"** (D11). A
  character is fun for two weeks and then it's a bit. Character comes from what it knows, not
  how it talks. The voice is always interruptible with one tap.
- **Nothing happens on a first miss** (D12). Not a colour, not a word, not a gentle reminder.
  Second consecutive miss opens a conversation about the pattern; third puts the claim on trial.
- **Strict mode is never auto-offered.** It lives in settings, is mentioned once at onboarding,
  and is never raised again. You go looking for it on a good day.
- Most nights the gate is one prompt, ~30 seconds. It opens into conversation only on the five
  triggers in D6. Predictability is what killed v1's contract.
- **Only claim what Force's own record proves** (D24). D11's example used to read *"you slept
  past midnight before all three"* — Force has no sleep data and does not ask for it. The
  corrected line is *"you closed this app after 1am on all three of those nights."* Same
  insight, no health permissions, no tracking.
- **Length is not the rule; plain and picturable is** (D23). Short by default on the evening
  gate with an openable "more"; no limit ever on what the user says; properly long on the day-7
  and day-28 reviews and in the Counsel, because those are surfaces they chose to read.

### D15 — phase discipline

**Now: functionality only.** Prove the loop works. **Later: the full design pass** — applying
the palette and motion across every surface, identity, polish. Do not let theming leak forward
and do not let the spikes' throwaway styling leak back.

D15 governs *when*, not *what*. The what is already settled: **D19 is the palette (Ash, ten
tokens)** and **D20 is the motion language (Ink Bloom, Italic + rule, the layered ring, Fling)**.
Full tables and measurements in [`docs/DESIGN.md`](docs/DESIGN.md). Two rules that fail review on
sight: `accent` `#B4553A` has exactly **one** use in the entire product — the emphasis mark on
the falsifiable half of the claim — and the settle's spring constants are **not** to be restated
in prose. They live in `spikes/flutter-showcase/lib/scenes/settle_scene.dart` and that file is
the source of truth (D20).

### Scope boundary

Force does not answer *"what should I do at 2pm."* Any app that tries to own your task list
becomes a task list. Force answers **"which part of me am I defending this month, and is that
still the right one."**

### Writing in this repo

Plain, concrete language. Short words, real numbers, real examples. No corporate register, no
filler, no "leverage"/"utilize"/"robust", no emoji. The user's standard: *"if I can't visualize
it, it doesn't go in."* Carry the reasoning, not just the conclusion — cite decisions as (D4),
(D12) so they stay traceable.

**Short *words*, not short documents.** **D23** states it outright: *"short sentences" is NOT
the principle — plain words and something picturable is*, and length is allowed where the reader
chose to read. What killed v1 was *passive* length: 160 lines scrolled past. A long stretch of concrete
prose about a real week is good; a short abstract one is not. So do not "tighten" a doc by
trading a number, a date or a quote for a summary of it. Cut the throat-clearing —
*it is worth noting*, *a consequence worth stating* — and keep the evidence.

## Toolchain

Everything below was learned the hard way. Copy-paste it rather than rediscovering it.

```sh
# Homebrew's bin is not always on a non-interactive shell's PATH.
export PATH="/opt/homebrew/bin:$PATH"

# Android: Gradle must run on Android Studio's bundled JDK, not the system Java.
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

# Rust: only needed to rebuild spikes/tauri-gate/, which is a dead end.
# cargo is a rustup shim and is not on PATH by default.
source "$HOME/.cargo/env"
```

| Thing | Where / what |
|---|---|
| Flutter | `/opt/homebrew/bin/flutter`, SDK at `/opt/homebrew/share/flutter`. 3.44.8 stable, Dart 3.12.2. |
| Xcode | `/Applications/Xcode.app`, 26.6. `xcode-select -p` → `/Applications/Xcode.app/Contents/Developer`. |
| Android SDK | `~/Library/Android/sdk` |
| Android NDK | `27.0.12077973` and `28.2.13676358` |
| Emulator | AVD `force_spike` (Pixel 7, API 35), image `system-images;android-35;google_apis;arm64-v8a` |

**Full Xcode is required for Flutter macOS and iOS.** Command Line Tools alone will not do it —
Tauri and SwiftUI build fine on CLT, Flutter desktop does not. `FORCE-V2.md` still lists this
under "Platform / infra" as a to-do; it was resolved during the strict-mode spike and Xcode 26.6
is installed. ~15 GB.

**The JDK conflict, since it will come back.** Android Studio ships **Java 25**. Gradle 8.14.3
rejects it outright (`Unsupported class file major version 69`). Flutter generates a **Gradle
9.1.0** wrapper, which works — this is exactly the difference that broke the Tauri Android build
and produced blockers 2 and 3 in `spikes/RESULTS.md`. If you see that error, check the wrapper
version before you touch `JAVA_HOME`.

`android/local.properties` (`sdk.dir`, `flutter.sdk`) is generated and machine-specific. Never
commit it.

The macOS and iOS strict-mode builds both bind `127.0.0.1:8787`, and the iOS simulator shares
the host's loopback. Run one at a time or the second silently fails to bind and your `curl` hits
the wrong app. This cost one bad test run.

## Traps already paid for

Framework-level things that read as correct and render as wrong. All of these were discovered by
spending real time on them; do not spend it twice.

- **Flutter instantiates a variable font's fvar *default* instance.** Fraunces defaults to
  `wght 900 / opsz 9` — Black at caption optical size. Every text style must pin `wght` and
  `opsz` explicitly. There is no automatic optical-size mapping the way CoreText gives you for
  free. This is silent: you just get the wrong weight and wonder why the type looks heavy.
- **`ImageFiltered(ImageFilter.blur(...))` costs a `saveLayer` each.** For per-word blur use a
  transparent fill plus `Shadow(blurRadius: b, offset: Offset.zero)`. Identical optics, no
  offscreen pass, degrades to a crisp glyph at `b == 0`.
- **`AnimationController.animateWith(SpringSimulation)` cannot retarget mid-flight**, which is
  the entire reason to use a spring. You need your own simulation clock, seeded from current
  position *and* velocity. ~35 lines.
- **A `ui.FragmentShader` is mutable and the recorded picture only holds a reference.** Using one
  instance twice in a frame with different uniforms retroactively corrupts the earlier draw. Two
  instances off the same `FragmentProgram`. Nothing warns you.
- **`Row(children: [Flexible(a), SizedBox(), Expanded(b)])` does not push `b` to the right
  margin.** Flex space is allocated before children are laid out. Use `Wrap(alignment:
  spaceBetween)`.
- **`bool.fromEnvironment` only accepts the literal strings `true`/`false`.** `=1` silently
  evaluates to false.
- **Android: a `FlutterView` added to `WindowManager` with `MATCH_PARENT` never paints**
  (`FlutterRenderer: Width is zero. 0,0`). The window exists, `dumpsys` shows it, the engine
  starts, the screen is blank. Fix: explicit pixels from `wm.currentWindowMetrics.bounds` **and**
  wrap the `FlutterView` in a plain `FrameLayout`. This is in no documentation.
- **macOS: Flutter's `MainFlutterWindow` can never be re-assigned to another app's full-screen
  Space.** Six different collection-behaviour and window-level combinations all reported
  `isOnActiveSpace: false`. A hand-written AppKit window with identical flags overlaid instantly,
  so it is the window, not the OS. Use a second `NSPanel`.
- **Memory profiling needs a long window.** A 3-minute sample of the showcase reads as a 7 MB/min
  leak. It is the Dart heap approaching its next major GC and it does not resolve until ~350s.
  Both soak runs plateau *below* their starting RSS.

## Skills

Project skills live in `.claude/skills/<name>/SKILL.md`. **List that directory at the start of a
session.** If a skill covers what you are about to do, read it before you write anything — the
skills exist to stop the same decisions being re-made in code. If the directory is empty or the
skill you need isn't there, say so; don't improvise a substitute and don't pretend the guidance
was written.

Two exist today:

| Skill | Use it for |
|---|---|
| `force-build` | anything touching `flutter run`/`build`/`test`, Gradle, Xcode, the Android SDK or emulator, the iOS simulator, screenshots, cold-start timing, memory soaks |
| `force-voice` | any sentence a user will read or hear — screen copy, buttons, what the AI says at the gate, notifications, onboarding, error and empty states. The long form is [`docs/COPY.md`](docs/COPY.md) |

`force-old/.agents/skills/` holds fourteen vendored third-party design skills from v1
(`brandkit`, `impeccable`, `emil-design-eng`, `high-end-visual-design`, and others, pinned in
`force-old/skills-lock.json`). Reference only. They are not Force's design system and nothing in
them overrides `docs/DESIGN.md` or D17.

## Open — do not resolve these silently

Listed in `FORCE-V2.md` §4 and §5b. Each is genuinely undecided.

- **Is there a fourth verdict, `partial`?** D5 says the day settles as *kept / partial / broken*.
  D7, the palette note in `FORCE-V2.md` §4, and `spikes/SPEC.md` all say *kept / broken /
  unsettled*. Three places against one, and D7 is the later and more worked-out decision — but
  `partial` was never explicitly retracted. [`docs/DATA-MODEL.md`](docs/DATA-MODEL.md) is the only
  doc that catches this; everything else, this file included, writes three states as settled.
  **It needs a call before the enum is built**, because adding a state after days exist is a
  migration and a palette change.
- **Speech-to-text: on-device or cloud.** Must degrade to *something* offline (D11).
- **The latency pipeline.** No model call may sit in the critical path of the nightly gate. Any
  design where you wait on a spinner before you can speak is disqualified. Likely shape:
  local-first writes, the day settles with or without the model, responses stream in after.
- **The image model's exact ID.** The *provider* is settled — D24 says stay with what produced
  the approved samples, one provider and one pipeline, revisit at thousands of users. Native
  transparency turned out not to matter, because for black line art on white a luminance
  threshold beats a segmentation model, which eats thin hatch lines. Confirm the model ID at
  wiring time: Imagen 4 shut down 2026-08-17 and that is a different model from the Gemini image
  model the samples came from. Pricing in `spikes/illustration/COSTS.md` was live on 2026-08-04
  and goes stale fast.
- **Untested and load-bearing:** real `didWakeNotification`; physical Android hardware; OEM
  battery-killer behaviour; Play policy on `SYSTEM_ALERT_WINDOW` and `specialUse`; sustained
  animation on a real 120 Hz device; the Windows build, which needs CI.

**Recently closed — do not re-open these as "open".** `FORCE-V2.md` now carries **D19** (palette
is Ash), **D20** (the four motion moments), **D21** (distribution: GitHub + Developer ID, signed
and notarised, *not* the App Store), **D22** (the Counsel is in v1 scope; macOS ships first and
alone for 28 consecutive days), **D23** (copy voice), and **D24** (image provider). §4's open
questions 12–15 are all closed.

## How to work here

From `FORCE-V2.md` §6, and it is a hard rule: **every feature gets shown individually, in
multiple approaches, and is judged by whether it *feels* right in use — not by whether the spec
reads well.** A feature the user feels no pull toward is a feature that's dead in six weeks, like
the last one.

The acceptance test for the whole product: *"You should not be the one helping me organise my
thoughts. Force should be."*
