# Handoff — updated 2026-08-07

A snapshot for picking the work back up. **This file decides nothing.** `FORCE-V2.md` is the
decision record and it wins; everything below is either a fact verified on disk, a quotation
from a doc with its line number, or a question that needs a call. Where this file says
"needs a call", that is not a soft suggestion — it means the thing is genuinely undecided and
must not be invented in code.

It goes stale. Re-verify before trusting the toolchain versions or the artifact URLs.

---

## Last session — 2026-08-07

**The five published design artifacts had been deleted. All five are rebuilt and republished,
and their source is now in the repo at [`design/`](design/README.md).** Nothing else moved;
no code was written and no decision was made or changed.

What happened, in case the same failure recurs: every URL in the table under
[At risk](#at-risk) returned "artifact not found", and the account listing showed nothing
newer than 2026-07-31. This file's earlier claim that the *source* was gone was also wrong —
it survived in `~/.claude/file-history/7d6102db-e380-49d1-9586-1a9b98ab9e71/` as 119
byte-exact snapshots, one per Write of every part file. **The earlier search missed it because
it looked for the scratchpad paths, which were deleted, rather than for file history. Look
there first next time.** The companion transcript,
`~/.claude/projects/-Users-clupa-Documents-projects-force/7d6102db-….jsonl` (41 MB), records
all 26 original part paths and the original `build_demo.py`, which is what settled the
concatenation order.

Verified by rendering in headless Chrome, not just parsing: 27 demo states, 24 flow nodes,
34 screen plates `a1`→`h5` with zero unresolved anchors, both engraving masks recolouring
through `ink3`, all embedded JS passing `node --check`.

Two things worth carrying forward:

- **`design/built/` is generated.** 6.6 MB of the 8.5 MB in `design/`. It belongs in
  `.gitignore` when Phase 0 runs `git init`. The source is `design/parts/` (26 files),
  `design/standalone/` (2), `design/assets/` and `design/build.py`.
- **Fraunces Italic now exists on disk** at `design/assets/Fraunces-Italic.ttf`, pulled from
  google/fonts (SIL OFL) because no copy existed anywhere on this machine. It is the only
  asset the repo could not supply. Note that the screens page lists "Fraunces Italic" under
  its own **NOT DECIDED** heading — the font being present does not answer whatever that
  entry is asking.

---

## Where things stand

Design is complete. Nothing is built.

D1 through D24 are all made. `FORCE-V2.md` §4 closes with "All numbered questions are closed…
none of it blocks starting work." Five spikes ran to completion. There are 5,897 lines of
documentation. All of it — the record, the four other root `.md` files, the five `docs/` files
and the roadmap — was written in **one session on 2026-08-04**.

There is still no application source. `/bin/ls -A` of the repo root returns twelve entries:

```
.claude  .DS_Store  CHANGELOG.md  CLAUDE.md  design  docs
force-old  FORCE-V2.md  HANDOFF.md  plans  README.md  spikes
```

`design/` and this file are the two that were not there on 2026-08-04, and neither is in
`CLAUDE.md`'s repo-layout table. No `pubspec.yaml`, no Dart, no `.git`. `FORCE-V2.md`'s
"Nothing built yet" is literally true. Tree total 12 GB, of which roughly 7.9 GB is
regenerable spike build cache and 6.6 MB is regenerable `design/built/`.

### The spike results that settled the stack

| | SwiftUI | Tauri v2 | Flutter |
|---|---|---|---|
| cold start → first paint (median of 5) | 212 ms | 458 ms | **208 ms** |
| spread | 174–318 | 418–470 | **196–223** |
| idle RSS | 103–107 MB | 111 MB | **99 MB** |
| Android | n/a | never produced an APK, 3 toolchain blockers | **39 MB APK, first attempt, zero source changes** |

Showcase soak: 14,884 frames, 3 over the 60 Hz budget (0.02%), zero exceptions, memory peaked
at 355.8 MB in the first ten seconds and plateaued at 262.8 MB.

### The v1 log still exists and confirms §0

`~/Library/Application Support/Force/acknowledgements.log` — 4.8 KB, 145 lines, last written
2026-07-10 21:03:35 AEST. 145 entries across 38 distinct days, first 2026-05-21, 51 calendar
days end to end. Max 9 acknowledgements in one day, which is D5's "6–9 gates a day in week one"
exactly. Weekly totals from day one: **39, 39, 17, 17, 18, 5, 9, 1**.

It is not in the repo and not backed up by it. Worth copying in — every number in §0 rests on it.

---

## Start here: Phase 0

Nothing blocks it. From `plans/ROADMAP.md`:

1. **`git init` at the root, first commit before any Dart is written.** Two calls to make while
   doing it, named in Phase 0 but absent from the numbered open-questions table: does `force-old/`
   stay in the tree as history or move to its own archive, and is `spikes/` committed given the
   build output on disk. The `.gitignore` matters more than usual — Flutter, Gradle and SwiftPM
   all litter, and `design/built/` is 6.6 MB of generated output that rebuilds in seconds.
   **`design/` itself must be committed.** It is the only copy of the five review surfaces, and
   the 2026-08-07 recovery is what happens when the only copy lives somewhere else.
2. **A fresh Flutter project**, not an evolution of `spikes/flutter-gate` (D15). Two settings
   required on day one: `uses-material-design: false` in `pubspec.yaml` (the Material icon font
   is 1.6 MB and nothing uses it), and `WidgetsApp` rather than `MaterialApp`/`CupertinoApp`
   (Force uses neither design system and both put an inherited lookup on the path of every `Text`).
3. **The Ash token layer** from D19's ten tokens, no placeholders. D15 defers the design *pass*,
   not the values. `accent` `#B4553A` must not be reachable as a general-purpose colour — but see
   the D19/D20 conflict below before writing the rule as "exactly one use".
4. **The font pipeline**, with `wght` and `opsz` pinned explicitly on every `TextStyle`. Fraunces'
   fvar default is `wght 900 / opsz 9` — Black at caption optical size — and Flutter instantiates
   it silently. The roadmap gives the `_v(double wght, double opsz)` helper verbatim.
5. **The doc set** — already written.

**Exit** (six criteria, all in the roadmap): clean `git status` with history from the first commit;
a **release** build reaching first paint under ~250 ms measured from the kernel's `p_starttime`
(never a timestamp taken inside Dart — `flutter run` is debug and its numbers mean nothing here);
a specimen screen plus a test that fails if any theme `TextStyle` lacks explicit `fontVariations`;
a test that fails if any token's `fontSize` is under 15 or any text token is under 4.5:1; the
specimen clipping nothing at 200% `textScaler`; and the three day-state marks judged
distinguishable at arm's length, by the user, on the user's own screen.

---

## Calls needed before Phase 1

### 1. Is there a fourth verdict, `partial`?

The one the whole schema waits on. Adding a state after real days exist is a migration **and** a
palette change.

- `FORCE-V2.md:133` (D5) — "day settles as **kept / partial / broken**."
- `FORCE-V2.md:173–181` (D7) — a three-row table, `kept` / `broken` / `unsettled`, followed by
  "**`unsettled` is not `broken`.**"
- `FORCE-V2.md:541–542` (§4 palette note) — "v2 has three day-states."
- `spikes/SPEC.md:95` — three states.
- `docs/DATA-MODEL.md:417–424` is the **only** doc that catches the conflict. `README.md:396`
  and `CLAUDE.md` carry the flag. Everything else, `plans/ROADMAP.md` included across all 952
  lines, writes three states as settled and never mentions `partial`.

Three places against one, and D7 is later and more worked out — but `partial` was never
explicitly retracted. If the answer is three states, retract it in `FORCE-V2.md` as a numbered
amendment with reasoning, so it stops being open in four documents at once.

### 2. Speech-to-text — on-device or cloud, and does Phase 1 transcribe at all

Two constraints stack. D11: it must degrade to something offline, because the gate can never
depend on a network call. D3 cuts the other way: "the mechanism is speaking it aloud and putting
it back through your own ears, not the transcript." The roadmap offers an interim — Phase 1 keeps
the audio and does not transcribe — and labels it "a suggestion, not a decision." If deferred, it
must land in Phase 3, because D6's vague-testimony trigger and the Tempo-contradiction trigger
both need text.

**This collides with a default nobody has cited — see the recordings conflict below.**

### 3. Gate in the main window, or the `NSPanel` from the start

`spikes/strict-mode/FINDINGS.md` §4 recommends a second borderless `NSPanel` on its own
`FlutterEngine` with its own `gateMain` entrypoint, and calls that separation "architectural, not
cosmetic". But the panel only becomes *necessary* in Phase 6. The roadmap recommends the middle
path — build in the main window, write the gate as a self-contained tree with no reach into
app-level state so `gateMain` stays viable — and says explicitly "It is a recommendation, not a
decision."

---

## Verify this before building the lifecycle layer

**`NSWorkspace.didWakeNotification` has never once been observed.** It is the system-sleep wake —
the exact event that killed v1 — and D8 rests on it.

`spikes/strict-mode/evidence/macos-events.log` is 18 lines, all 2026-08-04, spanning 11:22:48 to
11:46:28. The string `didWakeNotification` appears **zero times**. What it contains is three
`NSWorkspace.screensDidWakeNotification` lines at 11:24:34, 11:25:26 and 11:25:59 — that is
*display* wake, a different notification.

The spike could not trigger the real one: `sudo pmset schedule wake` needs a password it could not
supply, and `pmset sleepnow` alone would have slept the Mac with nothing able to wake it. Posting
the notification via `DistributedNotificationCenter` from `tools/PostWake.swift` **did not reach
the observers**, so it does not count. What is proved is only that the observer sits on the same
notification centre as the two that did fire, and proved-by-analogy is not proved.

The log is still wired. Run the app, close the lid, wait, reopen, check for the line. Two minutes.

**Also unaddressed:** raising to front **fails while the screen is locked**. Two attempts recorded
verbatim — `raiseToFront mode=activateIgnoringOtherApps frontBefore=loginwindow
frontAfter=loginwindow NSApp.isActive=false isKeyWindow=false` at 11:25:08 and again at 11:25:46.
`loginwindow` owns the screen and does not give it up. `FINDINGS.md` records the failure and
proposes no mitigation, and nothing in `FORCE-V2.md` says what the evening beat does when the Mac
is asleep or locked. At 11pm that is the normal state, not an edge case.

---

## The record contradicts itself

Found by cross-checking every doc against `FORCE-V2.md`. All line numbers verified by hand on
2026-08-06. These matter because `FORCE-V2.md` is the file that is supposed to win — a reader who
lands on the wrong section gets the wrong answer from the authoritative source.

### Inside `FORCE-V2.md`

| Where | What |
|---|---|
| `:798` vs `:741` | §5b lists "**Counsel surface**" under *Product features parked, not rejected*, while D22 is titled "v1 scope includes the Counsel (RESOLVED)" and §4 records "✓ 13. v1 scope — Counsel is in". `ROADMAP.md:554` caught it; the record was never corrected. |
| `:607` vs D21 | D18's "**UNRESOLVED — needs a call**" on distribution was never deleted after D21 answered it. The file carries an open flag and its own answer. |
| `:711` vs `:725` | D19 marks `accent` "**one use only — see D20**". D20's own hold-to-speak row then specifies three contours "each a **solid body of its own colour** (`broken`, `ink3`, `accent`)". Only `docs/DESIGN.md:135` reconciles it — the innermost contour borrows `accent` transiently, thirty seconds a night. **`CLAUDE.md` files the flat one-use rule under "fail review on sight", so a correct D20 ring would currently fail review.** |
| `:833`, `:837` | "Only Command Line Tools are installed" and Android SDK "none currently installed". Both false — Xcode 26.6 and the SDK with both NDKs are on this machine (verified below). |
| `:790–795` | The palette rework and motion design pass are still unticked to-dos, though D19 and D20 resolve both and §4 already records "✓ 14". |
| `:285` vs `:782` | D11's canonical example still reads "you slept past midnight before all three." D24 corrects it to "you closed this app after 1am on all three of those nights" — Force has no sleep data. Anyone reading §1 alone copies the retired wording. |

### Between docs

**The recordings conflict — nobody flagged this one, and it is load-bearing.**
`FORCE-V2.md:508` gives the default: *"transcribe on device where possible, keep the text,
**discard the audio**. The record is words, not recordings."* The roadmap builds three separate
items on the inverse — `:265` ("keeps the audio and does not transcribe it at all"), `:526` (a
Phase 4 **exit criterion** requiring the restore test to return "every recording"), and `:544`
("the largest thing Force stores"), plus open questions about encrypting recordings the record
says should not exist. `docs/DATA-MODEL.md` is more careful but also never cites `:508`.
**This needs settling with question 2 above, not separately.**

| Doc | Conflict |
|---|---|
| `docs/ARCHITECTURE.md:464` | "**Provider: open**… Spike this first" for the image provider — contradicts D24, and contradicts its own line `:520` fifty-six lines later, which correctly says "settled by D24". `DESIGN.md` and `ROADMAP.md` both handle it right; ARCHITECTURE is the one that drifted. |
| `docs/DATA-MODEL.md:136` | "Nothing in FORCE-V2 chooses" the time zone for the logical day. False — `FORCE-V2.md:515` names "4am boundary in device-local time; revisit if it bites". Small practical harm (storing `settled_at` with its offset is compatible either way) but it tells an implementer to make a call already made. |
| `docs/COPY.md:235` vs `:236` | The same table gives day 7 two different lengths one line apart — "Medium" then "**Properly long**". `FORCE-V2.md:768` (D23) and `.claude/skills/force-voice/SKILL.md` both say properly long. COPY.md is the doc `CLAUDE.md` points at as the voice rules in full, so the stale row is the one a writer hits first. |
| `CLAUDE.md:186` | Cites `stone` and `mute` as live token names. Neither exists in D19's ten-token Ash palette — they are v1/spike-era names, retired wholesale. Both ratios quoted are correct as measurements; the tokens are not. The actual floor is `docs/DESIGN.md:90` — `ink3` `#7E858B` at **5.1:1**. Same class of error at `ROADMAP.md:175`, whose Phase 0 exit test checks contrast against `base` — also retired; D19's ground is `bg` `#101112`. |
| `docs/DESIGN.md:205`, `:310` | The full type scale and the three motion house-curves (`Cubic(0.16, 1.0, 0.3, 1.0)`, 220/420/760 ms) are presented as settled — "carry the sizes forward", "verbatim". **Neither has a D-number.** Grepping `FORCE-V2.md` for `Cubic`, `760`, `220 ms`, `opsz` returns zero hits; D17 fixes four minimums and D20 fixes four moments and three durations. `ROADMAP.md:172` already turns them into a Phase 0 exit criterion. This is the exact failure mode `CLAUDE.md` warns about: a doc presenting an undecided thing as settled. Same applies to the mic-meter constants at `DESIGN.md:394`. |
| `docs/PLATFORM.md:17` | "It does not ship in the first version" about strict mode — no D-number anywhere, and `ROADMAP.md:620` puts strict mode at **Phase 6**, before Phase 7's second platform. Genuinely undecided; stated as settled. |

**`docs/DESIGN.md:566`** — `unsettled` `#5A6066` measures **2.97:1** against `bg`, 0.03 under the
3:1 WCAG non-text floor, on the state D7 calls the most diagnostic signal in the product. Two
routes: carry contrast with stroke weight (the showcase moved its ring 1.4 px → 1.6 px), or change
the hex, which amends D19. Not decided which. The doc's own prescribed fix says move "from
`outline` to `mute`" — **both retired tokens**, so the remedy is currently un-followable.

Every other contrast figure in `DESIGN.md` was spot-checked against WCAG relative luminance
computed from the hex and verified exactly.

---

## At risk

**Nothing at the root is under version control.** `git rev-parse` at the repo root returns
"fatal: not a git repository". The only `.git` in the tree is `force-old/.git`. The 50 KB decision
record, 166 KB of docs and the 56 KB roadmap exist as single unversioned copies.

**`force-old/` has 43 uncommitted changes**, and the most-cited files in it are **untracked**:
`Sources/ForceKit/` (72 KB — contains `Engine/AcknowledgementGate.swift`, the file D8 came from),
`docs/` (contains `research-affirmations-habits-ai-mentor-v2.md`, the research `CLAUDE.md` says v1
failed to implement), `Sources/ForceDesktop/`, `Sources/ForceCLI/`. Last commit is `a0f86e5`
"android: pre-test", 2026-05-25. One `git checkout` loses them.

**~~The demo and flow-chart source is gone.~~ Recovered 2026-08-07, and the five published
artifacts turned out to be gone instead.** Both halves of this entry were wrong, in opposite
directions. Corrected:

- **All five published artifacts were deleted.** Every URL below now returns "artifact not
  found", and the account listing shows nothing newer than 2026-07-31. The recovery path this
  file assumed — "re-deriving from the published single-file HTML" — was already closed when it
  was written.
- **The source survived** in `~/.claude/file-history/7d6102db-e380-49d1-9586-1a9b98ab9e71/`:
  119 byte-exact snapshots, one per Write of every part file. The earlier search missed it
  because it looked for the *scratchpad* paths, which were deleted, not for file history.
  The true part filenames were confirmed against
  `~/.claude/projects/-Users-clupa-Documents-projects-force/7d6102db-….jsonl` (41 MB), which
  records all 26 part paths and the original `build_demo.py`.

All five now rebuild from `design/` — see [`design/README.md`](design/README.md). Only
`fonts_b64.json` and `masks_b64.json` were unrecoverable, because they were made with Bash
rather than Write; `design/build.py` regenerates both from fonts and images still in the repo,
plus `Fraunces-Italic.ttf`, which had no other copy here and came from google/fonts.

Verified by rendering, not just parsing: 27 demo states, 24 flow nodes, 34 screen plates with
zero unresolved anchors, both engraving masks recolouring correctly, all embedded JS passing
`node --check`.

| Artifact | Dead URL (2026-08-04/05) | Live URL (2026-08-07) |
|---|---|---|
| Force — the screens | `a86525d2-…` gone | `https://claude.ai/code/artifact/1630888d-ff95-4e8b-9277-34c605eb3375` |
| Force — the whole shape | `8ca00599-…` gone | `https://claude.ai/code/artifact/63a29a42-ee7e-4f73-95af-352aa3f43c57` |
| Force — the desktop demo | `7aafd3cf-…` gone | `https://claude.ai/code/artifact/c0bcd7b5-b32e-4acf-919e-77fb89a1bcec` |
| Force — Motion & Palette Lab | `cc3cfa41-…` gone | `https://claude.ai/code/artifact/63fab816-a39f-48ab-b717-19116f79ec75` |
| Force — Wireframe Walkthrough | `f26ab991-…` gone | `https://claude.ai/code/artifact/a3391319-f4e9-4d19-a3af-719e48e56899` |

Republishing any of them from a later session needs the URL passed as `url`, or it mints a new
one. **The artifact is no longer the only copy** — `design/` is, and `design/` is still not
under version control, because nothing here is. That is Phase 0, item 1.

**The demo implements seven things `FORCE-V2.md` does not authorise.** They are tagged `open` in
the artifact's Notes drawer and none may be treated as settled until each goes into the record as a
numbered decision with reasoning: the commit flood (accent filling the window — breaks D19's
one-use rule *and* D17, since nothing clears 4.5:1 on that orange); the moving line replacing
D20's layered ring; the line being orange and still at rest, which puts two accents on five
screens; the reversibility rule ("everything before a commitment is reversible, the commitment is
not, and the screen says which it is"); directional page transitions with no blur; stagger only
where order is information; and the bloom at 0.95 s against D20's ~1.15 s.

---

## Verified on this machine, 2026-08-06

| | |
|---|---|
| Flutter | 3.44.8 stable, rev `058e0af2c2` (2026-07-23), engine `13ffd72b2f9a5ca4db2a74ea52d5353ec2e8f939` |
| Dart | 3.12.2 stable, macos_arm64 |
| Xcode | 26.6, build 17F113, `xcode-select -p` → `/Applications/Xcode.app/Contents/Developer` |
| Android SDK | `~/Library/Android/sdk`, NDKs `27.0.12077973` and `28.2.13676358` |
| Emulator | AVD `force_spike` present at `~/.android/avd` |
| iOS simulators | iOS 26.4 and 26.5 runtimes, iPhone 17 family + iPads, all shut down |
| Spike source | all intact — including `spikes/flutter-showcase/lib/scenes/settle_scene.dart`, which D20 makes the source of truth for the settle spring constants |
| Spike evidence | `spikes/strict-mode/evidence/` holds exactly 25 files: 24 PNGs + `macos-events.log` |

`FORCE-V2.md:833` and `:837` claim the Xcode and Android toolchains are missing. They are not.

Reclaimable if disk matters: ~7.9 GB of build cache — `strict-mode/build` (2.9 G) +
`.dart_tool` (142 M), `flutter-gate/build` (1.6 G) + `.dart_tool` (67 M),
`tauri-gate/src-tauri/target` (1.6 G), `flutter-showcase/build` (769 M) + `.dart_tool` (539 M).
Keep every `lib/`, `macos/Runner/`, `android/.../kotlin/`, `tools/`, `evidence/`, `shots/` and
`.md` — those are the findings.

---

## Still open beyond Phase 1

Grouped by the phase they block. Not exhaustive — `plans/ROADMAP.md:911` has the full table and
`docs/DATA-MODEL.md:890` has fifteen more at schema level.

- **Phase 2** — does the claim get its illustration at commit or later; the register dial (separate
  setting, or is picking a voice picking the register); the onboarding script, whose structure D9
  locks and of which **not one word is written**.
- **Phase 3** — which model, and does the backend come forward to host it (Phase 3 precedes Phase 4,
  so either the client holds a key or the backend gets pulled forward); voice provider, and whether
  the on-device fallback feels like graceful degradation or a downgrade; **Tempo's actual API
  surface — no Tempo data has ever been read**; what counts as "vague" testimony, which is the one
  D6 trigger that cannot be read straight off the local record.
- **Phase 4** — database and auth, which `docs/DATA-MODEL.md` calls "**UNDECIDED, and this is the
  big one**"; whether recordings sync at all and whether they are encrypted, which is raised
  nowhere in `FORCE-V2.md` and should be, before recordings of someone's worst nights are uploaded.
- **Phase 5** — which surface the Counsel lives on (D14's table does not mention it); whether it can
  write back to a claim or only propose, which collides with Principle 5.
- **Phase 6** — **what strict mode actually does**, as opposed to what the OS permits. D18 proved
  capability. Interrupting on a schedule and blocking chosen apps until the day settles are
  different products, and the Kotlin `AccessibilityService` work in `force-old/android` was built
  for the second.
- **Phase 7** — Windows strict mode, entirely unresearched; if both a Mac and a phone can present
  the gate, which owns the night; Play policy on `SYSTEM_ALERT_WINDOW`, `QUERY_ALL_PACKAGES` and
  `specialUse`.
- **Cross-cutting** — the image model's exact ID (provider settled by D24; `COSTS.md` was priced
  live 2026-08-04 and goes stale fast); minimum OS versions; the licence (v1 was MIT, v2's is not
  chosen, and there is no `LICENSE` file); version numbering for the first v2 release.

Also untested and load-bearing: physical Android hardware and OEM battery-killer behaviour (the
single biggest real-world risk to the Android gate, untestable on an emulator); Windows at all,
which needs CI; sustained 120 Hz on a real ProMotion device under thermal load — every showcase
frame number is iOS Simulator, debug, 60 Hz and must not be quoted as a device figure.

---

## Two process rules to carry back in

From `FORCE-V2.md` §6, and the roadmap's closing line: **every feature gets shown individually, in
multiple approaches, and is judged by whether it *feels* right in use — not by whether the spec
reads well.** "A phase with every box ticked and no pull toward it has not passed. It has produced
a well-tested v1."

And on motion specifically: **ship a control, not a value.** Feedback on the demo arrived as felt
symptoms — "comes in too fast", "the staggered animation is too fast" — never as a spec, and "too
fast" turned out to have three different root causes (the curve, then the ordering, then the ratio
to the other motions). The Motion panel is where those numbers should get decided. One ask per
pass; do not batch.
