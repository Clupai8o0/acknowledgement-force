# Force v2 — Design Decisions

**Status:** in-progress design session (grilling). Nothing built yet.
**Started:** 2026-08-04
**Supersedes:** `force-old/` (Acknowledgement Force v0.3.0)

This file is the running record of the design conversation. Every locked decision
carries the reasoning that produced it, so future-us can tell the difference
between a considered choice and an accident.

---

## 0. Why v2 — the evidence

Pulled from `~/Library/Application Support/Force/acknowledgements.log` (the real
usage record, not memory):

```
2026-05-21 → 2026-07-10   145 acknowledgements across 38 days
Week 1–2:   6–9 opens/day, 14/14 days          ← engaged
Jun 4–5:    first 2-day gap                     ← inflection point
Jun 6–26:   1–3 opens/day, gaps widening
Jun 26 → Jul 4:  8-day gap
Jul 10:     final acknowledgement
Aug 4:      25 days dead; app no longer installed anywhere
```

Two facts do all the work:

1. **Death at week 7.** `docs/research-affirmations-habits-ai-mentor-v2.md` (already
   in the repo) states weeks 1–5 predict long-term adherence, and names
   "never miss twice" as the core mechanic. The two-day gap on Jun 4–5 is where the
   curve broke. The research was right; v1 didn't implement it.
2. **145 acknowledgements contain zero bits of information.** The log stores a
   timestamp and nothing else. The app could not distinguish the best day from the
   worst. Compliance and non-compliance were indistinguishable to it.

**User's own account of why it died:** the contract was too long; no emotional
connection; couldn't visualise it; nothing was tracked; it wasn't rewarding; it
became a reflex — scroll, tick, close.

---

## 1. Locked decisions

### D1 — The diagnosis we're fixing
**No feedback loop.** Habituation is its symptom, not its cause: you habituate fast to
a stimulus that carries no information. The gate said the same thing on day 1 and
day 40 regardless of anything you'd done. That's not accountability, it's a
screensaver with a checkbox.

Secondary, both real and both cheap to fix: the artifact was too large to internalise
(160 lines, 9 rules, 8 daily non-negotiables, 6 priority areas), and it was never
emotionally owned.

*Rejected as primary:* "wrong surface / not on my phone." Ubiquity is a multiplier.
It multiplies whatever the loop is worth. Shipping a broken loop to a second platform
breaks it in two places.

### D2 — The atomic unit is the **identity claim**
Habits are not chores; they are **evidence for or against a claim you have made about
yourself.** The contract becomes a small set of claims, not a document.

**What makes a claim good: it names its own evidence, and it can be false.**

- ❌ *"I am someone who takes care of their body"* — unfalsifiable. Any day can absorb
  it. A claim that can't be broken can't be kept.
- ❌ *"I train four times a week"* — a habit in an identity costume. Snaps the first
  week you get sick.
- ✅ *"I am someone who trains when I don't feel like it"* — today either contained a
  moment where you didn't want to and went anyway, or it didn't. You know which. So
  does the app.

*Rejected:* sharding the contract into lines (v1 with extra steps); a straight habit
tracker (every app on the store); promise/settle as the base unit (too transactional
to carry identity — but we steal **kept/broken** from it as the day's verdict).

### D3 — Evidence is **produced**, not asserted
- **Floor: spoken testimony.** One sentence in your own words naming what actually
  happened. Voice-first (typing available when in public). Speaking it aloud puts it
  back through your own ears — that is the mechanism, not the input method.
- **Numbers come from the source.** Tempo (workout MCP) is already wired up: sessions,
  sets, PRs, volume. Force should never ask whether you trained. It should already
  know, and open with the consequence.
- **AI challenges, never grades.** An AI that scores you becomes an opponent you game
  or resent, and you can lie to it for free. But it may push once:
  *"That's the fourth day running you've written 'went gym' and nothing else. That's
  not a record, that's a signature."*

*Disqualified: the checkbox.* It is literally v1. A box can be ticked while your mind
is elsewhere — that's the entire problem.

### D4 — One primary claim + up to two background; 28-day pursuit
**Selection rule — the no-external-enforcer test.** Force only covers life areas that
nothing else enforces.

| Domain | Enforcer if you go quiet |
|---|---|
| Studies | deadlines, grades, uni |
| Contract work / business | clients, invoices, people waiting |
| DSEC | meetings, other humans, a calendar |
| **Health** | **nobody** |
| **Job hunt / PR** | **nobody, ever** |
| **Relationships** | **nobody — and it decays silently** |

Burying the two things that need defending inside six that don't is how they got lost
in v1. Once you strip out what enforces itself, the list *produces* three claims — one
primary, two background. Not a restriction; an output.

**Primary is chosen by what your mind is most willing to quietly drop** — not by what
matters most.

**Change rules — revise freely, retire with a receipt.**
- The **sentence** is editable any time, zero friction. Rewording until it's true *is*
  the work; you'll rewrite a claim five times before it fits.
- The **pursuit** is locked for **28 days**. Exiting costs one spoken receipt: what the
  evidence showed and why you're stopping. It goes into your record permanently — not
  as punishment, but because a log of what you've abandoned and why is the most useful
  document about you that could exist.

*Rejected:* "locked 28 days but changeable any time" (those cancel out — a lock with
an any-time exit is a suggestion); a hard 30-day lock with no exit (teaches you the app
doesn't listen, and you route around it by not opening it — exactly how v1 ended).

### D5 — Two beats a day, exactly one of them a gate
**Morning — ~10 seconds, no lock.** Not a habit list. One line: your claim, and the
single thing today that would count as evidence for it. One tap to adjust. A briefing,
not a trial. (This is where implementation intentions live — and it's what makes the
evening beat measurable, since "did I do what I said" requires that you said something.)

**Evening — 60–90 seconds. This is the wall.** Your claim, what you committed to this
morning, and you speak what actually happened. Tempo has pre-filled the numbers. The
day settles as **kept / partial / broken**.

**Three hard rules:**
1. **One gate per day, exactly one.** v1 ran 6–9 gates a day in week one — that is the
   direct cause of "I scrolled through without reading." Scarcity is what makes a gate
   mean anything.
2. **"I didn't" is a complete, valid, closeable answer.** If the only exit is success,
   you'll lie or you'll stop opening it — and v1 shows which one you pick. A day that
   closes as *broken*, spoken honestly, is worth more than a day that closes as *kept*.
3. **The evening beat is day-close-based, not clock-based.** Shifts are chaos; some
   nights are 1am. It fires when you close the day, whenever that is. If you never
   close it, the next morning opens with *"yesterday never settled — what happened?"*
   One unsettled day is a question. Two in a row changes the app's behaviour toward you.

### D6 — The gate's form is **adaptive**: one prompt by default, conversation when earned
Most nights: one question, you speak, it closes. ~30 seconds.

It opens into a real conversation only when the data earns it:
- the day settled as **broken**
- the testimony was **vague** (*"went gym"* and nothing else)
- **Tempo contradicts you** — you said you trained, there's no session
- it's your **second consecutive miss**
- the **28-day review** is due

Every one of those is a moment where a human who cared about you would say something.
On every other night it shuts up and gets out of the way — which is what buys it the
right to not shut up on those five.

**Why not a conversation every night:** four turns at 11pm becomes a chore by night
twelve, and worse, it becomes *predictable* — you'd learn its questions and pre-load
your answers on the walk home. That's v1's scroll-and-tick with extra steps.
**Why not a fixed ritual:** three identical fields every night *is* v1's structure with
better labels.
**The property that matters:** you cannot predict what tonight costs you. Fixed
intensity trains you to it no matter how high you set it.

### D7 — The escape hatch: **"Not tonight"**, and the day logs as `unsettled`
There is no close button. There is a button that says *Not tonight*.
**The exit must be a statement, not a dismissal.**

A day ends in one of three states:

| State | Meaning |
|---|---|
| `kept` | you did it, evidenced |
| `broken` | you engaged and failed, spoken |
| `unsettled` | you didn't answer |

**`unsettled` is not `broken`.** Broken means you showed up and lost. Unsettled means you
didn't show up. Conflating them corrupts the record — and unsettled is the *more*
diagnostic signal, because a run of unsettled days is **the app dying**, and that's the
one thing v1 could never see about itself. It just stopped, and nobody noticed for 25
days until someone read a log file.

Rules:
1. **One tap. No confirm dialog, no guilt copy, no "are you sure".** It closes instantly.
   The moment quitting the night gets expensive, you quit the app instead.
2. Never-miss-twice applies to `unsettled` too. One is noise, zero guilt. Two consecutive
   changes the app's behaviour.
3. **What returns the next morning is not the same gate.** Re-showing last night's
   question builds a nag. It asks one smaller, different thing — *"Yesterday didn't
   settle. Bad day, or busy day?"* Two taps. Those two answers deserve completely
   different responses and it's the only distinction that matters.
4. **Never hard-lock the machine.** v1's `windowShouldClose` returning `false` is
   precisely what got the app deleted. A gate blocking a machine you earn money on is a
   hostage situation with your income attached. The gate owns its own window and nothing
   else.

> v1's `App.swift:30` carries the comment `// the "no escape" rule`. It produced exactly
> one outcome: total escape. An easy exit makes the app *more* effective, because the
> alternative to a cheap exit is never compliance — it's uninstallation.

### D8 — Lifecycle law: gate state is derived from persisted wall-clock facts, **never** from process memory

**The v1 bug, diagnosed.** `AcknowledgementGate.swift:31`:
```swift
case .everyLaunch, .onLogin:
    return sessionAcknowledged     // a per-process Bool
```
In those two modes the gate depends *only* on a boolean scoped to the process lifetime.
So: Force is running in the background → you acknowledge → `sessionAcknowledged = true` →
launchd fires `open Force.app` → `SingleInstance` hands off to the live process instead of
starting a new one → `didBecomeActive` → `recomputeGate()` → the Bool is *still true* →
**the gate never re-locks for as long as that process lives.** Sleep/wake, days passing,
nothing recovers it. A `Bool` has no clock.

The 30s `Timer` at `Store.swift:50` papers over `daily`/`hourly` but cannot help here —
there is no wall-clock fact to re-derive from. (The `flock`-based single-instance lock is
fine; the kernel releases it on process death. That part wasn't the problem.)

**Requirements for v2:**
- The **logical day** is the unit, with a configurable boundary — **default 4am, not
  midnight.** A 12:30am evening beat belongs to *that* day, not the next one. Shifts are
  chaos; the clock must match the life.
- Every beat's state is persisted and re-derived from timestamps. No process-scoped
  booleans anywhere in gate logic.
- Recompute on **all** of: launch, `didBecomeActive`, `NSWorkspace.didWakeNotification`,
  `NSCalendarDayChangedNotification`, `significantTimeChangeNotification`, plus a coarse
  timer as backstop. v1 observed *none* of the middle three.
- Recomputation is **idempotent** — running it a hundred times equals running it once.
- Must survive: wake from sleep (not just cold boot), restart mid-day after the morning
  beat, and the app sitting in the background for days without ever quitting.

### D9 — Onboarding: commit on night one, sharpen on day seven
**Structure of C, ceremony of B.** Nothing is labelled "provisional" in the UI — night one
is a real commitment with a real ritual, because the *felt* sense of "this is what I'm
sticking to" is load-bearing and a placeholder can't produce it.

- **Night 1** — you yap (voice or writing). The AI proposes 2–3 candidate claims. You pick
  one, edit it until it sounds like you, and commit. The 28-day clock starts here.
- **Day 7** — the first scheduled review. You've now got a week of real evidence, including
  at least one bad day. The AI shows you what actually happened and you *sharpen the
  wording*. You cannot retire at day 7 — only rewrite. (D4 already permits rewording any
  time; day 7 is just the first time the app makes you look.)
- **Day 28** — first retirement window. Receipt rule applies.

**Why not commit-and-never-review:** every claim written on day one is written by the
wrong person. Day-one you is maximally motivated and has just spent twenty minutes
thinking about who they want to be; tired-you on day nineteen has to live with the
sentence. Those two people don't know each other. v1's contract is the artifact of
day-one you and none of it survived contact with tired-you.
**Why not observe-first-with-no-claim:** a week with nothing to defend is a week with
nothing to do, in the exact window the research says decides retention.

**Two mechanics locked regardless:**

1. **Every proposed claim is shown with the quote it came from.**
   > **"I am someone who trains when I don't feel like it."**
   > *from what you said: "the days I actually go are the days I almost didn't"*

   The attribution is the mechanic, not decoration. It's the proof the sentence came out
   of your mouth rather than the model's — and that's what makes it yours. **If the AI
   can't cite you, it doesn't get to propose it.**
2. **v1's contract is onboarding input.** 160 lines of you already exist in
   `force-old`. The first session reads it and brings it as material. Don't start from
   zero when you've already written the thing.

### D10 — The name is **Force**
"Acknowledgement Force" is a description, not a name. Force is short, memorable, and
carries the idea.

**Reframe that resolves the tension with the product we designed:** Force is not what the
app applies to you — the app refuses to coerce. **Force is what you apply to your own
life.** The app is the thing that keeps the record honest. This reading is also a better
brand than the original.

### D11 — No persona. A voice, a register, and nothing to fanboy
**No character, no celebrity mentor.** Rejected because:
1. A character is something you *enjoy* — fun for two weeks, then it's a bit, and the day
   it stops being funny you stop opening the app.
2. Borrowed authority. Hormozi has never seen your record.
3. **It dilutes the only real advantage.** The most powerful thing Force can say is
   *"third tired session this week, and you slept past midnight before all three."* Nobody
   else on earth can say that. Dressing it in a podcast voice makes it sound like content
   — and you already ignore content. **Character comes from what it knows, not how it
   talks.**
4. A permanently-intense voice is a permanently-uninformative one. Always-loud equals
   always-silent.

*Also rejected:* "speaks as your future self" — that's the trait-affirmation the research
doc says failed to replicate, with a microphone.

**What you get instead — voice selection, 4 options, chosen for *stance* not demographics**
(warm / flat / dry / hard; gender and accent fall out rather than drive). Open question
worth prototyping: **voice choice and register dial may be the same control** — you pick a
voice and the voice *is* the register, so you hear what you're signing up for instead of
reading an adjective.

- **ElevenLabs is fine, pipelined.** Naively it's two network hops before you hear
  anything. But you speak for ~30s, and that's 30s of headroom: draft + synthesise while
  the user is still talking, ready the instant they stop.
- **On-device fallback is mandatory.** Offline or API down, the day still settles and
  something still gets said. The gate never depends on a network call.
- **The voice is always interruptible.** One tap kills it mid-sentence. A voice you can't
  stop becomes a voice you dread, and dread is how apps get deleted at 1am.

### D12 — Escalation: nothing, then a question, then a trial
| Event | Response |
|---|---|
| **1st miss** (`broken` or `unsettled`) | **Nothing. Genuinely nothing.** No colour change, no "streak broken", no gentle reminder. Silence. |
| **2nd consecutive** | The gate opens into conversation — and asks about the *pattern*, not the day. (Already a D6 trigger; no new machinery.) |
| **3rd consecutive** | **The claim goes on trial.** *"Three in a row. Is this claim wrong, or is this week wrong?"* Miscalibrated → rewrite the wording (always free). Hostile week → name it, and the app backs off instead of pushing. |
| **Strict mode** | **Never auto-offered.** Suggesting it right after you fail reads as punishment and you'll feel handled. It lives in settings, is mentioned once at onboarding, and is never brought up again. You go looking for it on a *good* day. |

**Why nothing on the first miss:** if one bad day produces any visible reaction, you learn
the app is watching for failure — and then the cheapest way to avoid the reaction is to
stop opening it. That is precisely the behaviour that killed v1.

### D13 — Platform: **Flutter** (decided by spike, against the initial recommendation)

> **RESOLVED 2026-08-04.** The spike overturned the Tauri recommendation on its own
> evidence. See the results table and the Android build log below.

**Why Flutter won:**
1. **Cold start 208 ms vs Tauri's 458 ms** — and it *matched native SwiftUI* (212 ms) with
   half the variance and the lowest memory of the three.
2. **The quality worry was false.** Fraunces renders indistinguishably from native. That
   was the main argument against shipping your own renderer; it's dead.
3. **Android built first try, zero source changes.** Tauri needed three fixes for the same
   screen: a `#[cfg(desktop)]` guard (`set_always_on_top` does not exist on Android), a
   Gradle/JDK version conflict (generates Gradle 8.14.3, which rejects the Java 25 that
   Android Studio ships), and then a `buildSrc` Kotlin failure when Gradle was bumped.
   Three toolchain blockers on a screen with **one** window API call.

**What it costs, stated honestly:** the design system now lives in two places — Dart for
the app, React for the Vercel landing page and dashboard. That was Tauri's single best
argument and it was real. But it's a tax paid once at the design-token level, versus
Tauri charging a platform-divergence tax forever *and* a 2.2× slower launch on the one
screen faced every night.

*(Original framing, kept for the record:)*
Target set is **macOS → Windows → Android** (the user has a Mac and an Android phone; no
iPhone; Windows is the market). That set rules Swift out as the cross-platform answer —
iOS-is-nearly-free is worth nothing to someone without an iPhone.

**Three-way spike before committing.** Same screen, three stacks, side by side on the
user's own Mac, judged by feel:

| | Renderer | Reaches | Cost |
|---|---|---|---|
| **SwiftUI** (`force-old`) | native AppKit/Metal | macOS only | the quality **benchmark**, not a contender |
| **Tauri v2 + React** | OS webview | Mac / Win / Linux / Android | engine differs per platform → look & motion diverge |
| **Flutter** | ships its own renderer | Mac / Win / Android / iOS | identical everywhere; Dart; no sharing with the Next.js web |

**Tauri is not Electron** — this was a live misconception and it's settled:

| | Electron | Tauri |
|---|---|---|
| Renderer | **bundles Chromium** | **uses the OS webview** |
| Backend | bundled Node.js | Rust, native binary |
| macOS engine | Chromium (in your app) | **WKWebView — same engine as Safari**, already in the OS |
| Windows engine | Chromium (in your app) | WebView2 — Chromium-based but *system-installed and shared* |
| Hello-world bundle | ~120–150 MB | **~5–10 MB** |

Tauri's real cost is **not** bloat — it's that each platform renders through a *different*
engine, so Mac / Windows / Android diverge in look and motion. That's precisely what
Flutter's own-renderer approach solves, and precisely what the spike exists to measure.

#### Spike results — macOS (2026-08-04). Full detail in `spikes/RESULTS.md`.

| | SwiftUI | Tauri v2 | Flutter |
|---|---|---|---|
| **Cold start → first paint** (median of 5) | 212 ms | **458 ms** | **208 ms** |
| spread | 174–318 | 418–470 | **196–223** |
| idle RSS | 103–107 MB | 111 MB | **99 MB** |
| bundle | **1.7 MB** | 10 MB | 36 MB |
| LOC, same screen | **799** | 881 | 944 |

**Three findings, two of which contradict the reasoning that produced D13's recommendation:**

1. **Flutter matched native and beat it on consistency** — 208 ms vs 212 ms, half the
   variance, *and* the lowest memory of the three. The expected penalty for shipping its
   own renderer did not appear.
2. **Tauri is 2.2× slower to first paint.** For a product whose whole job is to appear at
   11pm and be faced, this is the most relevant number in the table.
3. **The serif-rendering worry was unfounded.** All three render Fraunces cleanly and
   near-identically. That was the main qualitative risk cited against Flutter; it's dead.

**The Electron fear was misdirected but not baseless** — Tauri's webview costs ~8 MB more
memory than native, not 200 MB. Bloat was never the problem. *Latency* is.

**Still open:** sustained animation under load (the 40-bar meter exists in all three but
needs a human watching it, not a number), Windows (needs CI), and **Android — the actual
tiebreaker**, since that's where Flutter carries its own renderer and Tauri inherits
Android System WebView.

### D14 — Web dashboard: read the record, not settle the day
| Web (Vercel) | Native app |
|---|---|
| Landing page | **The evening gate — only ever here** |
| Progress, statistics, analysis | The morning beat |
| Reading the full record | Voice capture |
| *Some* claim edits — **wording, never commitments** | |
| Account & billing | |

**Why the gate can never live on the web:** if you can settle your day in a browser tab,
the gate loses scarcity, and you'd settle days half-watching something else. That is
reflex-ticking with extra steps — v1's death reproduced faithfully in a new medium.

### D15 — Phase discipline
**Now (experiment phase): functionality only.** Prove the loop works and the stack feels
right. The spike deliberately reuses v1's existing monochrome theme and fonts so the
comparison is about the *stack*, not the design.

**Later (product phase):** the full design pass — palette, motion, identity, polish. Do
not let theming leak into the experiment phase; do not let the experiment's throwaway
styling survive into the product.

---

## 1b. Hard constraints (non-negotiable, stated by the user)

- **UI quality is a primary requirement, not a finish.** This is a product judged by
  whether it *feels* right; a correct app that feels cheap is a dead app.
- **Speed is a primary requirement.** Every beat must feel instant.
- **Cloud sync + restore.** State lives on a server, not only on the device.
- **Hosting is Vercel.** Any web surface or server component deploys there.

> ⚠️ **Tension to resolve at architecture time:** speed vs. LLM. If a model call sits in
> the critical path of the nightly gate, the gate is only ever as fast as the network.
> Any design where you wait on a spinner before you can speak is disqualified. Likely
> shape: local-first writes, model responses stream in *after* the day is already
> settled, and the day settles with or without the model. Same question applies to
> speech-to-text (on-device vs. cloud).

---

## 2. Architecture: two surfaces

**The Loop** — morning/evening, rhythmic, automatic, low-effort. Claims and evidence.

**The Counsel** — on demand, conversational, for when you're stuck.
*"I have two things and I don't know which to defend this week."*

The Counsel is only worth anything **because the Loop feeds it.** Any chatbot can debate
two options with you. Only Force can say *"you've claimed this for nineteen days and
defended it four times — the question isn't which to prioritise, it's whether you're
going to keep saying that sentence out loud."* The Loop is what makes the Counsel
unfakeable.

### The north star (acceptance test)
> *"You should not be the one helping me organise my thoughts. Force should be."*

**Concretely: this grilling session should be a Counsel session.** Same structure — it
interrogates, you answer, it converges, and something gets decided and written down.

**Scope boundary.** Force does not answer *"what should I do at 2pm."* You have a
calendar and a todo list; any app that tries to own your task list becomes a task list.
Force answers **"which part of me am I defending this month, and is that still the right
one."** Choosing your primary claim *is* the prioritisation act. Everything below it is
downstream — you already know what to do once you know who you're being.

---

## 3. Principles (violate these and we rebuild v1)

1. **Scarcity over ubiquity.** One gate a day. More surfaces multiply the loop's value;
   they don't create it.
2. **Unpredictability defeats habituation.** If the gate is identical every night, you
   will learn to sleep through it.
3. **The AI may only say things that are impossible without your record.** Generic
   encouragement — *"that's okay, just make sure to..."* — is the canned mantra again,
   now with audio. You'd habituate to it faster than to the contract. **Silence is a
   valid output.**
4. **Failure must be a first-class, closeable state.** The bad night is the product.
5. **The user authors; the AI proposes.** It may never hand you your identity. It offers
   candidates *built from phrases you actually said*; you pick one and edit it until it
   sounds like you. If the machine wrote it, you didn't author it.
6. **Never miss twice.** One miss is noise, zero guilt. Two consecutive misses is when
   the app changes.

---

## 4. Open questions

```
✓ 1–8  diagnosis · atomic unit · evidence · claims · rhythm · gate form · escape hatch · lifecycle
✓ 9.  Onboarding — commit night one, sharpen day seven
✓ 10. No persona; voice selection; name is Force
✓ 11. Escalation — nothing / question / trial
✓ 12. Platform & stack — Flutter (D13)
✓ 13. v1 scope — Counsel is in (D22)
✓ 14. Palette — Ash (D19); motion (D20)
✓ 15. Rewrite vs evolve — full rewrite; force-old is reference only
```

**All numbered questions are closed.** What remains open is listed below, and none of it
blocks starting work.

### Still open — decide when reached
| | Default if unspecified |
|---|---|
| **The onboarding questions themselves** | not written; draft four and react to them |
| **Where the per-claim illustration appears** | record and reviews, *not* the morning beat — ten seconds is no time to look at a picture |
| **Sign-in in v1** | local-first, no account; sync arrives with the backend |
| **What happens to voice recordings** | transcribe on device where possible, keep the text, **discard the audio**. The record is words, not recordings. Affects onboarding copy, because users must be told |
| Backend / database | Supabase again — v1's schema already worked |
| Speech-to-text | platform-native first, cloud later; must degrade offline |
| LLM for challenges and the Counsel | Claude; model chosen at build time |
| TTS voices | four chosen for stance; prototype whether it is the same control as the register dial |
| Hosting costs / who pays | open source, self-host free, hosted backend optional |
| MCP carry-forward | yes eventually — it fits the suite plan |
| Travel / timezones | 4am boundary in device-local time; revisit if it bites |

### Genuinely undecided, not merely unscheduled
- **Does the app reject a bad claim?** D2 defines what makes one good — it names its own
  evidence and can be false. It was never decided whether the app *enforces* that. If
  someone writes *"I am someone who is happy"*, does it accept, push back once, or refuse?
  *Leaning: push back once, then accept.* Refusing grades you before you have started.
- **What strict mode actually does.** D18 proved what the OS permits. It was never decided
  what Force *does* with that — interrupt on a schedule, or block chosen apps until the day
  is settled. Those are different products. The Kotlin work in `force-old/android` was built
  for the second one.

### On the palette (raised mid-session)
The current system is **strictly monochrome** — `Theme.swift:69` maps `accent`, `info`
and `sale` all to `ink`. The instinct that "the colours don't portray Force" is literally
correct: **there are no colours.** Zero chroma, by design ("Digital Curator").

Two reasons not to touch it yet, and one reason it must change:

- **The brief doesn't exist yet.** Two hours ago Force was about coercion —
  `App.swift:30` says *"the no escape rule"*, and the product is named *Acknowledgement
  Force*. Today we designed its opposite: it cannot lock you out, *Not tonight* is one
  tap, failure is a first-class state, and its power comes from knowing your record
  rather than from blocking your screen. Choosing "stronger" colours this morning would
  have meant portraying **force** harder — the exact thing we just removed.
- **The name is upstream of the palette** and is now genuinely in question — resolved by D10 (the name is Force) and D19 (the palette is Ash).
- **But it must change, for a functional reason:** v2 has three day-states
  (`kept` / `broken` / `unsettled`) and the current palette can express exactly one.
  A monochrome system where `accent == ink` physically cannot render the record.

---

## 5. Parked ideas (not rejected, not scheduled)

- **Persona debate** — stand up two arguers for two options and watch which one you
  flinch at. The point isn't that the AI decides; it's that hearing a case made for the
  option you *weren't* going to pick exposes what you already wanted. Lives in the
  Counsel.
- **Interruption mode (opt-in escalation).** Not the base rhythm — an tier you unlock
  after repeated breaks, which interrupts during the day. Matches the research doc's
  escalate-on-second-miss guidance.
- **Voice output on the evening beat only.** Voice in the morning is a podcast you'll
  mute. Subject to Principle 3.
- **Register dial** — one setting at onboarding for how blunt the AI is by default,
  locked for the 28 days. But *mode* (encourage / plan / challenge) is picked by the app
  from your readiness state, not your preference. Rationale: you'll pick "harsh" in week
  one when you're motivated, and harsh is exactly what makes you close the laptop on the
  1am night after a bad week — which is the moment that decides everything. You set the
  accent; it picks what to say.
- ~~**Celebrity mentor personas** (Hormozi et al.)~~ — raised in the opening brief,
  **rejected by D11.** Kept here only so nobody re-proposes it.
- **Contract → claim migration.** The AI reviews your existing v1 contract and proposes
  claims from it, rather than starting from nothing.

---

## 5b. Deferred — things we agreed to do LATER (do not lose these)

> The user asked explicitly for this list: *"please keep note about all of these things
> because I'll probably forget about what we need to do down the line."*

### D18 — Strict mode: what the OS actually permits
Tested, not read. Full evidence in `spikes/strict-mode/FINDINGS.md` (25 screenshots + event log).

**Headline: Flutter changes nothing about the walls or the escapes.** Everything possible
natively is still possible. The cost is that **100% of strict mode is platform code — zero
lines are possible in Dart.** The gate's *UI* stays Flutter, running on a second engine.

**The wall remembered from v1 — "my window can't get above a full-screen app" — was not a
wall. It was the wrong window.** Six attempts to fix `MainFlutterWindow`
(`canJoinAllSpaces`, `fullScreenAuxiliary`, `stationary`, level 3 and 1000,
`orderFrontRegardless`) all reported `isOnActiveSpace: false`. A hand-written AppKit app
with identical flags overlaid instantly — so it was Flutter's main window, not macOS.

| Capability | macOS | Android | iOS |
|---|---|---|---|
| Raise itself unprompted | ✅ ~5 lines Swift *(fails while screen is locked)* | ✅ overlay | ❌ **impossible, no API** |
| Cover a full-screen app | ✅ **only via a separate `NSPanel`** | ✅ *(except over Settings)* | ❌ |
| Refuse to close / quit | ✅ both — **but `kill -TERM` always wins** | n/a | ❌ |
| Launch itself on a schedule | ✅ LaunchAgent — **requires sandbox off** | ✅ `BOOT_COMPLETED` + FGS | ❌ |
| Wake-from-sleep events → Dart | ✅ `screensDidWake` verified end-to-end | n/a | n/a |

**Two decisions this forces:**

1. **The gate must be a second `NSPanel`, not the main window.** Borderless
   `.nonactivatingPanel` at `.screenSaver` level with
   `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`, hosting a `FlutterViewController`
   on a second `FlutterEngine` (`@pragma('vm:entry-point') gateMain`). ~35 lines. It covers
   another app's full-screen Space **without stealing focus or switching Spaces** — which
   hands D7 "insistent but always escapable" for free.
2. **Strict mode takes Force off the Mac App Store.** LaunchAgent needs the sandbox off →
   Developer ID + notarization + a self-hosted updater. *A distribution decision hiding
   inside a settings toggle.* **UNRESOLVED — needs a call.**

**Confirmations and honest gaps:**
- **D8 is impossible in Dart.** `AppLifecycleState` fired for activation but **never** for
  sleep/wake. The ~35 lines of `NSWorkspace` observers are mandatory, not optional.
- **`kill -TERM` kills it instantly** — Force Quit and Activity Monitor can never be blocked.
  That is the OS boundary, and it is exactly the escape hatch D7 requires.
- **Android has a hole:** over the **Settings** app the OS force-hides the overlay
  (`mForceHideNonSystemOverlayWindow`). Any app calling `setHideOverlayWindows(true)` escapes
  the gate. Fine under D7 — but *"you can't get past it"* would be a lie.
- **Android code split: ~165 Kotlin + ~35 XML vs ~50 Dart.** Dart owns the pixels and nothing
  else. When the gate appears, whether it may, staying alive, surviving reboot — all Kotlin.
- **iOS cannot force itself to the foreground. No API, no entitlement, no workaround.**
  `FamilyControls` failed at runtime (`NSCocoaErrorDomain 4099`) — needs the Apple-gated
  `com.apple.developer.family-controls`. And shield UI is a **SwiftUI app extension**, so
  **Flutter can never render one.** iOS strict mode = notifications only.
- **Not tested, stated plainly:** real `didWakeNotification` (needs sudo); physical Android
  hardware; OEM battery-killer behaviour; Play policy on `SYSTEM_ALERT_WINDOW` / specialUse.

### D16 — Illustration language: **engraving line art, knocked out, recoloured**
Chosen from four generated directions (`spikes/illustration/`). Abstract and cinematic were
rejected — *"the abstract one didn't make sense to me"*, *"cinematic is just a street with a
kid in it"*. Risograph read as a generic agency poster.

**Why engraving wins:** it's the most workable and the most dynamic. The subject can be
knocked out to transparency and recoloured onto any ground, so it inherits the palette
instead of dictating one. It also carries forward from v1, which used sketchy hand-drawn
marks — so the product keeps a thread of its own history.

**Proven, not assumed** — `spikes/illustration/proof-recolour.png` shows the same three
engravings on dark, paper, and deep-teal grounds. Knockout uses luminance as alpha so the
cross-hatching keeps its anti-aliased edges rather than collapsing to jagged 1-bit lines.

> **Prompting rule discovered the hard way:** the prompt must explicitly forbid *paper
> texture, vignette, border, frame and drop shadow*, or the image knocks out as a visible
> rectangle. The `dir3-engraving` tile in the proof sheet shows exactly this failure.

**Where illustration goes, and where it must never go:**
- **Per-claim image** — generated once at commit, regenerated every 28 days from the user's
  own sentence and yap. This is the "visualise it" mechanism from the opening brief. Because
  it's rare and always changing, it can't become wallpaper.
- **Record, reviews, onboarding** — the sit-down-and-read surfaces.
- **Never the evening gate.** That screen is the claim, the voice, and what happened.
  Decoration there is the app patting you on the head at the moment it should be taking you
  seriously — the Calm/Headspace failure mode.

**Principle it produces:** *what repeats must be abstract or absent; what is rare can be
vivid.* Straight out of how v1 died — repetition kills anything.

**Generation provider** — full pricing research in `spikes/illustration/COSTS.md` (live
pricing, 2026-08-04; goes stale fast).

| Option | $/image | $/1000 users/yr | Note |
|---|---|---|---|
| **Recraft V3 Vector** | $0.08 | $1,040 | **Ships a literal `Engraving` style and returns true SVG.** Spike before committing. |
| **Ideogram 3.0 Turbo** `generate-transparent` | $0.04 | $520 | Only provider with native-alpha *generation*. `style_code` = persistent style ID. |
| **FLUX.1 [schnell]** via Together | $0.0027 | $39 | 15× cheaper, Apache-2.0, no style ID, DIY knockout |

- **Recraft is the one to test.** True SVG means no knockout step, recolour via
  `currentColor`, infinite scale. Risk: fine cross-hatching is the worst case for vector —
  every hatch line becomes a path. Generate five, check path count and file size.
- **DIY knockout is not the weak option.** Because the subject is black line art on white,
  luminance thresholding is *more* reliable than a segmentation model, which eats thin hatch
  lines. Already proven — see `proof-recolour.png`.
- **Time bombs to avoid depending on:** `gpt-image-2` has **no transparency support**;
  `gpt-image-1-mini`/`1.5` (which do) **shut down 2026-12-01**; **Imagen 4 shuts down
  2026-08-17**; **no Gemini/Nano-Banana model has an alpha channel at all**.
- **Self-hosting is never worth it here.** At ~13 images/user/year, cold starts dominate; a
  13 GB checkpoint costs more in load time than the API call. Crossover vs a $0.04 API is
  ~20,500 users/yr. Only reason to go there is a **custom LoRA** (~$2 one-off) if
  off-the-shelf engraving styles fail the taste test.
- **Vercel is fine** — Fluid Compute gives 300s max duration on Hobby, not 10s. Watch the
  4.5 MB response cap: stream to Blob, don't return the PNG inline.

### D17 — Minimum legibility (hard requirement, not a preference)
Raised after the user could not comfortably read label text in the Flutter showcase **on a
large screen at close distance**.

| Element | Minimum |
|---|---|
| Any readable text | **15px** |
| Body / conversational text | **17px** |
| Uppercase tracked labels | **14px** + real letter-spacing |
| Text contrast | **4.5:1**, and no text below 0.7 opacity |
| OS text-size setting | respected (`MediaQuery.textScaler`), never hard-clamped |

**Why this binds harder here than in most apps:** Force is *designed* to be opened on the
user's worst nights, when they are tired and not sharp. Poor legibility isn't an edge case
for this product — it's the core case. A screen that's hard to read at 11pm is a screen that
gets closed. If a composition depends on tiny type, the composition changes, not the type.

### D19 — Palette: **Ash** (RESOLVED)
Chosen from three live directions in the motion lab (Ash / Slate & Brass / Plate).

| Token | Hex | Role |
|---|---|---|
| `bg` | `#101112` | ground |
| `bg2` | `#191B1D` | raised surface |
| `ink` | `#EDEAE4` | primary text |
| `ink2` | `#A8AEB3` | secondary text |
| `ink3` | `#7E858B` | tertiary text |
| `kept` | `#EDEAE4` | day kept |
| `broken` | `#8A7566` | day broken |
| `unsettled` | `#5A6066` | day unsettled (ring) |
| `accent` | `#B4553A` | **one use only — see D20** |
| `rule` | `#2B2F33` | hairlines |

**What it replaces and why it had to change.** v1's theme mapped `accent`, `info` and
`sale` all to `ink` (`Theme.swift:69`), so it physically could not render three day-states.
Two of its colours also *failed measurement*: `stone` `#60646A` at **3.07:1** against the
4.5:1 minimum, and `outline` at **1.72:1**, which made the `unsettled` ring nearly
invisible — hiding the exact state that signals the app is dying.

### D20 — Motion: four locked choices (RESOLVED)
| Moment | Choice | Spec |
|---|---|---|
| **Claim entrance** | **Ink Bloom** | whole sentence resolves out of blur at once, ~1.15s. **No stagger** — word-by-word was rejected as too slow by day twenty |
| **Emphasis** | **Italic + rule** | the falsifiable half of the claim in italic; an accent rule draws left-to-right ~0.72s, starting ~0.9s after the bloom settles |
| **Hold to speak** | **Layered ring** | three closed contours drawn back to front, each a **solid body of its own colour** (`broken`, `ink3`, `accent`). Depth from overlap and occlusion. **The radial gradient was explicitly rejected.** |
| **Settle** | **Fling** | real spring physics integrated per frame, interruptible, no CSS/`Curve` easing. Constants live in `spikes/flutter-showcase/lib/scenes/settle_scene.dart` — read them there, don't restate them |

**Where the accent goes, and it is almost nowhere:** the emphasis mark inside the claim,
on the half of the sentence that can actually be false. *"I am someone who trains"* is
unfalsifiable; *"when I don't feel like it"* is the half that can be broken, and therefore
the only half that can be kept. One spot of colour in the whole app, on the words the
product is about.

### D21 — Distribution: **GitHub + Developer ID, not the App Store** (RESOLVED)
Resolves the question D18 left open. Ships openly on GitHub for download, signed with
Developer ID and notarised, with Gatekeeper bypass instructions in the README — v1 already
distributed this way and its README is a good model. Strict mode requires the sandbox off,
which the App Store forbids; keeping the interruption feature that was the original point
of Force matters more than store presence.

### D22 — v1 scope includes the Counsel (RESOLVED)
Confirmed. Time is not the bottleneck; iteration quality is. The one ordering rule stands:
**macOS ships first and alone**, and nothing touches Windows or Android until 28 consecutive
days have been run on it personally.

### D23 — Copy voice (RESOLVED — and this corrects a rule stated too narrowly)
The sentence that was **rejected**:
> "Drop it now and you're not deprioritising a habit — you're retiring a claim four days
> early, without the receipt."

The rewrite that was **approved**:
> "You started this 19 days ago. You've gone on 11 of them. There are 9 days left. Stop now
> and you never find out if it would have stuck."

Same idea. The second one you can *see* — a number, a countdown, a thing that happens.

**"Short sentences" is NOT the principle. Plain words and something picturable is.** That
distinction was collapsed once and corrected. Length is allowed and sometimes wanted,
because more words on screen means more seconds spent, and more seconds means more time to
visualise. The limit is that **v1 died of *passive* length** — 160 lines scrolled past.
Length only helps where the reader chose to read.

| Surface | Length |
|---|---|
| The claim | one sentence, always |
| The evening gate | short by default, with an openable "more" |
| **What the user says** | **no limit, ever** — this is the mechanism |
| Day-7 and day-28 reviews | properly long; nothing is trying to get you out |
| The Counsel | long |

Say **stop**, **wrong for you**, **quit** — never *deprioritise*, *miscalibrated*,
*retire a claim*.

### D24 — Image generation provider: stay with what produced the approved samples
Native transparency was the main reason to prefer Ideogram, and it turned out to be
unnecessary — for black line art on white, luminance thresholding beats a segmentation
model, which eats thin hatch lines. At ~13 images/user/year the price gap between providers
is a few dollars. **One provider, one pipeline.** Revisit at thousands of users.
*Watch:* confirm the exact model ID at wiring time — Imagen 4 shut down 2026-08-17, and
that is a different model from the Gemini image model used for the samples.

> **Correction to D11's example.** The canonical line was *"you slept past midnight before
> all three."* **Force has no sleep data and should not ask for it.** The line only claims
> what it can prove from its own timestamps: **"you closed this app after 1am on all three
> of those nights."** Same insight, no health permissions, no tracking.

---

**Design & identity (product phase, after the loop works)**
- [ ] **Full palette rework.** Current system is monochrome (`Theme.swift:69` — `accent`,
      `info`, `sale` all map to `ink`). It physically cannot render `kept` / `broken` /
      `unsettled`. Must change — but only once the register of "Force" is settled.
- [ ] Visual identity for the renamed product (Force, not Acknowledgement Force):
      logo, landing page, app icon, `force.clupai.com`.
- [ ] Motion design pass — the settle animation is the emotional centre of the gate.

**Product features parked, not rejected**
- [ ] **Counsel surface** — on-demand conversation for when you're stuck.
- [ ] **Persona debate mode** — two arguers for two options; you watch which you flinch at.
- [ ] **Strict mode** — opt-in daytime interruption tier. Never auto-offered.
- [ ] **Android app-blocking** (the Kotlin `AccessibilityService` work in `force-old/android`)
      — genuinely the most interesting engineering in the old repo. It's an *escalation*
      feature; it returns once strict mode is real.
- [ ] **28-day review ritual** — needs its own design; it's the moment claims live or die.
- [ ] **Voice/register unification** — prototype whether picking a voice IS picking the
      register, rather than two separate settings.

**Integrations**
- [ ] **The suite.** The user is building several apps for themselves — **Tempo** (workout
      logging), **Recall** (screen recording / personal management), **Kiro** (time
      management), Force, and more. Long-term intent: **one API so they all talk to each
      other.** Force is arguably the natural hub, since it's the one asking "what did today
      actually contain" — and every other app in the suite already knows part of the answer.
      Treat this as a standing design constraint: **prefer reading facts from a sibling app
      over asking the user.** Tempo→Force is the first instance and proves the pattern.
- [ ] **Calendar.** Not "remind me at 6pm". The user's framing, which is the right one:
      *"look at the calendar and say — you seem to be free at this time, do it then. Sounds
      good, I'd commit to it."* Force proposes the gap it found; the user accepts. Never a
      fixed clock time that reality then invalidates over and over.
- [ ] **Accessibility.** Raised explicitly: the app should work for people who aren't in a
      sharp mental state — which, given it's designed to be faced on bad nights, is *most*
      users *some* of the time. Plain language, low reading load, nothing that punishes a
      slow response, and every action reachable without precision.
- [ ] **Tempo (workout MCP)** — already connected in this environment. Sessions, sets, PRs,
      volume. Force should never *ask* whether you trained.
      *(Note: no Tempo data has been read. Only the tool list and its one-line description
      were visible in the session — that is how the app was known about at all.)*
- [ ] MCP server from `force-old/mcp` — re-point at the v2 data model once it exists.
- [ ] Migration: read the v1 contract + `acknowledgements.log` as onboarding material.

**Platform / infra**
- [ ] **Full Xcode is required for Flutter macOS *and* for any future iOS work.** Only
      Command Line Tools are installed (`/Library/Developer/CommandLineTools`). Tauri and
      SwiftUI build fine on CLT; Flutter desktop does not. ~15 GB, App Store, needs the
      user's Apple ID — cannot be automated.
- [ ] Windows build (GitHub Actions — can't be built or felt from this Mac).
- [ ] Android build (needs Android SDK + JDK + NDK, ~5 GB, none currently installed;
      user's phone is Android so this is a real target, not hypothetical).
- [ ] Vercel: API, auth, sync endpoint, model calls, web dashboard, landing.
- [ ] Decide STT: on-device vs cloud. Must degrade to *something* offline (D11).
- [ ] The latency pipeline from §1b — draft + synthesise the response **while the user is
      still speaking**, so nothing waits on a spinner.

**Known traps to re-check before shipping**
- [ ] Every lifecycle case in **D8** — wake from sleep, restart mid-day, app alive in
      background for days, 4am boundary. This is what broke v1 and it broke silently.
- [ ] No process-scoped booleans anywhere in gate logic, ever.
- [ ] Verify nothing visible happens on a **first** miss. Not a colour, not a word.

---

## 6. Process agreement

Every feature gets shown individually, in **multiple approaches**, and is judged by
whether it *feels* right in use — not by whether the spec reads well. A feature the user
feels no pull toward is a feature that's dead in six weeks, like the last one.
