# Architecture

How Force v2 is put together, and which decision each piece answers to.

Every structural claim here traces back to [`../FORCE-V2.md`](../FORCE-V2.md) (D1–D24) or to a
spike that measured something. Where nothing has been decided, it says so under **Open** rather
than guessing. Directory names and package layouts are the one exception — FORCE-V2.md names no
folders, so the shapes below are labelled as proposals that follow from the decisions.

This is the functionality-phase architecture (D15). Palette, motion and identity are a separate
pass and live in [`DESIGN.md`](DESIGN.md).

---

## The shape

```
     NATIVE (Flutter)                          VERCEL                       WEB (React)
 ┌──────────────────────┐              ┌──────────────────────┐        ┌──────────────────┐
 │  main engine         │              │  API · auth · sync   │        │  landing         │
 │   morning beat       │◄────sync────►│  model calls         │◄──────►│  the record      │
 │   the record         │              │  image generation    │        │  statistics      │
 │   onboarding         │              │  → Vercel Blob       │        │  wording edits   │
 │   settings           │              └──────────────────────┘        │  account/billing │
 ├──────────────────────┤                        ▲                     └──────────────────┘
 │  gate engine         │                        │                          reads only
 │   the evening gate   │                        │                       never settles a day
 │   (2nd FlutterEngine)│                 model + TTS + STT
 └──────────┬───────────┘                    (best effort)
            │
 ┌──────────▼───────────┐
 │  platform code       │   Swift on macOS · Kotlin on Android
 │  lifecycle · window  │   the gate's existence, not its pixels
 │  overlay · schedule  │
 └──────────────────────┘
```

Two things to read off it immediately. The day settles on the left-hand side of that diagram and
nowhere else. And the arrow to Vercel is the only one that is allowed to fail.

---

## Surfaces

FORCE-V2.md §2 names two product surfaces. D14 draws a separate line about *where each one runs*.
Those are two different questions — what a surface is *for*, and which machine it runs on —
and merging them is how the gate ends up in a browser tab.

### The Loop — native only

Morning and evening. Rhythmic, automatic, low-effort. Claims and evidence (§2). Two beats a day,
exactly one of them a gate (D5): a ~10-second morning briefing with no lock, and a 60–90 second
evening beat that is the wall.

The Loop runs on the native app. All of it. The morning beat, the voice capture, and the gate.

### The Counsel — on demand, conversational

For when you're stuck: *"I have two things and I don't know which to defend this week."* The
Counsel is only worth anything because the Loop feeds it (§2). Any chatbot can debate two options.
Only Force can say *"you've claimed this for nineteen days and defended it four times."*

**In v1 scope (D22).** Open question 13 is closed: the Counsel ships. D22's reasoning is that
time is not the bottleneck, iteration quality is. It stays late in the order for a product
reason rather than a scope one — the Loop is what makes it unfakeable, so it cannot come first.
Architecture-wise it needs the same read path as the web dashboard plus a model call, and
nothing the Loop does not already require.

### The web dashboard — reads the record, never settles a day (D14)

| Web (Vercel) | Native app |
|---|---|
| Landing page | **The evening gate — only ever here** |
| Progress, statistics, analysis | The morning beat |
| Reading the full record | Voice capture |
| *Some* claim edits — wording, never commitments | |
| Account & billing | |

**Why the gate can never live on the web.** If you can settle your day in a browser tab, the gate
loses scarcity, and you would settle days half-watching something else. That is reflex-ticking with
extra steps — v1's death reproduced faithfully in a new medium (D14). v1 died because 145
acknowledgements carried zero information and the act became scroll, tick, close. A browser tab is
the fastest possible route back to that.

This is not a policy we enforce with a feature flag. It is a shape: **the web API has no endpoint
that can write a day's verdict.** There is nothing to disable, because there is nothing to call.

**The write split D14 forces.** "Wording, never commitments" means the two are different
operations with different reach:

| Operation | Where it can happen | Why |
|---|---|---|
| Edit a claim's sentence | native **and** web | Rewording until it's true *is* the work; zero friction, any time (D4) |
| Settle a day (`kept` / `broken` / `unsettled`) | native only | D14 |
| Start a 28-day pursuit | native only | It is a commitment with a ritual (D9) |
| Retire a pursuit | native only | Exiting costs one **spoken** receipt (D4) — it needs a microphone |

The receipt rule does half the work on its own. You cannot retire a claim from a keyboard because
retiring requires you to say out loud what the evidence showed and why you're stopping.

---

## The Flutter app

Flutter was chosen by spike, against the initial recommendation (D13). The numbers that decided it,
in full in [`../spikes/RESULTS.md`](../spikes/RESULTS.md):

| | SwiftUI | Tauri v2 | Flutter |
|---|---|---|---|
| Cold start → first paint (median of 5) | 212 ms | 458 ms | **208 ms** |
| spread | 174–318 ms | 418–470 ms | **196–223 ms** |
| idle RSS | 103–107 MB | 111 MB | **99 MB** |
| Android build | n/a | 3 toolchain blockers, never produced an APK | **first try, zero source changes** |

Cold start is the number the user feels every night, and Flutter matched native on it with half the
variance. Android was the tiebreaker and it was not close.

### Two entrypoints, two engines

The app has two Dart entrypoints and they run in **separate FlutterEngine instances**:

| Entrypoint | Hosted by | Contains |
|---|---|---|
| `main` | the ordinary app window | morning beat, the record, onboarding, settings, the 28-day review |
| the gate entrypoint (`@pragma('vm:entry-point')`) | macOS: a borderless `NSPanel`. Android: a `WindowManager` overlay | the evening gate, and nothing else |

Why this exists is covered under [the second-engine pattern](#the-second-flutterengine-pattern)
below and in [`PLATFORM.md`](PLATFORM.md). The consequence that matters *here* is that a second
engine is a **second isolate**: the two UI trees share no Dart memory. Anything the gate needs must
come from persisted state or across a platform channel.

That is inconvenient exactly once and correct forever, because it is D8's law restated by the
runtime: **gate state is derived from persisted wall-clock facts, never from process memory.** The
architecture cannot cheat here even if someone wants to.

### Module boundaries

> **Proposed.** FORCE-V2.md names no modules. Each boundary below is the shape a locked decision
> forces; the names are not decided.

```
lib/
  core/        day-state derivation, claim and record models, the 28-day clock
  store/       local persistence — the device's source of truth
  sync/        Vercel client; may be offline for a week without breaking anything
  bridge/      platform channels: lifecycle, gate presentation, permissions
  voice/       capture, STT, TTS playback, and the offline path for both
  design/      tokens, type scale, components  (mirrored in React — D13's stated cost)
  app/         main entrypoint: morning, record, onboarding, settings
  gate/        gate entrypoint: the evening beat
```

What each boundary is answering:

- **`core` is pure and takes the clock as a parameter.** No I/O, no globals, no `DateTime.now()`
  buried in a branch. It answers one question — *given these persisted timestamps and this instant,
  what is the state of the logical day?* — and it answers it identically the hundredth time you ask
  (D8: recomputation is idempotent). The **logical day boundary defaults to 4am, not midnight**
  (D8), because a 12:30am evening beat belongs to the day it ended, and shifts are chaos.

  v1 got this layering right and still shipped the bug. `AcknowledgementGate.swift` was pure policy
  in a platform-neutral kit — and `AcknowledgementGate.swift:31` returned `sessionAcknowledged`, a
  process-scoped `Bool`. A `Bool` has no clock. Purity was never the missing thing; **the inputs
  were.** `core` may only be handed persisted facts.

- **`store` is the device's source of truth, and it is written to before anything else happens.**
  Local-first (§1b). The write that settles a day completes on the device; the network learns about
  it afterwards.

- **`sync` must be allowed to be down.** Cloud sync and restore is a hard constraint (§1b) — state
  lives on a server, not only on the device — but "the record survives a lost laptop" and "the gate
  needs the network" are different claims and only the first one is true here.

- **`bridge` is thin on purpose.** It carries events and commands, not logic. The
  [strict-mode spike](../spikes/strict-mode/FINDINGS.md) established that the platform layer owns
  *whether and when* the gate exists; Dart owns what it looks like. Putting policy in `bridge`
  would mean writing it twice, in two languages, and drifting.

- **`design` is duplicated in React, knowingly.** This is the tax D13 accepted: the design system
  lives in Dart for the app and React for the landing page and dashboard. It was Tauri's best
  argument and it was real. It is paid once, at the token level, against a platform-divergence tax
  charged forever plus a 2.2× slower launch.

### Legibility is structural, not cosmetic (D17)

Minimums, not preferences: 15px for any readable text, 17px for body and conversational text, 14px
plus real letter-spacing for uppercase tracked labels, 4.5:1 contrast, nothing below 0.7 opacity,
and `MediaQuery.textScaler` respected rather than clamped.

The reason binds harder here than in most apps. Force is *designed* to be opened on the user's
worst nights, tired and not sharp. Poor legibility is not an edge case for this product; it is the
core case. **If a composition depends on tiny type, the composition changes, not the type.**

---

## The platform-channel boundary

### What must be native

The strict-mode spike executed every one of these rather than reading about them; 25 screenshots and
a persistent event log are in [`../spikes/strict-mode/FINDINGS.md`](../spikes/strict-mode/FINDINGS.md).

**Flutter changes nothing about the walls or the escapes.** Everything possible natively is still
possible. What it costs is that **100% of this layer is platform code — zero lines are possible in
Dart** (D18).

| Concern | macOS | Android | Dart's share |
|---|---|---|---|
| Wake / sleep / day-change / time-change events (D8) | 9 `NSWorkspace` + `NSNotificationCenter` observers, ~35 lines Swift | — | receives them |
| Showing the gate over another app | `NSPanel` at `.screenSaver` level, ~35 lines | `TYPE_APPLICATION_OVERLAY` window, ~110 lines Kotlin | draws inside it |
| Staying alive to show it | LaunchAgent, ~55 lines | foreground service + `BOOT_COMPLETED` receiver, ~14 lines | none |
| Permission checks and grant deep-links | — | ~45 lines Kotlin | ~15 lines |
| The gate's pixels | 0 | 0 | **all of it** |

**The measured split on Android: ~165 lines Kotlin + ~35 lines XML against ~50 lines Dart.** On
macOS it is ~155 Swift against ~45 Dart. Dart owns the widget tree inside the overlay and nothing
else. When the gate appears, whether it may appear, staying alive to make it appear, coming back
after a reboot — all Kotlin.

That is not a reason to leave Flutter. Those are AppKit and Android framework calls; native would
have cost the same. It *is* a reason not to expect a package to hand it to you.

**D8 is impossible in Dart, and this was proved rather than assumed.** `AppLifecycleState` — the
only lifecycle signal pure Dart gets — fired for activation changes and **never fired for screen
sleep or wake at all**. The native observers are mandatory.

### The second-FlutterEngine pattern

The gate is not the app's main window. It is a second window with its own engine and its own Dart
entrypoint, on both desktop and mobile.

**On macOS, this is the finding that looked like a wall and wasn't.** The remembered limitation —
*"my window can't get above a full-screen app"* — was the wrong window, not the OS. Six attempts to
fix `MainFlutterWindow` (`canJoinAllSpaces`, `fullScreenAuxiliary`, `stationary`, window levels 3
and 1000, `orderFrontRegardless`) all reported `isOnActiveSpace: false`. A hand-written AppKit app
with identical flags overlaid the same full-screen Space instantly. Flutter's storyboard-created
main window, belonging to a `.regular` app with a Dock tile and a menu bar, is never re-assignable
to another app's full-screen Space.

The shape that works, ~35 lines:

```swift
let panel = NSPanel(contentRect: NSScreen.main!.frame,
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered, defer: false)
panel.level = .screenSaver
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
let engine = FlutterEngine(name: "gate", project: nil, allowHeadlessExecution: true)
engine.run(withEntrypoint: "gateMain")            // @pragma('vm:entry-point') in Dart
panel.contentViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
panel.orderFrontRegardless()
```

Result: `{onActiveSpace: true, isVisible: true, level: 1000, frontmost: Decoy}` — a full-bleed
Flutter gate covering another app's full-screen Space **without stealing focus and without switching
Spaces.** That hands D7's "insistent but always escapable" over for free. Visually total, input-wise
polite.

One catch to carry forward: because the panel is non-activating, keyboard focus stays with whatever
is underneath. D3 allows typing when you're in public, so the typing path must **also** activate —
a deliberate second step, never a side effect.

Android is the same pattern with different nouns: a `FlutterView` on a second engine running an
overlay entrypoint, added to `WindowManager`. One trap that cost the spike twenty minutes and is in
no documentation: **a `FlutterView` added with `MATCH_PARENT` never paints.** The window is created,
`dumpsys` lists it, the engine logs that Impeller started, and the screen shows nothing
(`FlutterRenderer: Width is zero. 0,0`). The fix is explicit pixels from
`wm.currentWindowMetrics.bounds` plus a plain `FrameLayout` wrapper.

**Why this is architecture and not a workaround.** The gate becomes a distinct thing you *show*
rather than a mode the app window *enters*. It can be shown when the main engine was never started.
It cannot read the main app's memory. Both properties are what D5 and D8 wanted anyway.

Per-platform detail, including what iOS cannot do at all, is in [`PLATFORM.md`](PLATFORM.md).

---

## The Vercel backend

Hosting is Vercel — a hard constraint from §1b. The backend's job list, from FORCE-V2.md §5b:

- the **API**
- **auth**
- the **sync endpoint** (cloud sync and restore is a hard constraint; state lives on a server, not
  only on the device)
- **model calls** — every LLM call goes through here, so no provider key ever ships in a client
- **image generation**, writing to Vercel Blob
- the **web dashboard**
- the **landing page**

Fluid Compute makes the runtime a non-issue: Hobby gets a 300s max duration, not 10s, and I/O wait
does not count toward billed Active CPU time. A 20-second image call is fine on the free plan.

### And explicitly not the gate

The backend cannot settle a day and has no endpoint that would let it (D14). It also cannot be in
the gate's critical path at all — that is §1b's tension, resolved in the next section. The gate's
correctness does not depend on any server being reachable, and the *record's* durability does not
depend on the device surviving. Those are two different guarantees and each is handled on its own
side.

**Open:** the database and auth provider. v1 talked directly to Supabase (GoTrue for auth,
PostgREST for a single `contents` row, row-level security scoping every query). FORCE-V2.md §4
closes Q15 — it is a **full rewrite and `force-old/` is reference only**, so nothing carries
forward as code — but that settles the code question, not the vendor one. §5b's default is
"Supabase again — v1's schema already worked," which is a default, not a decision. The record's
shape is in [`DATA-MODEL.md`](DATA-MODEL.md); where it is stored is not decided.

---

## The latency pipeline

This is the resolution of the tension flagged in §1b:

> Speed vs. LLM. If a model call sits in the critical path of the nightly gate, the gate is only
> ever as fast as the network. **Any design where you wait on a spinner before you can speak is
> disqualified.**

The trick is that the user hands you thirty seconds of free time and you spend it (D11): *you speak
for ~30s, and that's 30s of headroom — draft and synthesise while the user is still talking, ready
the instant they stop.*

```
t=0     press and hold
        │  the gate is already on screen. No fetch happened to get here.
        │  which shape tonight takes (one prompt / conversation) was decided
        │  locally, from the record.
        │
0–30s   speaking
        │  partial transcript streams out
        │  ──► backend starts DRAFTING the reply on the partial
        │  ──► TTS starts SYNTHESISING the first sentence
        │      both happen behind the user's own voice. Neither is visible.
        │
t=30s   release
        │  verdict appears instantly — kept / broken / unsettled.
        │  no network was consulted to draw it.
        │
t=30s+  tap the verdict
        │  ► written locally. THE DAY IS NOW SETTLED.
        │  ► the settle animation runs.
        │  ► the reply plays if it arrived. If it didn't, the day is still settled
        │    and nothing is waiting on it.
        │
later   sync pushes when there is a network. Whenever that is.
```

Three rules fall out, and they are the ones to test against every future feature:

1. **The write that settles the day is local and synchronous.** Model output streams in *after* the
   day is already settled (§1b). It is commentary on a closed record, never a gate on closing it.
2. **The day settles with or without the network.** This is stated twice in FORCE-V2.md — once in
   §1b as the likely shape, once in D11 as a rule: *the gate never depends on a network call.*
3. **Nothing the user must wait for is drawn from a fetch.** The claim, this morning's commitment,
   the record strip, the verdict buttons and *Not tonight* are all local reads.

**One consequence lands on the STT choice.** Drafting during the speech means you need text
*during* the speech.
Whatever speech-to-text is chosen has to emit partial results as the user talks, not just a final
transcript when they stop. That constrains the STT decision below; it does not make it.

**Which shape the gate takes is also decided locally.** D6 opens the gate into a real conversation
on five triggers: the day settled `broken`, the testimony was vague, Tempo contradicts you, it's a
second consecutive miss, or the 28-day review is due. Four of those are readable straight off the
local record. *Vague* is the one that isn't — see Open.

### Speech-to-text — undecided

**Not decided.** FORCE-V2.md §5b lists it as an open item: *"Decide STT: on-device vs cloud. Must
degrade to something offline (D11)."*

What is decided is the constraint, and it is a hard one. Voice is the floor of evidence (D3) — one
sentence in your own words, spoken, because speaking it aloud puts it back through your own ears.
If STT is unavailable the day must still settle. So whatever gets chosen must fall back to
*something* that works with no network. The gate cannot be the place where a transcription service
outage costs you a day.

Options are not narrowed. The choice interacts with the partial-results requirement above, with the
offline requirement, and with the illustration/model budget.

### Text-to-speech — ElevenLabs, pipelined, with a mandatory fallback (D11)

There is no persona and no celebrity mentor. You choose from four voices selected for **stance**
rather than demographics — warm, flat, dry, hard — with gender and accent falling out rather than
driving. Character comes from what the app knows, not how it talks (D11), which means nothing in
this section is a personality feature. It is a pipeline with one job: have audio ready the
instant the user stops speaking. What that audio *says* is [`COPY.md`](COPY.md)'s problem.

Three architectural requirements, all from D11:

- **Pipelined, not sequential.** Naively ElevenLabs is two network hops before you hear anything.
  Started while the user is still speaking, it is ready the instant they stop.
- **On-device fallback is mandatory.** Offline or API down, the day still settles and something
  still gets said.
- **The voice is always interruptible.** One tap kills it mid-sentence. A voice you can't stop
  becomes a voice you dread, and dread is how apps get deleted at 1am.

Interruptibility is an audio-session and playback-control concern, which means it lives partly in
the platform layer on both OSes — a Dart-side `stop()` that has to wait for a buffer to drain is
not a stop.

**Parked, and it scopes where the voice is allowed to exist: FORCE-V2.md §5 lists *"voice output
on the evening beat only — voice in the morning is a podcast you'll mute,"* subject to Principle
3.** That is a parked idea rather than a decision, and no other document in this set carries it,
so it is recorded here to keep it from being lost. If it holds, TTS is wired to one surface and
the ~10-second morning briefing (D5) stays silent, which also means the pipelining above only
ever has to serve the gate. Nothing should be built as though it were settled.

---

## Illustration generation

One image per claim, generated once at commit and regenerated every 28 days from the user's own
sentence and yap (D16). This is the "visualise it" mechanism from the opening brief. Because it is
rare and always changing, it cannot become wallpaper.

The style is **engraving line art, knocked out to transparency and recoloured** — chosen from four
generated directions. The subject can be knocked out and recomposited onto any ground, so it
inherits the palette instead of dictating one. Proven, not assumed:
`../spikes/illustration/proof-recolour.png` shows the same three engravings on dark, paper and
deep-teal grounds. The knockout uses luminance as alpha, so cross-hatching keeps its anti-aliased
edges rather than collapsing into jagged 1-bit lines.

### The path

```
commit a claim  (native — it's a commitment, so it happens where commitments happen)
   │
   ▼
Vercel function  (Fluid Compute — 300s available on Hobby, so a 20s call is comfortable)
   │  1. model turns the user's own sentence + yap into an engraving prompt
   │  2. image provider generates
   │  3. knock out to alpha if the provider didn't do it natively
   │  4. stream the result into Vercel Blob
   ▼
return the blob URL — never the bytes
   │
   ▼
client fetches once, caches forever, recolours onto the current ground
```

**Why it streams to Blob instead of returning inline: Vercel's request/response body cap is 4.5 MB.**
A 1024px PNG can clear that on its own, and the failure mode is an opaque 500 rather than a slow
response. The provider's URL goes straight into Blob storage and the function returns a link. These
images are generated roughly 13 times per user per year and then never change, so they belong on a
CDN with a long max-age.

**The prompting rule, learned the hard way.** The prompt must explicitly forbid *paper texture,
vignette, border, frame and drop shadow*, or the image knocks out as a visible rectangle. The
`dir3-engraving` tile in the proof sheet is exactly this failure, preserved so nobody repeats it.

**Where illustration goes, and where it must never go.** Per-claim image, the record, reviews,
onboarding — the sit-down-and-read surfaces. **Never the evening gate.** That screen is the claim,
the voice, and what happened. Decoration there is the app patting you on the head at the moment it
should be taking you seriously.

The principle underneath: *what repeats must be abstract or absent; what is rare can be vivid.*
Straight out of how v1 died — repetition kills anything.

**This is the one model call the user is allowed to see.** It happens at onboarding and at the
28-day review, never at the gate, so a 5–20 second wait is a moment of anticipation rather than a
spinner in front of the wall.

**Provider: open.** [`../spikes/illustration/COSTS.md`](../spikes/illustration/COSTS.md) has live
pricing from 2026-08-04 and a recommendation, not a decision:

| Option | $/image | $/1000 users/yr | Status |
|---|---|---|---|
| Recraft V3 Vector | $0.08 | $1,040 | **Spike this first.** Ships a literal `Engraving` style and returns true SVG — no knockout step, recolour via `currentColor`, infinite scale. Risk: fine cross-hatching is the worst case for vector. Generate five, count paths, check file size. |
| Ideogram 3.0 Turbo `generate-transparent` | $0.04 | $520 | Primary pick if the vector route fails. Only provider with native-alpha *generation*; `style_code` is a persistent style ID. |
| FLUX.1 [schnell] via Together | $0.0027 | $39 | Cheap fallback. Apache-2.0, no style ID, DIY knockout. |

Two constraints that outlive the pricing. **DIY knockout is not the weak option** — black line art
on white thresholds more reliably than a segmentation model, which happily eats thin hatch lines.
And several models have published shutdown dates inside four months: `gpt-image-2` has no
transparency at all, `gpt-image-1-mini`/`1.5` (which do) shut down 2026-12-01, Imagen 4 shuts down
2026-08-17, and no Gemini/Nano-Banana model has an alpha channel. Re-verify before committing.

---

## What we are not building

**No task list.** Force does not answer *"what should I do at 2pm."* You have a calendar and a todo
list; any app that tries to own your task list becomes a task list (§2). Force answers *"which part
of me am I defending this month, and is that still the right one."* Choosing your primary claim
**is** the prioritisation act — everything below it is downstream, because you already know what to
do once you know who you're being.

**No calendar ownership.** The parked calendar integration is deliberately the small version: Force
reads the calendar and proposes a gap — *"you seem to be free at this time, do it then"* — and you
accept. Never a fixed clock time that reality then invalidates over and over. Force does not create
events, own a schedule, or become a second calendar.

**No second place to settle the day.** Not the web, not a widget, not a notification action, not a
CLI. One gate per day, exactly one (D5), and it exists on exactly one surface (D14). v1 ran 6–9
gates a day in week one and that is the direct cause of *"I scrolled through without reading."*
Scarcity is what makes a gate mean anything, and every additional way to close a day divides it.

Two more, since they shape code as much as copy:

**No AI that scores you.** The AI challenges, never grades (D3). A model that assigns a number
becomes an opponent you game or resent, and you can lie to it for free. There is no score field
anywhere in the record.

**No hard lock.** The OS will let us refuse to close and refuse to quit — both were tested and both
work — and we are not taking either. `windowShouldClose -> false` is the line in v1 that got the app
deleted. The panel is already visually total without it, and `kill -TERM` is the floor the OS
guarantees regardless (D7).

---

## Open

Genuinely undecided. Listed so nobody mistakes an absence for a choice.

| # | Question | Where it's from |
|---|---|---|
| 1 | **Speech-to-text: on-device or cloud.** Must degrade to something offline, and must emit partial results if drafting is to happen during the speech. | §5b, D11 |
| 2 | **Database and auth provider.** v1 used Supabase directly. Q15 is closed — full rewrite, `force-old/` is reference only — but that settles the code, not the vendor. §5b's default is "Supabase again"; a default is not a decision. | §5b |
| 3 | **The image model's exact ID.** The *provider* is settled by D24 — stay with what produced the approved samples, one provider and one pipeline. Confirm the model ID at wiring time; Imagen 4 shut down 2026-08-17 and is a different model from the Gemini image model the samples came from. | D24 |
| 4 | **How Force reads Tempo.** D3 says Force should never ask whether you trained — it should already know. The mechanism is not decided. Note for honesty: **no Tempo data has ever been read**; only its tool list was visible in the design session. | D3, §5b |
| 5 | **What counts as "vague" testimony.** It is one of D6's five conversation triggers, and it is the only one not readable straight off the local record. If it needs a model, it needs a rule for what happens when the model isn't there. | D6 |
| 6 | **When the MCP server in `force-old/mcp` gets re-pointed** at the v2 data model. The deferred list says it happens "once the data model exists"; nothing schedules it. | §5b |

**Closed since the last revision, and deliberately not on this list:** distribution — **D21**
picks GitHub + Developer ID, signed and notarised, *not* the App Store, which is what D18 left
UNRESOLVED. The Counsel's place in v1 — **D22** puts it in scope. What survives from
`force-old` — §4 closes Q15 as a full rewrite with `force-old/` as reference only.

### Known traps to re-check before shipping

From FORCE-V2.md §5b, reproduced because they are architecture, not QA:

- Every lifecycle case in **D8** — wake from sleep, restart mid-day after the morning beat, the app
  sitting in the background for days, the 4am boundary. This is what broke v1 and **it broke
  silently.**
- **No process-scoped booleans anywhere in gate logic, ever.**
- Verify that **nothing visible happens on a first miss** (D12). Not a colour, not a word.
- `NSWorkspace.didWakeNotification` — real system sleep, the exact event that killed v1 — is the one
  observer the spike could **not** trigger (it needs `sudo`). The log at
  `../spikes/strict-mode/evidence/macos-events.log` is wired for a two-minute manual confirmation.
  Do it before building on it.
- **Android OEM battery-killers** (Xiaomi, Oppo, Vivo, Samsung) killing the foreground service.
  Untested — emulator only, no physical device was available — and the single biggest real-world
  risk to the gate ever appearing.

---

## See also

- [`../FORCE-V2.md`](../FORCE-V2.md) — the decision record. Source of truth for everything above.
- [`PLATFORM.md`](PLATFORM.md) — per-OS capability, the strict-mode walls, and what iOS cannot do.
- [`DATA-MODEL.md`](DATA-MODEL.md) — claims, days, the record, the 28-day clock.
- [`DESIGN.md`](DESIGN.md) — the product-phase design pass (D15).
- [`COPY.md`](COPY.md) — what the app is allowed to say, and when silence is the output.
- [`../plans/ROADMAP.md`](../plans/ROADMAP.md) — order of work.
- [`../spikes/RESULTS.md`](../spikes/RESULTS.md) · [`../spikes/strict-mode/FINDINGS.md`](../spikes/strict-mode/FINDINGS.md) · [`../spikes/illustration/COSTS.md`](../spikes/illustration/COSTS.md) — the measurements.
