# Force v2 — Roadmap

**Status:** plan. Nothing is built yet; `/Users/clupa/Documents/projects/force` is not a git
repository as of 2026-08-04.
**Source of truth:** [`../FORCE-V2.md`](../FORCE-V2.md). Every decision cited below as (D1)…(D24)
lives there with its reasoning. If this file and that file disagree, that file wins.

---

## How to read this

There are no dates in this document. Nothing here is late because a week went by; it is late
because the thing it was meant to prove has not been proved. A phase is finished when its exit
criteria are met and not before, and the criteria are written so that someone else could check
them without asking how it felt.

Each phase gives you four things:

| | |
|---|---|
| **Depends on** | the locked decisions it implements, by number |
| **Built** | what actually gets written |
| **Exit** | observable criteria — a command that passes, a file that exists, a week that happened |
| **Open first** | questions that must be answered before the phase can start, with where they came from |

An exit criterion that reads "feels good" is not an exit criterion. Where the only honest test
*is* the user's judgement — and for a product judged by feel there are several — the criterion
names the specific thing being judged and the specific moment it gets judged in.

---

## The one ordering rule

**macOS ships first and alone. Nothing touches Windows or Android until the user has personally
run Force for 28 consecutive days on macOS.**

This is not caution for its own sake. `force-old/` had five front ends over one broken loop:
the SwiftUI Mac app (`Sources/Force`), a CLI (`Sources/ForceCLI`), a SwiftCrossUI desktop port
(`Sources/ForceDesktop`), a Next.js web app (`web/`), and a Kotlin Android client (`android/`).
The loop underneath all five stored a timestamp and nothing else, and it died at week seven.
Five surfaces multiplied a thing worth zero.

**This is D22**, which states it as a sentence: *"macOS ships first and alone, and nothing
touches Windows or Android until 28 consecutive days have been run on it personally."*

The reasoning behind it was already in the record. D1 says it directly: *"Ubiquity is a
multiplier. It multiplies whatever the loop is worth. Shipping a broken loop to a second
platform breaks it in two places."* Principle 1 says *"Scarcity over ubiquity."* The 28-day
number is D4's pursuit length — one full claim cycle, including the day-7 sharpening and the
day-28 retirement window, so the platform gate and the product's own clock are the same clock.

---

## Standing rules — these apply in every phase

Six things that were true of v1 and must never become true again. Check them at the end of every
phase, not once at the end.

1. **No process-scoped booleans in gate logic. Ever.** This is the v1 bug in one line
   (`AcknowledgementGate.swift:31` returning `sessionAcknowledged`). Gate state is derived from
   persisted wall-clock facts, recomputed idempotently (D8).
2. **The gate never waits on a network call.** Not the model, not speech-to-text, not sync. The
   day settles offline or the design is disqualified (§1b, D11).
3. **Nothing visible happens on a first miss.** No colour, no word, no streak notice. Verify it
   by looking, every phase (D12).
4. **Silence is a valid output from the AI.** It may only say things that are impossible without
   your record. Generic encouragement is the canned mantra again, with audio (Principle 3).
5. **Never hard-lock the machine.** `windowShouldClose -> false` and `.terminateCancel` both work
   on macOS and both are proven in [`../spikes/strict-mode/FINDINGS.md`](../spikes/strict-mode/FINDINGS.md).
   Do not take them. The comment `// the "no escape" rule` at `force-old/Sources/Force/App.swift:30`
   produced exactly one outcome: total escape (D7).
6. **Legibility is a floor, not a target.** 15px minimum for anything readable, 17px for body,
   4.5:1 contrast, no text under 0.7 opacity, `MediaQuery.textScaler` honoured and never clamped
   (D17). Force is opened on the nights the user is least sharp. That is the design case, not an
   edge case.

---

## Phase 0 — The ground

Nothing here is product. It is the floor everything else stands on, and two of the four items
have already bitten someone in the spikes.

**Depends on:** D13 (Flutter), D15 (functionality-only phase discipline), D17 (legibility floors),
D19 (the Ash palette — the token layer's values).

### Built

**The repository.** `git init` at the project root. First commit before any Dart is written, so
the whole build has history. Two calls to make while doing it: whether `force-old/` stays in the
tree as history or moves to its own archive, and whether `spikes/` is committed (it contains
build output — `spikes/flutter-gate/build/` and `spikes/swift-gate/.build/` are both on disk).
The `.gitignore` matters more than usual here because Flutter, Gradle and SwiftPM all litter.

**A fresh Flutter project.** Not an evolution of `spikes/flutter-gate`.
[`../spikes/SPEC.md`](../spikes/SPEC.md) says it plainly: *"This is a throwaway… None of this
code survives."* It reused v1's theme on purpose so the comparison measured the stack rather
than someone's taste. Copying it forward would smuggle throwaway styling into the product, which
is exactly what D15 forbids. What does carry over is the *knowledge* — the notes in
[`../spikes/flutter-showcase/NOTES.md`](../spikes/flutter-showcase/NOTES.md) are worth more than
the code.

Two settings from the spike that should be there on day one:

- `uses-material-design: false` in `pubspec.yaml`. The Material icon font is 1.6 MB and nothing
  uses it.
- `WidgetsApp`, not `MaterialApp` or `CupertinoApp`. Force uses neither design system, and both
  put an inherited lookup on the path of every `Text`.

**Design tokens.** **The palette is decided: Ash, D19.** Ten tokens, listed in D19 and expanded
with their measured contrast in [`../docs/DESIGN.md`](../docs/DESIGN.md). Nothing in the token
layer needs to be a placeholder, because there is no longer an open question to hold a place
for — D15 defers the *design pass* (composition, polish, identity), not the values.

What made this urgent is unchanged: v1's palette is strictly monochrome
(`force-old/Sources/Force/Theme.swift:69` maps `accent`, `info` and `sale` all to `ink`) and v2
has three day-states. A monochrome system physically cannot render `kept` / `broken` /
`unsettled`. Phase 0 takes `kept` `#EDEAE4`, `broken` `#8A7566` and `unsettled` `#5A6066`
straight from D19 rather than inventing three stand-ins.

Two things to carry across with them. `accent` `#B4553A` has exactly one use in the whole
product (D20 — the emphasis mark on the falsifiable half of the claim), so a token layer that
lets it become a button colour has already lost it. And `unsettled` measures 2.97:1 against
`bg`, 0.03 under the 3:1 non-text floor — see DESIGN.md's Open section; the fix is stroke
weight, not a new hex.

The showcase already did the contrast audit and it produced real casualties worth inheriting.
These are v1's spike-era colours, measured — they are why D19 exists, not what Phase 0 ships:

| Colour | Contrast on `base` `#141515` | Verdict |
|---|---|---|
| `ink` `#F2F2F0` | 16.32:1 | fine |
| `mute` `#9A9E9F` | 6.77:1 | the quietest voice in the app |
| `stone` `#60646A` | **3.07:1** | **retired as a text colour** — survives only as the fill of a `broken` mark, where the 3:1 non-text minimum applies |
| `outline` `#3C3F40` | 1.72:1 | invisible as a 1.4px `unsettled` ring on a dark phone at night; the ring is `mute` at 1.6px |

**The font pipeline, and the Fraunces trap.** This is the sharpest edge in the whole port and it
fails silently.

> Flutter instantiates the **fvar default instance** of a variable font. Fraunces' default is
> `wght 900 / opsz 9` — Black, at caption optical size. You do not get an error. You get type
> that looks heavy and slightly wrong and you spend an afternoon wondering why.

Every text style must pin both axes explicitly:

```dart
List<ui.FontVariation> _v(double wght, double opsz) => [
  ui.FontVariation('wght', wght),
  ui.FontVariation('opsz', opsz),
];
```

CoreText does the optical-size mapping for free on the SwiftUI build. Flutter does not, and
there is no automatic mapping to turn on. Inter is a variable font too and has the same problem,
just less visibly.

**The doc set.** [`../README.md`](../README.md), [`../CLAUDE.md`](../CLAUDE.md),
[`../CHANGELOG.md`](../CHANGELOG.md), [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md),
[`../docs/DESIGN.md`](../docs/DESIGN.md), [`../docs/COPY.md`](../docs/COPY.md),
[`../docs/PLATFORM.md`](../docs/PLATFORM.md), [`../docs/DATA-MODEL.md`](../docs/DATA-MODEL.md),
and the skills under `.claude/skills/`.

### Exit

- [ ] `git log` shows the project's history from its first commit. `git status` is clean.
- [ ] A **release** build (`flutter build macos --release`, then launch the `.app` — `flutter run`
      is debug and its numbers mean nothing here) reaches first paint from a cold start in under
      ~250 ms, matching the spike's measured 208 ms median (196–223 ms range) in
      [`../spikes/RESULTS.md`](../spikes/RESULTS.md). Measure it the way the spike did — `t0` from
      the kernel's `p_starttime`, never a timestamp taken inside Dart; the `force-build` skill has
      the working method. If it is materially slower, find out why now rather than in Phase 6.
- [ ] A specimen screen renders every token in the type scale, and a **test fails** if any
      `TextStyle` in the theme lacks explicit `fontVariations` for `wght` and `opsz`.
- [ ] A **test fails** if any token's `fontSize` is under 15, or if any text token's computed
      contrast against `base` is under 4.5:1 (D17).
- [ ] The specimen screen at 200% `textScaler` clips nothing and overflows nothing.
- [ ] The three day-state marks are distinguishable from each other at arm's length on the
      user's own screen — judged by the user, once, on that screen.

### Open first

Nothing blocks Phase 0. One item can now be **closed**: `../FORCE-V2.md` §5b lists "Full Xcode is
required for Flutter macOS" as outstanding with only Command Line Tools installed. Xcode 26.6 is
now at `/Applications/Xcode.app` (it was installed for the strict-mode spike). Tick it off.

---

## Phase 1 — The loop, local only

No backend. No AI. No network. This is the phase that decides whether v2 is a different product
or v1 with better fonts.

**Depends on:** D2 (identity claim), D3 (evidence produced not asserted), D5 (two beats, one
gate), D7 (three day-states, "Not tonight"), D8 (lifecycle law), D17.

### Built

**The morning beat.** ~10 seconds, no lock. One line: your claim, and the single thing today that
would count as evidence for it. One tap to adjust. A briefing, not a trial. This is where the
implementation intention lives, and it is what makes the evening beat measurable at all — *"did I
do what I said"* requires that you said something (D5).

**The evening gate.** 60–90 seconds. Your claim, what you committed to this morning, and you
speak what actually happened. In this phase there is no AI, so the gate is the default shape from
D6: one prompt, you speak, it closes.

**The three-state verdict.** `kept` / `broken` / `unsettled`, and the distinction between the
last two is load-bearing (D7). Broken means you showed up and lost. Unsettled means you didn't
show up. Conflating them corrupts the record, and a run of `unsettled` days is *the app dying* —
the one thing v1 could never see about itself. It just stopped, and nobody noticed for 25 days
until someone read a log file.

**"Not tonight."** One tap. No confirm dialog, no guilt copy, no "are you sure". It closes
instantly. The moment quitting the night gets expensive, you quit the app instead.

**The morning-after question.** Not the same gate re-shown — that builds a nag. One smaller,
different thing: *"Yesterday didn't settle. Bad day, or busy day?"* Two taps. Those two answers
deserve completely different responses and it is the only distinction that matters at that
moment (D7 rule 3).

**The record.** The seven-day strip, and whatever surface reads the history behind it.

**The lifecycle layer — this is where v1 actually died, so it gets built properly the first
time.** The logical day is the unit, with a configurable boundary defaulting to **4am, not
midnight**: a 12:30am evening beat belongs to *that* day. Every beat's state is persisted and
re-derived from timestamps. Recompute on launch, `didBecomeActive`,
`NSWorkspace.didWakeNotification`, `NSCalendarDayChangedNotification`,
`significantTimeChangeNotification`, plus a coarse timer as a backstop. v1 observed none of the
middle three (D8).

**This cannot be done in Dart, and that is proven, not assumed.** The strict-mode spike found
that `AppLifecycleState` fires for activation changes and **never fires for screen sleep or
wake**. The nine `NSWorkspace` / `NSNotificationCenter` observers are ~35 lines of Swift over one
`FlutterMethodChannel`, and they are mandatory.

### Exit

The headline criterion is the one that matters: **the user runs it for a week, on real days, on
their own machine, with no developer intervention.** Made concrete:

- [ ] Seven consecutive logical days where every day reached a terminal state.
- [ ] Those seven days contain **at least one `broken`** and **at least one `unsettled`**. A week
      of nothing but `kept` has not tested the failure paths, and the failure paths are the
      product (Principle 4).
- [ ] The app survived a full lid-close overnight and the next morning's beat was correct.
- [ ] The app survived being left running across a 4am boundary without restarting, and the day
      rolled.
- [ ] The app survived a restart mid-day, after the morning beat, and did not re-ask for it.
- [ ] `NSWorkspace.didWakeNotification` verified **by hand**. The spike could not trigger real
      system sleep (`sudo pmset schedule wake` needed a password it could not supply) and
      explicitly flags this as unverified. It is the exact event that killed v1. Close the lid,
      wait, reopen, check the log. Two minutes.
- [ ] `grep` the gate logic for process-scoped booleans. Zero results.
- [ ] Recomputation is idempotent — running it a hundred times equals running it once, under test.

### Open first

**Speech-to-text: on-device or cloud.** Listed as undecided in `../FORCE-V2.md` §5b. D11's
constraint is hard: it must degrade to *something* offline, because the gate can never depend on
a network call. D3's constraint is subtler and cuts the other way — the mechanism is *speaking
it aloud and putting it back through your own ears*, not the transcript. The input method is not
the mechanism.

That leaves a real interim option: **Phase 1 captures and keeps the audio and
does not transcribe it at all**, with typing available for public places (D3). The day settles,
the record holds the recording, and transcription arrives in Phase 3 where the AI needs text to
notice that four days in a row said *"went gym"* and nothing else. This is a suggestion, not a
decision — it needs a call before Phase 1 starts, because it changes the data model.

**Where the gate window lives.** [`../spikes/strict-mode/FINDINGS.md`](../spikes/strict-mode/FINDINGS.md)
§4 recommends the gate be a second borderless `NSPanel` on its own `FlutterEngine` with its own
Dart entrypoint (`gateMain`), rather than the main window — *"that separation is architectural,
not cosmetic."* But the panel only becomes necessary for covering another app's full-screen
Space, which is Phase 6 work.

Two options, and this needs deciding before Phase 1 rather than during Phase 6:

| | Cost | Risk |
|---|---|---|
| Panel now | ~35 lines of Swift and a second engine, in the phase that should be about the loop | Adds a platform-code surface before the loop is proven |
| Main window now, panel in Phase 6 | Simpler Phase 1 | If the gate's widget tree grows dependencies on app-window state, Phase 6 stops being a hosting change and becomes a rewrite |

The middle path — build it in the main window but write the gate as a self-contained tree with
no reach into app-level state, so `gateMain` stays viable — is what this document recommends.
It is a recommendation, not a decision.

---

## Phase 2 — Onboarding and claim authorship

**Depends on:** D2 (what makes a claim good), D4 (one primary + up to two background; 28-day
pursuit; the no-external-enforcer test), D9 (commit night one, sharpen day seven), D16 (only if
the illustration call below goes early), Principle 5 (the user authors, the AI proposes).

### Built

**The derived focus list.** D4's selection rule, as an actual screen rather than a table in a
design doc. You name the areas of your life. You mark which ones have something outside you that
enforces them — deadlines, clients, meetings, other humans. What is left over *is* the list.

| Domain | Enforcer if you go quiet |
|---|---|
| Studies | deadlines, grades, uni |
| Contract work / business | clients, invoices, people waiting |
| DSEC | meetings, other humans, a calendar |
| **Health** | **nobody** |
| **Job hunt / PR** | **nobody, ever** |
| **Relationships** | **nobody — and it decays silently** |

The framing matters and should survive into the copy: this is **an output, not a restriction**.
Once you strip out what enforces itself, the list *produces* three claims. Burying the two
things that need defending inside six that don't is how they got lost in v1.

And the primary is chosen by **what your mind is most willing to quietly drop** — not by what
matters most.

**The yap.** Night one, voice or writing. You talk. Nothing is labelled provisional anywhere in
the UI, because the felt sense of *this is what I'm sticking to* is load-bearing and a
placeholder cannot produce it (D9).

**Claim proposal, with citation.** The AI proposes 2–3 candidates. Every one is shown with the
quote it came from:

> **"I am someone who trains when I don't feel like it."**
> *from what you said: "the days I actually go are the days I almost didn't"*

**If the AI can't cite you, it doesn't get to propose it.** The attribution is the mechanic, not
decoration — it is the proof the sentence came out of your mouth rather than the model's, and
that is what makes it yours (D9).

**Editing until it fits.** The sentence is editable any time, zero friction. You will rewrite a
claim five times before it fits, and rewording until it is true *is* the work (D4).

**v1's contract as input.** 160 lines of the user already exist in `force-old/`. The first
session reads it and brings it as material. Don't start from zero when you've already written
the thing (D9 mechanic 2, and the parked "contract → claim migration" idea).

**The 28-day clock.** Starts on commit. The pursuit is locked; the wording is not. Exiting early
costs one spoken receipt — what the evidence showed and why you're stopping — and it goes into
the record permanently. Not as punishment: a log of what you've abandoned and why is the most
useful document about you that could exist (D4).

**The day-7 sharpening.** The first scheduled review. You now have a week of real evidence
including at least one bad day. You can rewrite the wording. **You cannot retire at day 7.** Day
28 is the first retirement window.

The reasoning should carry into the copy: every claim written on day one is written by the
wrong person. Day-one you is maximally motivated and has just spent twenty minutes thinking
about who they want to be. Tired-you on day nineteen has to live with the sentence. Those two
people don't know each other, and v1's contract was the artifact of day-one you — none of it
survived contact with tired-you.

**The first model call.** This is where an LLM enters the product, one phase before the AI layer
proper. That is fine and it is a different animal: it happens once, at onboarding, off the
critical path of the nightly gate. A 10–20 second wait while you sit reading your own words back
is acceptable. A 10–20 second wait at 11:40pm before you are allowed to speak is disqualified
(§1b).

### Exit

- [ ] The user goes through onboarding from cold, on their own machine, without the developer
      touching a debugger, and comes out the other side with a claim they would defend.
- [ ] **Every** proposed claim in that session carried a citation to something the user actually
      said. Zero uncited proposals — this is a code-level guarantee, not a prompt instruction.
- [ ] The user edited the claim at least once before committing. If nobody ever edits, either
      the model is writing the sentence or the editing affordance is not visible enough. Both
      are failures of Principle 5.
- [ ] The focus-list screen produced three claims from the user's real life, not from an example.
- [ ] Day 7 arrives on its own and offers a rewrite. Retirement is not offered and cannot be
      reached.
- [ ] **The strong one:** the claim committed in that session is still the claim on day 7 —
      rewritten, sharpened, argued with, but not abandoned in disgust.

### Open first

- **Illustration scheduling.** D16 puts a generated per-claim image at commit and again every 28
  days, and calls it *the "visualise it" mechanism from the opening brief*. "Couldn't visualise
  it" is one of the six reasons the user gave for why v1 died. That is an argument for pulling
  it into this phase rather than leaving it in Later. It is also a whole provider decision (see
  Deferred) and a source of latency in the one flow that should feel like a ceremony. **Needs a
  call: does the claim get its image in Phase 2, or later?**
- **The register dial.** Parked, not scheduled — one setting at onboarding for how blunt the AI
  is by default, locked for 28 days. D11 raises the open question of whether **picking a voice
  IS picking the register**, so you hear what you're signing up for instead of reading an
  adjective. If it ships, onboarding is where it lives. If the voice/register prototype has not
  happened by the time Phase 2 starts, ship onboarding without it and add it in Phase 3.

---

## Phase 3 — The AI layer

**Depends on:** D3 (AI challenges, never grades), D6 (adaptive gate form), D9 (day-7 and day-28
reviews), D11 (no persona; voice; on-device fallback; always interruptible), D12 (escalation
ladder), Principle 3, Principle 6, and §1b's speed-vs-LLM tension.

### Built

**The adaptive gate.** Most nights: one question, you speak, it closes, ~30 seconds. It opens
into a real conversation only when the data earns it (D6):

- the day settled as **broken**
- the testimony was **vague** — *"went gym"* and nothing else
- **Tempo contradicts you** — you said you trained, there is no session
- it's your **second consecutive miss**
- the **28-day review** is due

Every one of those is a moment where a human who cared about you would say something. On every
other night it shuts up and gets out of the way, and that is what buys it the right to not shut
up on those five.

Not a conversation every night: four turns at 11pm becomes a chore by night twelve, and worse, it
becomes *predictable* — you would learn its questions and pre-load your answers on the walk home.
Not a fixed ritual either: three identical fields every night is v1's structure with better
labels. **The property that matters is that you cannot predict what tonight costs you.** Fixed
intensity trains you to it no matter how high you set it.

**The escalation ladder** (D12). Three rungs, and the first one is the hardest to build because
it is nothing:

| Event | Response |
|---|---|
| 1st miss (`broken` or `unsettled`) | **Nothing. Genuinely nothing.** No colour change, no "streak broken", no gentle reminder. Silence. |
| 2nd consecutive | The gate opens into conversation — and asks about the *pattern*, not the day. Already a D6 trigger; no new machinery. |
| 3rd consecutive | **The claim goes on trial.** *"Three in a row. Is this claim wrong, or is this week wrong?"* Miscalibrated → rewrite the wording, always free. Hostile week → name it, and the app backs off instead of pushing. |

If one bad day produces any visible reaction, you learn the app is watching for failure — and
the cheapest way to avoid the reaction is to stop opening it. That is precisely the behaviour
that killed v1.

**Voice** (D11). Four options, chosen for **stance** not demographics: warm / flat / dry / hard.
Gender and accent fall out rather than drive.

ElevenLabs is fine if it is pipelined. Naively it is two network hops before you hear anything —
but you speak for ~30 seconds, and that is 30 seconds of headroom. Draft and synthesise while
the user is still talking, ready the instant they stop. **On-device fallback is mandatory**:
offline or API down, the day still settles and something still gets said. And the voice is
**always interruptible** — one tap kills it mid-sentence, because a voice you can't stop becomes
a voice you dread, and dread is how apps get deleted at 1am.

**Tempo.** D3's rule: numbers come from the source. Force should never ask whether you trained.
It should already know, and open with the consequence. This is also the first instance of the
suite pattern — **prefer reading facts from a sibling app over asking the user**.

And plainly: no Tempo data has ever been read. Only the tool list and its one-line
description were visible in the design session. That is how the app was known about at all.

**The 28-day review.** Flagged in `../FORCE-V2.md` §5b as needing its own design — *"it's the
moment claims live or die."* It is a D6 conversation trigger and a D4 retirement window and a
D16 image regeneration, all landing on the same night. Design it as a thing, not as three
features that happen to coincide.

### Exit

- [ ] **The latency test.** Turn the wifi off. Complete an evening gate. The day settles, and
      something is said. Then turn wifi on and confirm the model's response arrives *after* the
      day is already settled and does not retroactively change the verdict.
- [ ] **The nothing test.** Deliberately miss one day. Open the app the next morning and look at
      every surface. Nothing changed — not a colour, not a word, not a count. This is a manual
      inspection and it should be run at the end of every subsequent phase too.
- [ ] **The trigger-count test.** Over 14 days of real use, count the nights the gate opened into
      conversation. That number equals the number of D6 trigger events that occurred. Not more.
      If the gate is talking on nights it wasn't earned, D6 has quietly become "conversation
      every night".
- [ ] **The Principle 3 test.** At least one thing the AI said during those 14 days is something
      no chatbot on earth could have said, because it required the record. *"Third tired session
      this week, and you closed this app after 1am on all three of those nights."* If everything it said would
      also have come out of a generic model with no context, the AI layer has failed regardless
      of how pleasant it was. Note the shape of that example: it claims only what Force's own
      timestamps prove. D24 corrects the older *"slept past midnight"* wording precisely because
      Force has no sleep data and should not ask for it.
- [ ] The voice can be killed mid-sentence with one tap, from every screen that plays it.
- [ ] The on-device fallback speaks when the network is off.
- [ ] Escalation reaches rung 3 in a test harness with a synthetic three-miss run, and the trial
      offers both branches — rewrite the claim, or name the week.

### Open first

- **Which model, and where it runs.** Undecided. Phase 4 puts a backend on Vercel; a model call
  can live there, or the app can call a provider directly. Note that Phase 3 comes *before*
  Phase 4, so either Phase 3 calls a provider straight from the client with a key on the device,
  or the backend gets pulled forward. **Needs a call.**
- **Speech-to-text**, if it was deferred out of Phase 1. It has to land here — D6's "vague
  testimony" trigger and the "Tempo contradicts you" trigger both need text.
- **Tempo's actual API surface.** Nothing has been read from it. Before building the
  contradiction trigger, read a real session and find out what is actually there.
- **Voice provider and the on-device fallback's quality.** ElevenLabs is named as *fine* in D11,
  not as decided. The on-device fallback on macOS is `AVSpeechSynthesizer`-class quality and the
  gap between it and ElevenLabs may be large enough that hearing the fallback feels like a
  downgrade rather than a graceful degradation. Worth listening to both before committing.

---

## Phase 4 — Backend, sync, then the web dashboard

**Depends on:** §1b (cloud sync + restore; hosting is Vercel), D13 (the design system now lives
in two places — Dart and React), D14 (what the web may and may not do).

### Built

**Sync, local-first.** The device writes first and always. The server is where state survives a
lost laptop, not where the gate gets its answer. If sync is ever on the critical path of settling
a day, standing rule 2 has been broken.

**The web dashboard**, and the line D14 draws through it:

| Web (Vercel) | Native app |
|---|---|
| Landing page | **The evening gate — only ever here** |
| Progress, statistics, analysis | The morning beat |
| Reading the full record | Voice capture |
| *Some* claim edits — **wording, never commitments** | |
| Account & billing | |

**Why the gate can never live on the web:** if you can settle your day in a browser tab, the gate
loses scarcity, and you would settle days half-watching something else. That is reflex-ticking
with extra steps — v1's death reproduced faithfully in a new medium.

**The two-design-systems tax.** D13 states this cost honestly rather than hiding it: Dart for the
app, React for the Vercel surfaces. It was Tauri's single best argument and it was real. The way
to keep it to *one* payment is to make the token layer from Phase 0 the single source and
generate both ends from it, rather than maintaining two hand-written palettes that drift.

### Exit

- [ ] **The restore test.** Delete the local store on the Mac entirely. Sign in. The full record
      comes back — every day, every verdict, every recording, the claim, the receipts. Compare
      against a pre-deletion export and diff it.
- [ ] **The offline test, again.** Unplug the network. Settle a day. Plug it back in. The day
      appears on the server with its original timestamp and logical-day assignment, not the
      reconnection time.
- [ ] **The web dashboard cannot settle a day.** Not "there is no button" — there is no endpoint.
      A test posts a verdict from a web session and gets refused.
- [ ] Web claim editing changes wording and cannot start, stop, or retire a pursuit.
- [ ] The Dart and React token sets are generated from one file, and a test fails if they diverge.

### Open first

- **The database.** Genuinely undecided. `../FORCE-V2.md` fixes hosting to Vercel and says
  nothing about storage. v1 talked directly to **Supabase** — GoTrue for auth, PostgREST for a
  single `contents` row per user, with RLS (`force-old/docs/ARCHITECTURE.md`). Reusing it is
  cheap and the user knows it. Choosing something else is also fine. **Needs a call.**
- **Auth.** Same status, same shape. v1 used Supabase email+password. Nothing in v2 decides it.
- **Where the audio lives.** The evening beat produces a recording every night. That is the
  largest thing Force stores and it is the most personal. Vercel Blob is the obvious answer given
  the hosting constraint, but nothing has decided it, and there is a real question about whether
  recordings sync at all or stay on the device with only the transcript going up.
- **Encryption.** Not raised anywhere in `../FORCE-V2.md`. It should be, before recordings of
  someone's worst nights are uploaded anywhere.

---

## Phase 5 — The Counsel

**Scope status: IN. D22 puts the Counsel in v1.** The reasoning it carries: *"Time is not the
bottleneck; iteration quality is."* Open question 13 is closed, and §5b's "product features
parked" entry for the Counsel is superseded by it. Build this phase.

D22 attaches one ordering rule and only one — **macOS ships first and alone, 28 consecutive
days** — which is [the ordering rule](#the-one-ordering-rule) at the top of this document. Being
in scope does not move the Counsel earlier; it comes after the Loop for the reason below.

**Depends on:** D22 (the Counsel is in v1 scope), §2 (two surfaces — the Loop and the Counsel),
the north star acceptance test, the scope boundary, Principle 3.

### Why it is here and not earlier

The Counsel is only worth anything **because the Loop feeds it.** Any chatbot can debate two
options with you. Only Force can say *"you've claimed this for nineteen days and defended it
four times — the question isn't which to prioritise, it's whether you're going to keep saying
that sentence out loud."* The Loop is what makes the Counsel unfakeable, which means the Counsel
cannot come first.

### Built

An on-demand conversational surface for when you're stuck. *"I have two things and I don't know
which to defend this week."* It interrogates, you answer, it converges, and **something gets
decided and written down.**

**The scope boundary is a feature, not a limitation.** Force does not answer *"what should I do
at 2pm."* You have a calendar and a todo list, and any app that tries to own your task list
becomes a task list. Force answers **"which part of me am I defending this month, and is that
still the right one."** Choosing your primary claim *is* the prioritisation act. Everything below
it is downstream — you already know what to do once you know who you're being.

### Exit

The north star is the acceptance test, and it is stated in `../FORCE-V2.md` §2 as a sentence:

> *"You should not be the one helping me organise my thoughts. Force should be."*

And concretely: **the design session that produced `FORCE-V2.md` should have been a Counsel
session.** That is the bar. Made checkable:

- [ ] The user brings one real decision they are actually stuck on — not a test case — and runs
      a Counsel session on it.
- [ ] The session **converges**. Something is decided.
- [ ] The decision is **written down** into the record, with its reasoning, in a form that is
      still legible in a month. Same property `FORCE-V2.md` has.
- [ ] At least once during the session, the Counsel cited the record in a way that changed the
      shape of the conversation — not a decoration, a turn that would not have happened without
      it.
- [ ] **The negative test:** ask it to plan your afternoon. It declines and redirects. If it
      cheerfully produces a task list, the scope boundary has already leaked.

### Open first

- **Which surface.** D14's table divides the web and the native app and does not mention the
  Counsel at all. Only the *gate* is explicitly barred from the web. The Counsel is a
  sit-down-and-think surface, which argues for the web — but it is also the thing that most
  needs the record and the voice, which argues for native. **Undecided. Needs a call.**
- **Whether the Counsel writes back.** It converges on a decision and writes it down — into what?
  If it can change a claim, it has a power the Loop deliberately withholds from the AI
  (Principle 5). If it can only *propose*, the same citation mechanic from D9 should apply.
  Not decided anywhere.
- **Persona debate mode** is parked (see Deferred) and lives inside the Counsel when it lands.
  Phase 5 should not close off room for it.

---

## Phase 6 — Strict mode on macOS

This is the phase that cashes in **D21**. Force is not going on the Mac App Store; it ships from
GitHub, signed with Developer ID and notarised. That call is already made, so this phase spends
it rather than raising it.

**Depends on:** D18 (what the OS actually permits — tested, not read), D21 (distribution: GitHub
+ Developer ID, not the App Store), D12 (never auto-offered), D7 (never hard-lock), D8 (the
lifecycle observers, which this phase formalises).

### Built

**The gate panel.** The finding that matters most in
[`../spikes/strict-mode/FINDINGS.md`](../spikes/strict-mode/FINDINGS.md), because it looks like a
wall and isn't:

> The wall remembered from v1 — *"my window can't get above a full-screen app"* — **was not a
> wall. It was the wrong window.**

Six attempts to fix `MainFlutterWindow` (`canJoinAllSpaces`, `fullScreenAuxiliary`, `stationary`,
level 3 and level 1000, `orderFrontRegardless`) all reported `isOnActiveSpace: false`. A
hand-written AppKit app with identical flags overlaid instantly. So macOS allows it; Flutter's
storyboard-created main window, belonging to a `.regular` app with a Dock tile and a menu bar, is
never re-assignable to another app's full-screen Space.

The shape that works is ~35 lines: a borderless `.nonactivatingPanel` at `.screenSaver` level
with `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`, hosting a
`FlutterViewController` on a second `FlutterEngine` running a `@pragma('vm:entry-point')
gateMain` Dart entrypoint. It covers another app's full-screen Space **without stealing focus or
switching Spaces**, which hands D7's "insistent but always escapable" over for free.

One consequence to design around: because the panel is non-activating, keyboard focus stays with
the app underneath. If the evening beat needs typing (D3's "typing available when in public"),
you must *also* activate — a deliberate second step, not a side effect.

**The LaunchAgent.** ~55 lines. Proven: app killed at 11:23:01, relaunched by launchd at
11:23:52. And `open -a <bundle>` on a live app does not spawn a second process, so v1's
`SingleInstance` hazard does not reappear if you launch through `/usr/bin/open`.

**What you must not build.** `windowShouldClose -> false` works. `applicationShouldTerminate ->
.terminateCancel` works. Both were verified. **Leave them out.** `kill -TERM` kills the process
instantly and cannot be blocked, so the machine is never truly hostage either way — but the
*feeling* of being trapped is what deleted v1, and the panel already gives you total visual
presence without it.

**How it is offered.** It is never auto-offered. Suggesting it right after you fail reads as
punishment and you will feel handled. It lives in settings, is mentioned once at onboarding, and
is never brought up again. You go looking for it on a good day (D12).

### The distribution consequence — decided, and it was decided in strict mode's favour

The LaunchAgent needs `com.apple.security.app-sandbox = false`. Under the sandbox,
`launchctl bootstrap` fails with status 5, "Input/output error" — the plist gets redirected into
the app's container. Verified in the spike (Q4b).

Unsandboxed means: no Mac App Store, Developer ID signing, notarization, direct download, and
**your own updater**. **D21 takes that trade.** Force ships openly on GitHub, signed and
notarised, with Gatekeeper bypass instructions in the README — v1 already distributed this way.
The reasoning, in D21's words: keeping the interruption feature that was the original point of
Force matters more than store presence.

So this phase does not have a distribution blocker. It has a build-and-release checklist:
Developer ID signing, `notarytool` submission and stapling, a `.dmg` on the Releases page, and
an updater we host.

### Exit

- [ ] The gate panel reproduces `q2-l`: a full-bleed Flutter gate over another app's full-screen
      Space, with `onActiveSpace: true`, no Space switch, and `frontmost` still reporting the
      other app.
- [ ] `kill -TERM` still kills it. Force Quit still works. Activity Monitor still works.
- [ ] The LaunchAgent relaunches the app after it is killed, and `launchctl print` shows a clean
      exit code.
- [ ] Uninstalling strict mode removes the LaunchAgent completely — `launchctl print` reports not
      found and the plist is gone. The spike left no state on the machine; the product must not
      either.
- [ ] A notarized build downloaded from a GitHub release installs on a **second Mac** with no
      Gatekeeper warning, and the README's bypass instructions are checked against what that Mac
      actually shows (D21).
- [ ] The self-hosted updater updates a running install, end to end, once.
- [ ] Strict mode is not mentioned anywhere in the app except settings and one line at
      onboarding. Grep the copy.

### Open first

- **What strict mode actually *does*.** D12 calls it an "opt-in daytime interruption tier" and
  §5 parks "interruption mode" as an escalation you unlock after repeated breaks. D18 proves what
  the OS *permits*. Nothing decides what it *should do* — how often it interrupts, what it shows,
  what unlocks it. That is a design phase of its own and it should not be improvised at build
  time.

---

## Phase 7 — Windows, then Android

**Gated by the 28-day rule.** Not startable until the user has run Force on macOS for 28
consecutive days.

**Depends on:** D13 (Flutter chosen partly *because* Android built first try with zero source
changes), D18 (Android strict-mode capabilities and holes).

### Windows first

Windows is the market (D13). It also cannot be built or felt from this Mac —
[`../spikes/RESULTS.md`](../spikes/RESULTS.md) says so plainly: *"Windows. Cannot be built or
felt from this Mac; needs CI."* So Phase 7 opens with a GitHub Actions pipeline before it opens
with a feature.

**Exit:**

- [ ] CI produces a signed Windows build on every push to the main branch.
- [ ] The full loop — morning beat, evening gate, three states, the record, sync — works on real
      Windows hardware, run by a real person for a week.
- [ ] Cold start to first paint measured on Windows and compared against the macOS number. The
      spike measured macOS only.
- [ ] Fraunces renders correctly. Same variable-font trap, different text stack.

**Open first:** **Windows strict mode is completely unresearched.** The strict-mode spike covered
macOS, Android and iOS. There is no equivalent finding for Windows — no data on always-on-top
over full-screen apps, no data on scheduled launch, no data on what the OS lets you refuse.
Either that spike happens, or Windows ships without strict mode and says so.

### Then Android

Android is where Flutter earned the decision: **built first try, zero source changes, 39 MB
release APK.** Tauri needed three toolchain fixes on a screen with one window API call and never
produced an APK at all.

The SDK is already installed at `~/Library/Android/sdk`.

**Two traps, both already paid for once:**

1. **`mForceHideNonSystemOverlayWindow`.** Android force-hides all non-system overlays whenever a
   foreground app calls `Window.setHideOverlayWindows(true)`. Settings does. So do system
   permission dialogs. **The user can always escape the gate by opening Settings.** Fine under
   D7 — but any product copy promising *"you can't get past it"* would be a lie, and should never
   be written.
2. **`FlutterRenderer: Width is zero. 0,0`.** A `FlutterView` added to `WindowManager` with
   `MATCH_PARENT` never paints. The window exists, `dumpsys` shows it, the engine starts, the
   screen is blank. The fix is explicit pixels from `wm.currentWindowMetrics.bounds` **and**
   wrapping the `FlutterView` in a plain `FrameLayout`. This cost 20 minutes in the spike and it
   is in no documentation.

**The code split, quantified:** ~165 Kotlin + ~35 XML against ~50 Dart. Dart owns the pixels
inside the overlay and nothing else. When the gate appears, whether it may appear, staying alive
to make it appear, coming back after a reboot — all Kotlin. That is the same split as macOS, and
~165 lines is not a reason to leave Flutter; it *is* a reason not to expect a package to hand it
to you.

**Exit:**

- [ ] The full loop runs on the user's **physical** Android phone for a week. The spike was
      emulator-only and says so.
- [ ] The overlay gate appears over the launcher, over a browser, and over another app — and
      visibly does not appear over Settings, which is correct behaviour and should be confirmed
      rather than debugged.
- [ ] The foreground service survives a real reboot (`BOOT_COMPLETED`) and an app update
      (`MY_PACKAGE_REPLACED`). Both were proven on the emulator; both need a device.
- [ ] It survives 48 hours on the user's actual phone without the OEM battery manager killing the
      service. This is the single biggest real-world risk to the Android gate, it is untestable
      on an emulator, and `force-old/plans/roadmap.md` Track 2 already flagged it.

**Open first:**

- **Play Store policy.** `SYSTEM_ALERT_WINDOW`, `QUERY_ALL_PACKAGES` and the `specialUse`
  foreground-service type all attract review. Untested and unaffected by the Flutter choice
  either way. Same risk v1 carried, now with evidence that the technical half works.
- **Whether Android gets the evening gate at all, or only the morning beat.** D5 says one gate a
  day and D14 says the gate is native-only — but "native" now means two or three devices. If both
  the Mac and the phone can present the gate, which one owns the night? Nothing decides this.

---

## Later — explicitly deferred, explicitly not forgotten

The user asked for this list by name: *"please keep note about all of these things because I'll
probably forget about what we need to do down the line."*

### iOS — companion only, and probably never

`../FORCE-V2.md` D13: the user has no iPhone. iOS is a free by-product of the Flutter choice, not
a target. And the strict-mode spike is blunt about the ceiling: **an iOS app cannot force itself
to the foreground. There is no API, no entitlement, no workaround.**

What iOS could offer: local notifications at `.timeSensitive`, and Live Activities. Two things to
know before anyone gets excited — a Live Activity is a WidgetKit/SwiftUI extension, so **Flutter
can never render one**, and `FamilyControls` failed at runtime with `NSCocoaErrorDomain 4099`
because it needs the Apple-gated `com.apple.developer.family-controls` entitlement. Shield UI is
a SwiftUI app extension too. If Force ever ships iOS blocking, that surface is hand-written
Swift, permanently.

Honest position: **iOS is a companion, not a gate surface.** It can say *the day hasn't settled*.
It can never make you settle it.

### Illustration (D16) — if it does not land in Phase 2

**Locked already:** engraving line art, knocked out to transparency, recoloured onto the app's
ground so it inherits the palette rather than dictating one. Chosen over abstract, cinematic and
risograph, and proven on three grounds in `spikes/illustration/proof-recolour.png`. It also
carries a thread from v1, which used sketchy hand-drawn marks.

**Where it goes:** the per-claim image at commit and every 28 days; the record, reviews and
onboarding — the sit-down-and-read surfaces.

**Where it must never go: the evening gate.** That screen is the claim, the voice, and what
happened. Decoration there is the app patting you on the head at the moment it should be taking
you seriously.

The principle it produces outlives illustration: **what repeats must be abstract
or absent; what is rare can be vivid.** Straight out of how v1 died.

**The provider is decided — D24.** Stay with what produced the approved samples. One provider,
one pipeline; revisit at thousands of users. The whole reason a shortlist existed was native
transparency, and that turned out to be unnecessary, so the shortlist below is history rather
than a decision to make. At ~13 images per user per year the price gap between any two of them
is a few dollars, which does not buy a second integration.

| Option | $/image | $/1000 users/yr | Note |
|---|---|---|---|
| Recraft V3 Vector | $0.08 | $1,040 | Ships a literal `Engraving` style and returns true SVG. Fine cross-hatching is the worst case for vector. |
| Ideogram 3.0 Turbo `generate-transparent` | $0.04 | $520 | The only provider with native-alpha *generation*. `style_code` is a persistent style ID. |
| FLUX.1 [schnell] via Together | $0.0027 | $39 | 15× cheaper, Apache-2.0, no style ID, DIY knockout |

**What is still open is the exact model ID**, and D24 says to confirm it at wiring time: Imagen 4
shut down 2026-08-17, and that is a different model from the Gemini image model the samples came
from. Full research in [`../spikes/illustration/COSTS.md`](../spikes/illustration/COSTS.md),
priced live on 2026-08-04 and going stale fast.

Two things that make this easier than it looks. **DIY knockout is not the weak option** — because
the subject is black linework on white, luminance thresholding is *more* reliable than a
segmentation model, which happily eats thin hatch lines. Already proven. And **the prompt must
explicitly forbid paper texture, vignette, border, frame and drop shadow**, or the image knocks
out as a visible rectangle; the `dir3-engraving` tile in the proof sheet shows exactly that
failure.

Time bombs not to build on: `gpt-image-2` has no transparency; `gpt-image-1-mini` and `1.5`
(which do) shut down 2026-12-01; Imagen 4 shuts down 2026-08-17; no Gemini/Nano-Banana model has
an alpha channel at all.

### The suite API — Tempo, Recall, Kiro, Force

Long-term intent: one API so they all talk to each other. Force is arguably the natural hub,
since it is the one asking *"what did today actually contain"* — and every other app already
knows part of the answer.

Treat it as a standing design constraint from Phase 3 onward rather than a project:
**prefer reading facts from a sibling app over asking the user.** Tempo → Force is the first
instance and proves the pattern. `force-old/mcp` also exists and can be re-pointed at the v2
data model once there is one.

### Calendar integration

Not "remind me at 6pm". The user's framing is the right one: *"look at the calendar and say —
you seem to be free at this time, do it then. Sounds good, I'd commit to it."* Force proposes the
gap it found; the user accepts. Never a fixed clock time that reality then invalidates over and
over.

### Persona debate mode

Stand up two arguers for two options and watch which one you flinch at. The point isn't that the
AI decides — it's that hearing a case made for the option you *weren't* going to pick exposes
what you already wanted. Lives inside the Counsel.

### Everything else on the deferred list

- **Interruption mode** — opt-in daytime escalation, unlocked after repeated breaks. Related to
  strict mode but not the same thing; strict mode is the machinery, this is the policy.
- **Android app-blocking** — the `AccessibilityService` work in `force-old/android`, genuinely
  the most interesting engineering in the old repo. It returns once strict mode is real. The
  spike proves the *overlay half* of that design works with Flutter UI inside it.
- **Voice/register unification** — prototype whether picking a voice IS picking the register
  (D11's open question).
- **Full palette rework** — **done as a decision (D19, Ash).** What is deferred is applying it
  across every surface, not choosing it. Phase 0 takes the ten tokens straight from D19.
- **Visual identity** — logo, landing page, app icon, `force.clupai.com`.
- **Motion design pass** — **the four moments are decided (D20)**: Ink Bloom, Italic + rule, the
  layered ring, Fling. What is deferred is applying them everywhere and tuning on real hardware.
  The settle animation is the emotional centre of the gate, and its spring constants live in
  `../spikes/flutter-showcase/lib/scenes/settle_scene.dart` — read them there rather than copying
  them into a doc. The showcase already proved the ceiling: velocity-carrying retargetable
  springs, per-word blur without a `saveLayer`, a full-screen GLSL field with per-pixel dither,
  and a word-level diff that makes a sentence visibly rewrite itself. 14,884 frames, 0.02% over
  the 60 Hz budget.
- **Accessibility** — raised explicitly. The app should work for people who aren't in a sharp
  mental state, which, given it is designed to be faced on bad nights, is *most* users *some* of
  the time. Plain language, low reading load, nothing that punishes a slow response, every action
  reachable without precision. D17 is the floor, not the whole job.
- **Migration** — read the v1 contract and `acknowledgements.log` as onboarding material (D9).

---

## Open questions, by the phase they block

| # | Question | Blocks | Where it comes from |
|---|---|---|---|
| 1 | Speech-to-text: on-device or cloud, and does Phase 1 transcribe at all | Phase 1 | `FORCE-V2.md` §5b; D3; D11 |
| 2 | Gate in the main window now, or the `NSPanel` from the start | Phase 1 | `FINDINGS.md` §4 vs. phase discipline |
| 3 | Does the claim get its illustration at commit (Phase 2) or later | Phase 2 | D16; "couldn't visualise it" in §0 |
| 4 | Register dial — separate setting, or is the voice the register | Phase 2 / 3 | D11, open by name |
| 5 | Which model, and does the backend come forward to host it | Phase 3 | undecided; §1b latency constraint |
| 6 | Voice provider, and is the on-device fallback good enough to not feel like a downgrade | Phase 3 | D11 |
| 7 | Database and auth | Phase 4 | undecided; v1 used Supabase |
| 8 | Do recordings sync, and are they encrypted | Phase 4 | not raised anywhere — raise it |
| 9 | Which surface the Counsel lives on | Phase 5 | D14 divides web/native, never mentions it |
| 10 | Can the Counsel write back to a claim, or only propose | Phase 5 | Principle 5 vs. §2 "something gets decided" |
| 11 | What strict mode actually does, as opposed to what the OS permits | Phase 6 | D12 parks it; D18 only proves capability |
| 12 | Windows strict mode — entirely unresearched | Phase 7 | the spike covered macOS, Android, iOS |
| 13 | If Mac and phone can both present the gate, which owns the night | Phase 7 | D5 says one gate; D14 says native |
| 14 | The image model's exact ID (the *provider* is settled by D24) | Phase 2 / Later | D24's own "watch" note |

**Closed since the last revision, and no longer on this list:** the Counsel's place in v1 scope
(D22), the palette (D19), the motion language (D20), and Mac App Store versus Developer ID
(D21 — GitHub + Developer ID, signed and notarised).

---

## What this roadmap does not decide

It does not decide the palette, the motion language, the copy, the data model, or the
architecture. The palette and the motion language are already decided elsewhere (D19, D20) and
this file only says when they get applied. The rest live in [`../docs/DESIGN.md`](../docs/DESIGN.md),
[`../docs/COPY.md`](../docs/COPY.md), [`../docs/DATA-MODEL.md`](../docs/DATA-MODEL.md) and
[`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md). It decides the order, and what "done"
means at each step.

And it does not override the process agreement in `../FORCE-V2.md` §6, which outranks it:

> Every feature gets shown individually, in **multiple approaches**, and is judged by whether it
> *feels* right in use — not by whether the spec reads well. A feature the user feels no pull
> toward is a feature that's dead in six weeks, like the last one.

A phase with every box ticked and no pull toward it has not passed. It has produced a
well-tested v1.
