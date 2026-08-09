# Force

**Force holds you to one sentence you have claimed about yourself, and asks you once a
night what today did to it.**

Not a habit tracker. Not a checklist. One claim, the evidence you produce for or against
it, and a record honest enough to be worth reading six months later.

> The name is not what the app applies to you — the app refuses to coerce you. **Force is
> what you apply to your own life.** The app is the thing that keeps the record honest. (D10)

### Status: nothing is built yet

Today this repository contains the decision record, the spikes that produced it, and the
version of the app that died. There is no v2 binary, no release, and no clone URL — this
repo has not been published. Everything below describes what v2 is being built to be. Where
something genuinely has not been decided, it sits under [Still open](#still-open) and says
so plainly.

| Path | What it is |
|---|---|
| [`FORCE-V2.md`](FORCE-V2.md) | The decision record. D1–D24, each with the reasoning that produced it. The source of truth. |
| [`spikes/`](spikes/) | Four measured spikes: the three-stack comparison, the motion and legibility showcase, strict mode, illustration costs. |
| [`force-old/`](force-old/) | v1 — Acknowledgement Force 0.3.0. Kept because its failure is the design input. |

Companion docs: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) ·
[docs/DESIGN.md](docs/DESIGN.md) · [docs/COPY.md](docs/COPY.md) ·
[docs/PLATFORM.md](docs/PLATFORM.md) · [docs/DATA-MODEL.md](docs/DATA-MODEL.md) ·
[plans/ROADMAP.md](plans/ROADMAP.md) · [CHANGELOG.md](CHANGELOG.md)

## The app before this one died, and the log says exactly when

v1 was a gate on a Mac: read your contract, tick the box, name the one thing that mattered
today. It ran for seven weeks. Here is the real usage record, pulled from
`~/Library/Application Support/Force/acknowledgements.log` rather than from memory:

```
2026-05-21 → 2026-07-10   145 acknowledgements across 38 days
Week 1–2:   6–9 opens/day, 14/14 days          ← engaged
Jun 4–5:    first 2-day gap                     ← inflection point
Jun 6–26:   1–3 opens/day, gaps widening
Jun 26 → Jul 4:  8-day gap
Jul 10:     final acknowledgement
Aug 4:      25 days dead; app no longer installed anywhere
```

Two facts in that log do all the work (D1).

**It died at week seven, right after the first two-day gap.** The research already sitting
in the old repo says weeks one through five predict long-term adherence and names *never
miss twice* as the core mechanic. Jun 4–5 is where the curve broke. The research was
right; v1 did not implement it.

**Those 145 acknowledgements contain zero bits of information.** The log stores a timestamp
and nothing else. The app could not tell the best day of those seven weeks from the worst.
Compliance and non-compliance looked identical to it.

So the diagnosis is not "wrong platform" or "needs more discipline". It is **no feedback
loop**. The gate said the same thing on day 1 as on day 40 regardless of anything you had
done, and you habituate fast to a stimulus that carries no information. Habituation was the
symptom. Two secondary causes are real and cheap to fix: the contract was 160 lines with 9
rules, 8 daily non-negotiables and 6 priority areas — too large to hold in your head — and
none of it was ever emotionally owned. It became a reflex: scroll, tick, close.

There was also a straightforward bug. In two of its modes the gate depended on a
process-scoped `Bool`, so once you acknowledged, the gate never re-locked for as long as
that process lived — through sleep, wake, and days passing. A `Bool` has no clock. v2 makes
that a law rather than a fix: **gate state is always derived from persisted wall-clock
facts, never from process memory** (D8).

## How the loop works

### One claim, and it has to be able to be false

The atomic unit is not a habit. It is an **identity claim** — a sentence about who you are,
which today either supports or damages (D2). A good claim names its own evidence and can be
broken.

| | Claim | Why |
|---|---|---|
| No | *"I am someone who takes care of their body."* | Unfalsifiable. Any day absorbs it. A claim that can't be broken can't be kept. |
| No | *"I train four times a week."* | A habit in an identity costume. Snaps the first week you get sick. |
| Yes | *"I am someone who trains when I don't feel like it."* | Today either contained a moment where you didn't want to and went anyway, or it didn't. You know which. So does the app. |

You get **one primary claim and up to two background claims**, pursued for 28 days (D4).
That number is an output, not a rule. Force only covers the parts of life that nothing else
enforces:

| Domain | Enforcer if you go quiet |
|---|---|
| Studies | deadlines, grades, university |
| Contract work / business | clients, invoices, people waiting |
| Committees, clubs | meetings, other humans, a calendar |
| **Health** | **nobody** |
| **Job hunt** | **nobody, ever** |
| **Relationships** | **nobody — and it decays silently** |

Strip out everything with an external enforcer and roughly three things are left. Burying
the two that need defending inside six that don't is how they got lost in v1.

The primary is chosen by **what your mind is most willing to quietly drop**, not by what
matters most.

**Wording is free to change; the pursuit is not.** Rewriting the sentence until it is true
*is* the work — you will rewrite a claim five times before it fits. But the 28 days are
locked, and leaving early costs one spoken receipt: what the evidence showed, and why you
are stopping. It goes into your record permanently. Not as punishment — a log of what you
have abandoned and why is the most useful document about you that could exist.

### Evidence is produced, not asserted

The checkbox is disqualified. It is literally v1, and a box can be ticked while your mind is
elsewhere. Instead (D3):

- **The floor is spoken testimony.** One sentence in your own words naming what actually
  happened. Voice first, typing available when you're in public. Speaking it puts it back
  through your own ears, and that is the mechanism — not the input method.
- **Numbers come from the source.** Force should never ask whether you trained. Tempo, the
  workout app, already knows. Force opens with the consequence instead of the question.
- **The AI challenges; it never grades.** An AI that scores you becomes an opponent you game
  or resent, and you can lie to it for free. It gets one push:
  *"That's the fourth day running you've written 'went gym' and nothing else. That's not a
  record, that's a signature."*

### Two beats a day, exactly one of them a gate

**Morning, about ten seconds, no lock.** One line: your claim, and the single thing today
that would count as evidence for it. One tap to adjust. A briefing, not a trial. It also
makes the evening measurable, since "did I do what I said" requires that you said
something.

**Evening, sixty to ninety seconds. This is the wall.** Your claim, what you committed to
this morning, and you speak what actually happened. The numbers are already filled in. The
day settles.

Three rules hold this together (D5):

1. **One gate per day, exactly one.** v1 ran six to nine gates a day in week one. That is
   the direct cause of "I scrolled through without reading it." Scarcity is the only thing
   that makes a gate mean anything.
2. **"I didn't" is a complete, valid, closeable answer.** If the only exit is success, you
   will either lie or stop opening the app, and v1 shows which one you pick.
3. **The evening beat fires when you close the day, not at a clock time.** Some nights end
   at 1am. The logical day runs to a configurable boundary — **4am by default, not
   midnight** — so a 12:30am entry belongs to the day it came from.

Most nights the gate is one question, you speak, it closes, about thirty seconds. It opens
into a real conversation only when the data earns it (D6): the day settled as broken, the
testimony was vague, the workout data contradicts you, it's your second consecutive miss, or
the 28-day review is due. Every one of those is a moment where a human who cared about you
would say something. On every other night it shuts up — which is exactly what buys it the
right not to, on those five.

### Three ways a day can end

| State | Meaning |
|---|---|
| `kept` | you did it, and there's evidence |
| `broken` | you engaged and failed, spoken aloud |
| `unsettled` | you didn't answer |

There is no close button. There is a button that says **Not tonight**, because the exit must
be a statement rather than a dismissal (D7). One tap, no confirmation dialog, no guilt copy.
The moment quitting the night gets expensive, you quit the app instead.

`unsettled` is not `broken`. Broken means you showed up and lost. Unsettled means you didn't
show up, and it is the *more* diagnostic signal — a run of unsettled days is the app dying,
and that is the one thing v1 could never see about itself. It just stopped, and nobody
noticed for 25 days until somebody read a log file.

### What happens when you miss

| Event | Response |
|---|---|
| First miss (`broken` or `unsettled`) | **Nothing. Genuinely nothing.** No colour change, no "streak broken", no gentle reminder. Silence. |
| Second consecutive | The gate opens into conversation, and asks about the *pattern*, not the day. |
| Third consecutive | **The claim goes on trial.** *"Three in a row. Is this claim wrong, or is this week wrong?"* Miscalibrated, and you rewrite the wording. Hostile week, and the app backs off instead of pushing. |

If one bad day produces any visible reaction at all, you learn the app is watching for
failure — and the cheapest way to avoid a reaction is to stop opening it. That is precisely
how v1 ended (D12).

## What Force will not do

- **It will not lock your machine.** v1's `App.swift:30` carries the comment
  `// the "no escape" rule`. It produced exactly one outcome: total escape. A gate blocking
  a machine you earn money on is a hostage situation with your income attached. The gate
  owns its own window and nothing else (D7).
- **It will not tell you what to do at 2pm.** You have a calendar and a to-do list. Any app
  that tries to own your task list becomes a task list. Force answers one question: *which
  part of me am I defending this month, and is that still the right one.*
- **It will not let you settle the day in a browser.** The web surface reads the record —
  progress, statistics, wording edits, account. The evening gate lives only in the native
  app, because a gate you can clear in a background tab while half-watching something else
  is reflex-ticking with extra steps (D14).
- **It has no character and no celebrity mentor.** A persona is fun for two weeks, then it's
  a bit, and the day it stops being funny you stop opening the app. Worse, it dilutes the
  only real advantage: the most powerful thing Force can say is *"third tired session this
  week, and you closed this app after 1am on all three of those nights."* Nobody else on
  earth can say that. Dressing it in a podcast voice makes it sound like content, and you
  already ignore content. **Character comes from what it knows, not how it talks** (D11).
  Note what that sentence does and does not claim: Force has no sleep data and does not ask
  for it, so it only says what its own timestamps prove (D24).
- **It will not say anything generic.** The AI may only say things that would be impossible
  without your record. *"That's okay, just make sure to..."* is the canned mantra again, now
  with audio. **Silence is a valid output.**

## Platforms

Built in **Flutter** (D13), chosen by a measured spike that overturned the original
recommendation. Same screen, three stacks, same Mac, release builds — full detail in
[`spikes/RESULTS.md`](spikes/RESULTS.md):

| | SwiftUI | Tauri v2 + React | Flutter |
|---|---|---|---|
| Cold start to first paint (median of 5) | 212 ms | 458 ms | **208 ms** |
| spread across runs | 174–318 ms | 418–470 ms | **196–223 ms** |
| Idle memory | 103–107 MB | 111 MB | **99 MB** |
| Bundle | **1.7 MB** | 10 MB | 36 MB |
| Lines for the same screen | **799** | 881 | 944 |

Flutter matched native on launch, beat it on consistency, used the least memory, and
rendered the serif display type indistinguishably — which was the main argument against it
going in. Tauri was 2.2× slower to first paint, and for an app whose whole job is to appear
at 11pm and be faced, that is the most relevant number on the table. Android decided it:
Flutter built an APK first try with zero source changes, Tauri hit three toolchain blockers
on a screen with one window API call and never produced one.

What that costs, stated honestly: the design system now lives in two places, Dart for the
app and React for the web. That was Tauri's best argument and it was real. It is a tax paid
once at the token level, against a platform-divergence tax charged forever.

| Platform | Status | Notes |
|---|---|---|
| **macOS** | first target, and it ships alone | Downloaded from this repository's Releases page, signed with Developer ID and notarised. **Not the Mac App Store** — strict mode needs the sandbox off (D21). Nothing touches another platform until 28 consecutive days have been run on macOS (D22). |
| **Windows** | second | Built in CI; cannot be built or felt from the development Mac. |
| **Android** | third | The daily-driver phone. Sideloadable APK; Play Store not decided. |
| **iOS** | companion only | The loop works. Strict mode does not, and never will. |
| **Web** | read the record | Landing page, progress, statistics, wording edits, account. Never the gate. |

### iOS, straight

**An iOS app cannot force itself to the foreground. There is no API, there is no
entitlement, and there is no workaround.** This was tested, not assumed
([`spikes/strict-mode/FINDINGS.md`](spikes/strict-mode/FINDINGS.md)): opening your own URL
scheme returns false, backgrounded timers never run because the process is suspended, and
`FamilyControls` fails at runtime with an XPC error because its entitlement is granted by
Apple on application. Even if it were granted, the shield UI is a SwiftUI app extension, so
Flutter could never render one.

iOS gets a local notification and, potentially, a Live Activity. It can tell you the day
hasn't settled. It can never make you settle it. iOS is a companion, not a gate surface.

### Strict mode, and what each OS actually permits

Strict mode is the opt-in tier where the gate can appear on its own rather than waiting for
you. It is **never auto-offered** — suggesting it right after you fail reads as punishment
and you'll feel handled. It lives in settings, is mentioned once at onboarding, and is never
brought up again (D12). Everything in this table was executed against a real OS, with
screenshots and an event log (D18):

| Capability | macOS | Android | iOS |
|---|---|---|---|
| Raise itself unprompted | Yes, ~5 lines of Swift (fails while the screen is locked) | Yes, via an overlay | **No API** |
| Cover a full-screen app | Yes — only from a separate `NSPanel` | Yes, except over Settings | No |
| Refuse to close or quit | Possible, but **`kill -TERM` always wins** — and we don't take it | n/a | No |
| Launch itself on a schedule | Yes, via LaunchAgent — **requires the sandbox off** | Yes, boot receiver + foreground service | No |

Two honest caveats. On macOS, Force Quit, Activity Monitor and `kill -9` can never be
blocked; that is the OS boundary, and it is exactly the escape hatch the design wants. On
Android, any foreground app that calls `setHideOverlayWindows(true)` makes the gate
disappear — the Settings app does this — so *"you can't get past it"* would be a lie, and it
will not be claimed.

## Install

Not published yet. Once it is, this section is the whole story: download, drag, open.

### macOS

1. Download the latest `.dmg` from the Releases page of this repository.
2. Drag **Force** into `/Applications`.
3. Open it. macOS shows one confirmation the first time — *"Force is an app downloaded from
   the Internet. Are you sure you want to open it?"* — and you click **Open**. That's it.

**Force is distributed here, not through the Mac App Store** (D21). Releases are signed with
a Developer ID certificate and notarized by Apple, so a downloaded `.dmg` opens with one
confirmation and nothing else.

The reason it is not on the App Store is exact rather than ideological. Strict mode needs a
LaunchAgent so the gate can appear when the app isn't running, a LaunchAgent needs
`com.apple.security.app-sandbox = false`, and an unsandboxed app cannot be sold in the App
Store. Verified in the spike: with the sandbox on, `launchctl bootstrap` fails with an I/O
error because the plist gets redirected into the app's container. Interruption was the
original point of Force, so it wins over store presence, and the cost is ours to carry —
Developer ID signing, notarization, and an updater we host.

> **Ad-hoc signed builds warn.** Anything you build from source on another machine is not
> notarized, so if you move the `.app` to a different Mac, Gatekeeper may refuse it. Building
> on the machine you'll run it on avoids that entirely.

**If Gatekeeper blocks it outright**, right-click the app and choose **Open**, or clear the
quarantine flag by hand:

```sh
xattr -dr com.apple.quarantine "/Applications/Force.app"
```

Do that only for a build you produced yourself or a release whose signature you trust.

### Windows

Download the installer from Releases and run it. Windows builds come out of CI, since they
cannot be built or verified from the development machine. Code signing on Windows is not
decided yet, so until it is, expect a SmartScreen warning on first run.

### Android

Download the `.apk` from Releases and install it. You will need to allow installs from this
source once. Strict mode additionally asks for the "display over other apps" permission,
which the app links you straight to; without it, the overlay is correctly refused and simply
does nothing.

Whether Force goes on the Play Store is undecided. `SYSTEM_ALERT_WINDOW`, `QUERY_ALL_PACKAGES`
and the `specialUse` foreground-service type all attract manual review, and none of that has
been tested.

## Build from source

You need the Flutter SDK. The spikes ran on **Flutter 3.44.8 / Dart 3.12.2**.

```sh
git clone <repo-url>
cd force
flutter pub get
```

| Target | Command | What it needs |
|---|---|---|
| macOS | `flutter build macos --release` | **Full Xcode, roughly 15 GB.** Command Line Tools alone are not enough for Flutter desktop — this bites people, since Tauri and plain SwiftUI both build fine without it. |
| Windows | `flutter build windows --release` | Visual Studio with the C++ desktop workload. |
| Android | `flutter build apk --release` | Android SDK, JDK and NDK, roughly 5 GB. |

On Android, point `JAVA_HOME` at the JDK bundled with Android Studio:

```sh
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
```

Note that **strict mode is entirely platform code** — about 155 lines of Swift on macOS and
about 165 lines of Kotlin plus 35 of XML on Android. Not one line of it can be written in
Dart. Dart owns the pixels inside the gate; when the gate may appear, whether it stays alive,
and how it survives a reboot are all native. That is what native would have cost anyway;
they are AppKit and Android framework calls, not Flutter workarounds.

### Running the spikes today

Since the app itself doesn't exist yet, the only runnable code here is in `spikes/`. Each
one has its own build steps; the strict-mode harness in particular exposes a loopback
control port so every result is a recorded command and response rather than a claim. See
[`spikes/strict-mode/FINDINGS.md`](spikes/strict-mode/FINDINGS.md), section 5.

## Design principles

Six rules. Violate them and we rebuild v1.

1. **Scarcity over ubiquity.** One gate a day. More surfaces multiply whatever the loop is
   worth; they do not create it.
2. **Unpredictability defeats habituation.** If the gate is identical every night, you will
   learn to sleep through it. You should not be able to predict what tonight costs you.
3. **The AI may only say things that are impossible without your record.** Silence is a
   valid output.
4. **Failure is a first-class, closeable state.** The bad night is the product.
5. **The user authors; the AI proposes.** It offers candidate sentences built from phrases
   you actually said, shown next to the quote they came from, and you edit until it sounds
   like you. If the AI can't cite you, it doesn't get to propose it. If the machine wrote
   it, you didn't author it.
6. **Never miss twice.** One miss is noise and carries zero guilt. Two consecutive is when
   the app changes.

One more, which came out of how v1 died and now governs every visual decision: **what
repeats must be abstract or absent; what is rare can be vivid** (D16). And one hard
requirement that isn't a preference — Force is designed to be opened on your worst nights,
when you are tired and not sharp, so poor legibility is not an edge case here, it is the
core case. Minimum 15px for any readable text, 17px for body, 4.5:1 contrast, OS text
scaling respected and never clamped (D17).

For the reasoning behind all of it, read [`FORCE-V2.md`](FORCE-V2.md). For how it is put
together, [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and
[docs/DESIGN.md](docs/DESIGN.md).

## Still open

These are undecided, not omitted. None of them should be guessed at from this README.

- **Whether there is a fourth verdict.** D5 says a day settles as *kept / partial / broken*; D7
  and two other places say *kept / broken / unsettled*. This page, and every other doc except
  [docs/DATA-MODEL.md](docs/DATA-MODEL.md), writes the three-state version as settled. `partial`
  was never explicitly retracted and needs a call before the enum is built.
- **Speech-to-text: on-device or cloud.** Whatever it is, it must degrade to *something*
  offline. The gate never depends on a network call.
- **Minimum OS versions.** The spikes ran on macOS 26.5.2, Android 15 (API 35, emulator
  only) and iOS 26 (simulator). No floor has been set.
- **Windows code signing**, and Play Store submission. D21 settles macOS distribution and
  nothing else; the Play Store question is untouched by it.
- **The image model's exact ID.** D24 settles the *provider* — stay with what produced the
  approved samples, one provider and one pipeline. The model ID gets confirmed at wiring time,
  because Imagen 4 shut down 2026-08-17 and that is a different model from the Gemini image
  model the samples came from. Pricing across the field is in
  [`spikes/illustration/COSTS.md`](spikes/illustration/COSTS.md), gathered 2026-08-04 and going
  stale fast.
- **License.** v1 was MIT. v2's has not been chosen.

Four things that used to sit on this list are now decided, and are described above rather than
here: the **palette** (D19, Ash), the **motion language** (D20, four locked moments),
**distribution** (D21, GitHub + Developer ID, not the App Store), and **first-release scope** —
D22 puts the Counsel, the on-demand conversational surface for when you're stuck, in v1, with
the single ordering rule that macOS ships first and alone for 28 consecutive days. `FORCE-V2.md` §4 also closes rewrite-versus-evolve: it is a full rewrite,
and `force-old/` is reference only.

Known gaps in what has been tested, stated because a spike that overstates itself is worse
than no spike: real system-sleep wake events on macOS need `sudo` and were not triggered;
Android was emulator-only, so OEM battery-killer behaviour — the biggest real-world risk to
the always-running service — is unverified; sustained animation under load was built in all
three spikes but never profiled for dropped frames.

## History

`force-old/` is Acknowledgement Force 0.3.0 — Swift, SwiftUI, macOS-only, MIT, with a
Next.js and Supabase web editor and an unfinished Android app-blocking track. It is kept for
three reasons. Its usage log is the evidence that produced v2. Its 160-line contract is real
writing by the person who will use v2, and becomes input to the first onboarding session
rather than something to start over from. And its Android `AccessibilityService` work is
genuinely the most interesting engineering in the old repo; it returns once strict mode is
real.

The stack spikes deliberately reused v1's monochrome theme and its Fraunces and Inter fonts,
so the comparison measured the stack rather than anyone's taste. None of that styling
survives into the product.
