# Force — Design System

This is the visual and motion language for Force v2. Every rule here traces back to a
decision in [`../FORCE-V2.md`](../FORCE-V2.md), or to something a spike actually measured.
Where a thing is genuinely undecided it sits under [Open](#open) and says so.

> ### Status: the palette and the motion language are decided
>
> **The Ash palette is D19. The four motion moments are D20. Both are RESOLVED in
> [`../FORCE-V2.md`](../FORCE-V2.md), and open question 14 is closed.** Build against them.
>
> What else binds: **D15** (design is the product phase; the spikes' throwaway styling does not
> survive), **D16** (illustration language, and never on the gate), **D17** (the legibility
> floors). D15 still governs *when* the polish pass happens; D19 and D20 govern *what* it lands
> on, so nothing in the token layer has to be a placeholder any more.
>
> What is still open is listed under [Open](#open) and nowhere else.

Two things to keep in mind while reading.

**Design is the product phase, not the experiment phase (D15).** The spikes deliberately
reused v1's monochrome theme so the stack comparison measured the *stack*. None of that
styling survives. What does survive is what the spikes learned: the type scale, the
legibility floor, the motion techniques, and the two colours that failed measurement.

**UI quality is a primary requirement, not a finish** (§1b). A correct app that feels cheap
is a dead app. This document is not a coat of paint applied at the end.

## The principle that generates everything else

> What repeats must be abstract or absent. What is rare can be vivid. (D16)

This falls straight out of how v1 died. The gate ran 6–9 times a day in week one and said
the same thing every time (D1, D5). Repetition kills anything — a mantra, an illustration, a
colour, a sound. So the surfaces you face every night are quiet to the point of being almost
nothing, and the surfaces you meet once a month are allowed to be beautiful.

Read the rest of this document through that lens. It explains why there is one chromatic
colour and it lives in one place; why the evening gate has no illustration on it at all; and
why the slowest, most deliberate animation in the product plays exactly once a day.

## Colour — the Ash palette (D19)

> **RESOLVED.** Ash is the palette, chosen from three live directions in the motion lab (Ash /
> Slate & Brass / Plate). The ten tokens below are D19's table, with the contrast measurements
> this document added. `FORCE-V2.md` open question 14 is closed.

### What it replaces, and why the replacement is not optional

v1 was strictly monochrome by design — zero chroma, the "Digital Curator" idea. The user's
instinct that "the colours don't portray Force" was literally correct: there were no
colours. `force-old/Sources/Force/Theme.swift:69` reads

```swift
var accent: UInt32 { ink }            // emphasis stays monochrome
var sale: UInt32 { ink }
var info: UInt32 { ink }
```

Three semantic roles, one value. That is a taste choice right up until v2 gives a day three
possible endings — `kept`, `broken`, `unsettled` (D7) — at which point it becomes a
functional failure. **A palette where `accent == ink` physically cannot render the record.**
This is the reason the palette had to change, stated in FORCE-V2 §4: not that the old one
was ugly, but that it could not say the thing.

And two of its colours failed measurement outright, found during the showcase spike's
accessibility pass (`../spikes/flutter-showcase/NOTES.md`):

| v1 colour | Measured on `base` #141515 | Verdict |
|---|---|---|
| `stone` #60646A | **3.07:1** against a 4.5:1 requirement | Retired as a text colour. Every place that used it for type now uses `mute`. |
| `outline` #3C3F40 | **1.72:1** | A 1.4 px `unsettled` ring in it is invisible on a dark phone at night. |

The second one is the worse of the two. D7 says `unsettled` is
the *more* diagnostic of the two failure states, because a run of unsettled days is the app
dying — "the one thing v1 could never see about itself. It just stopped, and nobody noticed
for 25 days until someone read a log file." v1 drew that exact state at 1.72:1. The signal
that the product was dying was rendered in a colour you could not see.

### The tokens

Ten tokens is the whole palette.

| Token | Hex | Role | On `bg` | On `bg2` |
|---|---|---|---|---|
| `bg` | `#101112` | The ground. Everything sits on this. | — | — |
| `bg2` | `#191B1D` | Raised surface — panels, the record detail, cards. | 1.09:1 | — |
| `ink` | `#EDEAE4` | Primary text. The claim, headings, anything that matters. | **15.7:1** | 14.4:1 |
| `ink2` | `#A8AEB3` | Secondary text. Prose the app says to you. | **8.4:1** | 7.7:1 |
| `ink3` | `#7E858B` | The quietest voice in the app. This is the floor. | **5.1:1** | 4.6:1 |
| `kept` | `#EDEAE4` | A day you kept. | 15.7:1 | 14.4:1 |
| `broken` | `#8A7566` | A day you engaged with and lost. | 4.3:1 | 4.0:1 |
| `unsettled` | `#5A6066` | A day you didn't answer. | **2.97:1** — under the 3:1 non-text floor, see [Open](#open) | 2.7:1 |
| `accent` | `#B4553A` | The emphasis mark. See below — it goes almost nowhere. | 3.9:1 | 3.5:1 |
| `rule` | `#2B2F33` | Hairlines and dividers. Never text, never a mark. | 1.4:1 | 1.3:1 |

Contrast ratios are WCAG 2.1 relative luminance in sRGB, computed against `bg` `#101112` and
`bg2` `#191B1D`. They are in the table because v1 shipped colours nobody had measured, and the
failures only surfaced when the showcase spike audited them seven months later.

### What the day-state colours are doing

`kept` is not a new colour. **`kept` and `ink` are the same value.** A day you kept is drawn
in the same off-white as the sentence you made about yourself. Evidence and claim are
literally the same colour; the mark is the sentence, in small.

`broken` `#8A7566` is warm — a clay brown. `unsettled` `#5A6066` is cool — a blue-grey. That
warm/cool split is doing D7's work. In a seven-day strip you need to tell "showed up and
lost" from "didn't show up" at a glance, in the dark, tired, without reading a legend. Two
greys at different lightness would not survive that; a warm one and a cool one do. Neither is
loud, because neither should be — D12 says the first miss produces *nothing*, "no colour
change, no 'streak broken', no gentle reminder." The palette has to be able to render a
broken day without the render itself being a reaction.

### Where the accent goes

**One place that holds still: the emphasis mark inside the claim, on the half of the sentence
that can actually be false.**

D2 is the whole reason this token exists. A good claim names its own evidence and can be
false. Take the locked example:

> I am someone who trains **when I don't feel like it**.

"I am someone who trains" cannot be false. Anyone can say it, any day absorbs it — it is the
unfalsifiable half, and D2 rejects claims made entirely of that. *"when I don't feel like
it"* is the half today either satisfied or didn't. You know which. So does the app.

The emphasis mark sits under that clause and nowhere else. It is the only place in Force
where colour carries meaning rather than decoration, so it gets the only chromatic token, and
that token appears nowhere else on a resting screen. Not on buttons, not on the record strip,
not on links, not on a "primary action". The moment accent appears twice on one screen it
stops pointing at anything.

There is exactly one other appearance, and it is transient: the innermost contour of the
hold-to-speak ring borrows `accent` for as long as your thumb is down (see
[The layered ring](#3-hold-to-speak--the-layered-ring)). Thirty seconds a night, gone when
you release. That is the complete list.

### Two measurements that constrain how these get used

D17 requires 4.5:1 for anything readable. Run the table against that and two things follow
without anyone deciding them:

**`broken` `#8A7566` is 4.3:1 — it is a mark fill, not a text colour.** This is the same
situation as v1's `stone`, which is instructive: the showcase's fix was that stone "survives
only as the *fill* of a `broken` mark, where the 3:1 non-text minimum applies and it passes."
Same rule applies here. Any text that *names* a broken day is written in `ink2` or `ink3`.
The difference from v1 is that this is known before shipping rather than discovered after.

**`accent` `#B4553A` is 3.9:1 — it is not a text colour either.** So in the emphasis
treatment the words themselves stay `ink` at 15.7:1, and the accent is carried by the rule
that draws beneath them. That is arithmetic on a locked rule, not a taste call.

One more, quieter: **`ink3` on `bg2` is 4.62:1.** It passes, with 0.12 of headroom. Do not
stack `ink3` on a raised surface and then also reduce its opacity, or dim it on selection —
there is nothing left to spend. The showcase hit this exact wall and its answer is the right
one: "the strip no longer dims at all on selection… selection is carried by a halo and by
size, which cost no contrast."

## Type

### Two faces, both already in the repo

| Face | Role | Licence |
|---|---|---|
| **Fraunces** | Display. The claim, titles, the closing line, large numerals. | SIL OFL 1.1 |
| **Inter** | UI. Prose, testimony, transcripts, labels, buttons, timers. | SIL OFL 1.1 |

Both carry forward from v1 (`force-old/Sources/Force/Resources/Fonts/`). Both were rendered
by all three spike builds and the RESULTS.md finding is explicit: "All three render Fraunces
cleanly and near-identically." The serif-quality worry that was the main argument against
Flutter's own renderer is dead (D13).

### The variable-font trap, and it fails silently

Fraunces and Inter are both variable fonts. **Flutter instantiates the fvar *default*
instance.** Fraunces' default is `wght 900 / opsz 9` — Black, at caption optical size. Ask
for a 30 px claim without saying otherwise and you get a heavy, tightly-fitted display face
rendered at three times its intended optical size.

Nothing warns you. There is no error, no log line, no missing-glyph box. The type just looks
wrong and you spend an afternoon adjusting spacing to fix a weight problem. The showcase
NOTES call it "the sharpest edge in the whole port."

CoreText did optical-size mapping for free on the SwiftUI build. Flutter does not, and there
is no automatic mapping to turn on.

**The rule: every `TextStyle` in Force pins `wght` and `opsz` explicitly. A style without
`fontVariations` is a bug, not a default.**

```dart
List<ui.FontVariation> v(double wght, double opsz) => [
  ui.FontVariation('wght', wght),
  ui.FontVariation('opsz', opsz),
];
```

In the showcase, `opsz` is pinned to the pixel size at every step — a 30 px claim is
`v(430, 30)`, 17 px body is `v(400, 17)`, a 14 px label is `v(500, 14)`. That is what
CoreText would have done on its own; in Flutter you write it out. Keep doing that.

### The scale

This is the showcase's scale after it was rebuilt against D17, and it is measured rather than
guessed. Carry the sizes forward; the colours come from the Ash table above, not from the
monochrome tokens the spike used.

| Role | Face | Size | Tracking | Notes |
|---|---|---|---|---|
| Claim | Fraunces | 30 / 26 | −0.4 / −0.3 | The one piece of type allowed to be big |
| Title | Fraunces | 24 | −0.2 | |
| Closing line | Fraunces | 28 | — | |
| Numeral | Fraunces | 46 | — | Tabular figures |
| Body / testimony / transcript | Inter | **17** | — | Anything conversational |
| Supporting prose | Inter | **16** | — | Still full sentences, so still read |
| Smallest readable text | Inter | **15** | — | The floor. It does not go lower. |
| Uppercase tracked label | Inter | **14** | **2.2** | The tracking is legibility work, not styling |
| Button / verdict | Inter | 15 | 2.4 | |
| Record strip day letters | Inter | **14** | — | Was 9 |

For scale, here is what the accessibility pass actually cost — the "before" column is what a
normal design instinct produces:

| Role | Before | Now |
|---|---|---|
| prose / testimony / transcript | 14 | **17** |
| supporting prose | 12.5 | **16** |
| smallest readable text | 9–11 | **15** |
| uppercase tracked labels | 10 (1.7 tracking) | **14 (2.2 tracking)** |
| record strip day letters | 9 | **14** |

Between a fifth and a half again bigger, depending on the row — 14→17 is 21%, 9→14 is 56%.
That is not a nudge, and it broke three compositions, which is the point of the next section.

## Legibility (D17)

These are minimums, not targets. Nothing negotiates them down.

| Rule | Minimum |
|---|---|
| Any readable text | **15 px** |
| Body / conversational text | **17 px** |
| Uppercase tracked labels | **14 px**, with real letter-spacing |
| Text contrast | **4.5:1** against its own background |
| Resting text opacity | **never below 0.7** |
| OS text-size setting | `MediaQuery.textScaler` **honoured, never clamped** |

### Why this binds harder here than in most apps

Force is *designed* to be opened on your worst nights. Not tolerated on them — designed for
them. D5 calls the evening beat "the wall"; D6's conversation triggers are all bad-news
events (broken day, vague testimony, Tempo contradicting you, second consecutive miss). D7's
whole architecture exists because the 1am night after a bad week is the moment that decides
whether the app survives.

So tired, late, not-sharp is not an edge case for this product. **It is the core case.** A
screen that is hard to read at 11pm is a screen that gets closed, and D7 already establishes
what closing leads to: "the alternative to a cheap exit is never compliance — it's
uninstallation."

D17 was raised for a plain reason: the user could not comfortably read label text in the
Flutter showcase, on a large screen, at close distance. If it fails there it has no chance on
a phone at midnight.

**The load-bearing consequence: if a composition depends on tiny type, the composition
changes, not the type.** This has teeth. In Flutter, overflow is an error rather than a
reflow, so every type-size change is a layout change — the showcase's accessibility pass
"broke three compositions that had to be re-laid-out rather than re-sized."

### Honouring textScaler properly

Honouring the OS setting while holding fixed space open just means clipping at 200%. Three
techniques from the showcase that actually work:

- **Reserved-height boxes** (the transcript slot, the record detail panel, the scene bottom
  margin) scale their reserves through a `scaled(context, px)` helper, so the reserve grows
  with the text it is reserving for.
- **The claim** is laid out word-by-word in a `Row`, which cannot wrap, so it sits in a
  `FittedBox(scaleDown)`. The choreography survives; the overflow does not.
- **Eyebrow rows** use `Wrap(alignment: spaceBetween)`, which pins both ends when they fit and
  drops the second element onto its own line when they do not.

One deliberate compromise, recorded so nobody re-litigates it: the scene-indicator ticks are
44×30 pt, not 44×44. Swiping is the primary navigation and the ticks are a secondary
shortcut; 44 pt of vertical there would have eaten the bottom margin.

One Flutter layout trap belongs in the design doc rather than the engineering one, because
what it produces looks like a design bug:
`Row(children: [Flexible(a), SizedBox(), Expanded(b)])` does **not** push `b` to the right
margin. Flex space is allocated before children are laid out, so a loose `Flexible` that
under-uses its half strands the leftover and `b` lands mid-screen. `Wrap(spaceBetween)` is
the right primitive.

## Motion (D20)

Motion is not decoration here. `FORCE-V2.md` §5b puts it in one line — *the settle animation is
the emotional centre of the gate* — and **D20 locks the four moments that matter**: Ink Bloom,
Italic + rule, the layered ring, and Fling.

> **RESOLVED.** The four moments below are D20. The house curves and the measured figures come
> from the showcase spike and are citable as measurements. One rule D20 states explicitly and
> this document follows: **the settle's spring constants are not restated here.** They live in
> [`../spikes/flutter-showcase/lib/scenes/settle_scene.dart`](../spikes/flutter-showcase/lib/scenes/settle_scene.dart)
> and that file is the source of truth, because a number copied into prose drifts the first time
> anyone tunes it.

### The house rules

From `../spikes/flutter-showcase/lib/theme.dart`, verbatim:

```dart
/// The house curve. Fast out of the gate, long tail. Nothing in Force
/// overshoots except the settle, which earns it.
static const ease     = Cubic(0.16, 1.0, 0.3, 1.0);   // expo-out-ish
static const easeSoft = Cubic(0.33, 0.0, 0.15, 1.0);
static const easeIn   = Cubic(0.55, 0.0, 1.0, 0.45);

static const fast = Duration(milliseconds: 220);
static const med  = Duration(milliseconds: 420);
static const slow = Duration(milliseconds: 760);
```

"Nothing overshoots except the settle, which earns it" is the whole motion philosophy in one
line. Overshoot is a bounce. A panel that bounces open teaches you that things in Force
bounce — and then the one mark a night that is supposed to land with weight lands like
everything else does.

### The four moments

| Moment | Name | Timing | Shape |
|---|---|---|---|
| Claim entrance | **Ink Bloom** | ~1.15 s | Whole sentence resolves out of blur at once. No stagger. |
| Emphasis | **Italic + rule** | rule ~0.72 s, begins ~0.9 s **after the bloom settles** | Accent rule draws left to right beneath the falsifiable clause. |
| Hold to speak | **The layered ring** | while the thumb is down | Three closed contours, back to front, each a solid body of its own colour. |
| Settle | **Fling** | a spring, not a duration — it ends when it stops | Real spring physics integrated per frame. Interruptible. No `Curve`. |

### 1. Claim entrance — Ink Bloom

The whole sentence resolves out of blur at once, over about 1.15 seconds. **No stagger.**

The showcase built the staggered version first — eleven words arriving one at a time, out of
blur, from below. It was beautiful and it is not what ships. Stagger makes you read at the
app's pace, one word at a time, and turns a statement into a reveal. But the claim is one
thought. *"I am someone who trains when I don't feel like it"* is a sentence you either
believe about yourself tonight or you don't; it does not have eleven parts. It should arrive
the way a thought arrives — all at once, coming into focus.

D20 gives the plainer reason as well, and it is the one that decides it: **word-by-word is too
slow by day twenty.** A reveal you have already seen nineteen times is a wait. Everything in
Force gets judged on the twentieth night rather than the first.

1.15 s is slower than anything else in the product (`slow` is 760 ms). That is deliberate. It
plays once a night, it is the first thing on the screen, and it is the sentence the entire
app exists to defend.

**Technique.** Do not use `ImageFiltered(ImageFilter.blur(...))` — it costs a `saveLayer`,
and the showcase measured the per-word version at roughly eleven offscreen passes for one
sentence. The performant path is a non-obvious trick: render the text as its own drop shadow,
transparent fill plus `Shadow(blurRadius: b, offset: Offset.zero)`. Identical optics, no
layer, and it degrades to a crisp glyph at `b == 0`. Measured raster p95 for the staggered
per-word version was 3.7–4.0 ms — and a whole-sentence bloom is one shadow rather than
eleven.

### 2. Emphasis — italic and a rule

The falsifiable clause goes italic, and a rule draws left-to-right beneath it over about
0.72 s, **beginning about 0.9 s after the bloom has settled** (D20).

So the sentence lands first and is allowed to be read whole, and only then does the app start
underlining the part of it that can be wrong. The gap is the point. Emphasis arriving inside
the entrance would read as one compound flourish; arriving after it reads as a second thought —
the app going back over the sentence you just took in and putting its finger on the half that
today can break.

Left-to-right, at reading speed, is the gesture of underlining a line in a book while you
read it — not a bar sliding in from the side. `accent` `#B4553A` lives on the rule; the words
stay `ink`, because accent measures 3.9:1 and D17 will not have it as type.

### 3. Hold to speak — the layered ring

Three closed contours, drawn back to front. Each is **a solid body of its own colour**:
`broken` `#8A7566` at the back, `ink3` `#7E858B` in the middle, `accent` `#B4553A` in front.
Depth comes from overlap and occlusion — the front body hides part of the one behind it, and
that hiding is what reads as layers.

**The gradient was explicitly rejected.** A gradient is a picture of depth; overlap is depth.
There is also a mechanical reason it would have been the wrong tool anyway: the showcase
found that across Force's near-black range, "any smooth gradient in that range bands visibly
on an OLED," and killing the banding took a ±0.016 per-pixel dither in a fragment shader. So
the gradient is both the weaker idea and the more expensive one.

The contours are driven by real microphone amplitude, not a decorative loop. From the
showcase, carried over exactly: RMS computed per buffer, converted to dBFS,
floored at −58 dB, gamma-shaped, then smoothed with an **asymmetric attack and release —
26/s up, 8.5/s down.** That asymmetry is most of why a meter reads as *voice* rather than as
noise. The three contours are built from a rolling ~2.3 s history and phase-offset from each
other, so your syllables visibly wind around the circle as you speak.

Everything in the frame loop is fixed-capacity and mutated in place — structure-of-arrays
`Float32List`s, no object allocation per frame. Measured: 96 particles over three 168-point
contours, build p50 1.3 ms, raster p50 0.82 ms, raster p95 1.27 ms. Flat.

### 4. Settle — Fling

**Real spring physics, integrated per frame. No CSS curve and no `Curve` appears anywhere in
this moment.**

**The constants are not written down here.** D20 points at
[`../spikes/flutter-showcase/lib/scenes/settle_scene.dart`](../spikes/flutter-showcase/lib/scenes/settle_scene.dart)
and says to read them there, and this document does the same. A `SpringDescription` copied into
prose is wrong the first afternoon someone tunes it, and then two files disagree and neither
says which one ships. Read the file.

What the shape has to be, and this part *is* the decision: **underdamped, one small overshoot,
and then still.** A few percent of overshoot, once, and at rest fast enough that you are not
waiting on it. That is a mark that has weight and stops moving, not a mark that bounces. If a
tuning pass ever produces two overshoots or a visible wobble, it has left D20 regardless of what
the numbers say.

**Interruptible is the whole reason for the spring** — and Flutter's own spring cannot do it.
`AnimationController.animateWith(SpringSimulation)` cannot retarget mid-flight.
So Force writes its own simulation clock — `Spring1D.retarget()` rebuilds the simulation
seeded from the current `x` *and* `dx`, so position and velocity both carry across. There is
a 620 ms window before the verdict commits, and changing your mind inside it **redirects**
rather than restarts.

The mark can also be picked up and thrown. The fling velocity goes straight into the spring,
so a hard throw overshoots and a gentle one does not. This is the piece that makes the settle
feel like an act rather than a confirmation: a `broken` day you threw into the strip lands
differently from one you placed there, and you did that, not the app.

### Measured, with the caveats stated

Over a 6.5-minute auto-drive exercising every animation in all six scenes:

- **14,884 frames**, zero exceptions, zero layout overflows
- **22 frames (0.15%)** over the 8.33 ms 120 Hz budget
- **3 frames (0.02%)** over the 16.67 ms 60 Hz budget
- Memory plateaued and then *declined* — 355.8 MB peak, 262.8 MB at the end, flat to within
  0.3 MB over the final 90 s. No leak.

Two honest caveats, both from the spike's own notes. **The iOS Simulator vsyncs at 60 Hz**, so
120 Hz was never actually exercised — the table shows work per frame, and headroom inside an
8.33 ms budget is an inference, not a measurement. And these are **debug-mode numbers**; the
simulator has no profile or release build, so the build figures should improve and the raster
figures are the honest ones. Both need a physical ProMotion device to close out.

The showcase's own verdict on the ceiling: "I did not hit it on design or motion. I hit
platform and tooling limits… For Force specifically — a quiet, typographic, dark, once-a-night
app whose most demanding surface is a voice visualiser — Flutter is not the constraint."

## Illustration (D16)

### The look: engraving line art, knocked out, recoloured

Chosen from four generated directions in `../spikes/illustration/`. The other three were
rejected on sight:

| Direction | Verdict |
|---|---|
| Abstract | *"the abstract one didn't make sense to me"* |
| Cinematic | *"cinematic is just a street with a kid in it"* |
| Risograph | Read as a generic agency poster |
| **Engraving** | **Chosen** |

Engraving wins on two counts. It is the most workable: the subject knocks out to transparency
and recolours onto any ground, so **it inherits the palette instead of dictating one.** And
it carries a thread from v1, which used sketchy hand-drawn marks — the product keeps a piece
of its own history rather than arriving as a stranger.

Proven, not assumed: `../spikes/illustration/proof-recolour.png` shows the same three
engravings composited onto dark, paper and deep-teal grounds.

### The prompting rule — this one was learned the hard way

**The prompt must explicitly forbid paper texture, vignette, border, frame and drop shadow.**

Without those exclusions the model renders the illustration *on* something — a sheet of aged
paper, a soft vignette, a thin keyline — and that something has its own luminance. When you
knock the image out, the ground knocks out with it and you get **a visible rectangle floating
on your app's background.** The `dir3-engraving` tile in the proof sheet is exactly this
failure, preserved so nobody has to rediscover it.

This is not a stylistic preference. It is a hard requirement of the pipeline, and it belongs
in the prompt template as a fixed clause, not as advice.

### Knockout: luminance as alpha

The subject is black linework on white. So the knockout is not a segmentation problem — it is
arithmetic. **Take the image's luminance and use it as the alpha channel.** White becomes
fully transparent, black becomes fully opaque, and every anti-aliased grey in between becomes
a partial alpha.

That last part is why this beats the obvious approach:

- **A segmentation model eats thin hatch lines.** It mistakes them for background, because at
  a one- or two-pixel width against white that is a defensible guess. Cross-hatching is the
  single worst input for a matting model, and cross-hatching is the entire style.
- **Luminance-as-alpha keeps the anti-aliased edges** rather than collapsing them to jagged
  1-bit lines. The hatching stays soft where the renderer drew it soft.
- It is free and fast — `sharp` inside the Vercel function, sub-100 ms, zero marginal cost,
  no second provider, no extra network hop.

This is a genuine advantage of having chosen this style. Most illustration languages would
have forced a matting service into the pipeline; this one turns the removal step into a
channel swap.

### Where illustration goes

| Surface | Illustration? | Why |
|---|---|---|
| Per-claim image | **Yes** — generated at commit, regenerated every 28 days | This is the "visualise it" mechanism from the opening brief. Rare and always changing, so it cannot become wallpaper. |
| The record | Yes | A sit-down-and-read surface. |
| Reviews (day 7, day 28) | Yes | Same. |
| Onboarding | Yes | Same. |
| **The evening gate** | **Never. No exceptions.** | See below. |

### The absolute rule: never on the evening gate

The evening gate is the claim, the voice, and what happened. Nothing else.

D16 states the reason in one line, so quote it rather than paraphrase it: decoration
there "is the app patting you on the head at the moment it should be taking you seriously —
the Calm/Headspace failure mode."

There is a second reason, which is the generating principle. The gate is the one screen you
face every single night. An illustration there would be the most-repeated image in the
product, and *what repeats must be abstract or absent.* Within three weeks it would be
furniture. Within six it would be the thing you scroll past — which is the precise motion
that killed v1.

The per-claim image regenerates every 28 days. That is roughly thirteen images a year — one
at signup and one per window — each made from a sentence they wrote and a thing they said out
loud. Rare enough to still land.

### Provider

Full live pricing and capability research is in
[`../spikes/illustration/COSTS.md`](../spikes/illustration/COSTS.md) (researched 2026-08-04;
it goes stale fast — several models on that page have published shutdown dates within four
months). D16 records the shortlist:

| Option | $/image | $/1,000 users/yr | Note |
|---|---|---|---|
| **Recraft V3 Vector** | $0.08 | $1,040 | Ships a literal `Engraving` style and returns true SVG. **Spike before committing.** |
| **Ideogram 3.0 Turbo** `generate-transparent` | $0.04 | $520 | The only provider with native-alpha *generation*. `style_code` = persistent style ID. |
| **FLUX.1 [schnell]** via Together | $0.0027 | $39 | 15× cheaper, Apache-2.0, no style ID, DIY knockout. |

**That shortlist is history now. D24 made the call: stay with the provider that produced the
approved samples, one provider and one pipeline, revisit at thousands of users.** The reason the
shortlist existed was native transparency, and native transparency turned out to be unnecessary
— the luminance knockout above is not a fallback, it is the better tool for cross-hatching. At
roughly thirteen images per user per year the price gap between any two rows in that table is a
few dollars, which is not worth a second integration.

The one thing to confirm at wiring time, per D24: the exact model ID. Imagen 4 shut down
2026-08-17 and it is a different model from the Gemini image model the samples came from — see
[Open](#open).

## Open

Genuinely undecided. Do not treat anything in this section as settled. The palette (D19) and the
motion language (D20) are **not** on this list any more — they are decided.

**`unsettled` `#5A6066` measures 2.97:1 against `bg`.** That is 0.03 under the 3:1 WCAG
non-text minimum for graphical objects. It is a 1.7× improvement on v1's 1.72:1 outline and
it is nowhere near the old failure, but it is under the line, and it is under the line on the
exact state D7 calls the most diagnostic signal in the product. D19 locks the hex, so the cheap
fix is the one the showcase already used: carry the contrast with stroke weight rather than
colour (it moved the unsettled ring from 1.4 px to 1.6 px and from `outline` to `mute`).
Changing the value instead would be a change to D19 and goes back to the record. **Not decided
which.** Whichever way it goes, measure it and write the number down.

**What colour a per-claim illustration recolours to.** D16 says the engraving inherits the
ground rather than dictating one, and the Ash palette has exactly one chromatic token whose
entire discipline is scarcity. A full-bleed illustration rendered in `accent` would put more
of that colour on one screen than the rest of the app uses in a month. `ink`, `ink2` and
`ink3` are all candidates. **Not decided.**

**Light theme.** Every measurement in this document is against a dark ground. The spikes were
dark-only, explicitly out of scope in `../spikes/SPEC.md`. Whether Force has a light theme at
all is not decided, and if it does, the entire contrast table is re-measured, not inverted.

**The illustration provider's exact model ID.** The provider question itself is closed by
**D24**: stay with what produced the approved samples, one provider and one pipeline, and
revisit at thousands of users. Native transparency turned out not to be worth switching for —
for black line art on white, luminance thresholding beats a segmentation model, which eats thin
hatch lines. What is *not* settled is the exact model ID, and D24 says to confirm it at wiring
time: Imagen 4 shut down 2026-08-17 and it is a different model from the Gemini image model the
samples came from.

**The web design system.** D13 records the cost of choosing Flutter honestly: "the design
system now lives in two places — Dart for the app, React for the Vercel landing page and
dashboard… a tax paid once at the design-token level." The shape of that shared token layer —
what format, what generates what — is not designed. See
[`./ARCHITECTURE.md`](./ARCHITECTURE.md).

**Motion under real load.** The frame numbers above are iOS Simulator, debug mode, 60 Hz.
120 Hz sustained on a physical ProMotion device under thermal load has never been measured,
and RESULTS.md lists sustained animation under load as still open. Nothing here should be
quoted as a device figure until someone runs it on hardware.

## See also

- [`../FORCE-V2.md`](../FORCE-V2.md) — the decision record. D1–D24, each with its reasoning;
  D19 (palette) and D20 (motion) are this document's spine. If this document ever contradicts
  it, that file wins.
- [`./COPY.md`](./COPY.md) — voice, register, and what the app is allowed to say.
- [`./ARCHITECTURE.md`](./ARCHITECTURE.md) — how the surfaces fit together.
- [`./PLATFORM.md`](./PLATFORM.md) — what each OS permits, including the NSPanel gate (D18).
- [`./DATA-MODEL.md`](./DATA-MODEL.md) — claims, days, and the three states these colours render.
- [`../plans/ROADMAP.md`](../plans/ROADMAP.md) — when the design pass happens relative to the loop.
- [`../spikes/flutter-showcase/NOTES.md`](../spikes/flutter-showcase/NOTES.md) — the motion,
  legibility and typography measurements this document is built on.
- [`../spikes/RESULTS.md`](../spikes/RESULTS.md) — the stack comparison, including Fraunces
  rendering quality across all three engines.
- [`../spikes/illustration/COSTS.md`](../spikes/illustration/COSTS.md) — image generation
  providers, pricing and transparency support.
