# Flutter showcase — what the stack can actually do

A six-scene, swipeable demo of Force's real product moments, built to answer one
question: **is Flutter's design and motion ceiling high enough for Force?**

Not a feature spike. Every scene exists to stress a different *class* of motion.

```
flutter run -d 9DC0D285-C3C1-4928-AB56-2598F36BAE87
```

Optional flags (all `--dart-define`):

| flag | effect |
|---|---|
| `SCENE=n` | open on scene n (0–5) |
| `POSE=true` | each scene poses itself for a screenshot |
| `AUTODRIVE=true` | cycles scenes and exercises every animation, hands-free |
| `LOCK=true` | with AUTODRIVE, stay on the starting scene (per-scene soak) |
| `SYNTH=true` | force the synthesised voice envelope over the live mic |
| `FPSLOG=true` | print frame build/raster percentiles every 5 s |

> `bool.fromEnvironment` only accepts the literal strings `true`/`false`.
> `=1` silently evaluates to false — it cost me one wasted 4-minute soak.

Screenshots of all six scenes are in `shots/`.

---

## The scenes

### 1 · The claim — `lib/scenes/claim_scene.dart`
**Class of motion: staggered per-word entrance with animated blur.**

The identity claim arrives word by word, out of blur, from below, decelerating
hard (`Cubic(0.16, 1, 0.3, 1)`). The attribution quote follows a beat later —
D9's locked mechanic, the proof the sentence came out of your mouth.

The technique worth stealing: **per-word blur without a single `saveLayer`.**
`ImageFiltered(ImageFilter.blur(...))` per word is ~11 offscreen passes for one
sentence. Instead each word renders as its own drop shadow — transparent fill,
`Shadow(blurRadius: b, offset: Offset.zero)`. Identical optics, no layer, and it
degrades to a crisp glyph at `b == 0`. `BlurText` in `common.dart`.

Timing is written as an absolute score in milliseconds rather than a pile of
`Interval`s. Eleven staggered words are unreadable any other way.

### 2 · The record — `lib/scenes/record_scene.dart`
**Class of motion: staggered spring entrance + retargetable expansion.**

Seven days, three states (D7). The entrance is not a curve imitating physics:
one `SpringSimulation` is sampled analytically at each mark's own staggered time
offset, so the overshoot is a consequence of mass and stiffness. Tapping a day
expands it; tapping a second day mid-expansion *redirects* rather than restarts.

The strip is one `CustomPainter` repainting off a `ChangeNotifier`, with tap
targets floated over it — a 120 Hz spring costs zero framework rebuilds.

### 3 · Hold to speak — `lib/scenes/speak_scene.dart`
**Class of motion: sustained real-time data visualisation at vsync.**

Press and hold. Back to front: a 96-mote particle field pushed outward by
amplitude; three amplitude contours built from a rolling 2.3 s history and
phase-offset from each other, so your syllables visibly *wind around* the circle
as you speak; onset ripples on level peaks; the elapsed clock in the middle.

**Audio source — read this.** The `record` package's PCM stream works on the iOS
Simulator: it picks up the host Mac's microphone, and the on-screen label reads
`signal · live microphone` when it does. RMS is computed per buffer, converted to
dBFS, floored at −58 dB and gamma-shaped, then smoothed with an asymmetric
attack/release (26/s up, 8.5/s down) — that asymmetry is most of why a meter
reads as *voice* rather than *noise*.

There is also a synthesised fallback: syllables of 90–220 ms at a 3.5–6 Hz rate,
grouped into phrases with breath pauses and the occasional stressed syllable. It
engages automatically if the mic is denied, errors, or returns exact silence for
40 buffers, and it can be forced with `SYNTH=true`. **`shots/3-speak.png` was
captured with `SYNTH=true`** — a quiet room produces a nearly flat contour, which
photographs as broken rather than as quiet. The label on screen always says which
source is live; the demo never fakes its input silently.

Everything is fixed-capacity and mutated in place — structure-of-arrays
`Float32List`s, no object allocation in the frame loop.

### 4 · The settle — `lib/scenes/settle_scene.dart`
**Class of motion: velocity-carrying, retargetable 2-D springs.**

The day's verdict is a physical object. Tap a verdict, or pick the mark up and
throw it — the fling velocity goes straight into the spring, so a hard throw
overshoots and a gentle one does not. There is a 620 ms window before the verdict
commits, and changing your mind inside it does not restart the animation: it
**redirects**, with position *and* velocity carried across.

That is what `Spring1D` exists for (`common.dart`).
`AnimationController.animateWith(SpringSimulation)` cannot retarget mid-flight,
which is the entire reason to use a spring. `Spring1D.retarget()` rebuilds the
simulation seeded from the current `x` and `dx`. No `Curve` appears anywhere in
this scene.

The token also paints a velocity-gated trail, sampled on its own 90 Hz clock so
the streak reads the same length regardless of display refresh rate.

### 5 · The field — `shaders/field.frag`, `lib/field.dart`
**Class of motion: a GLSL fragment program, at surface resolution, 100% of the
time.**

Two octaves of value noise, two levels of domain warp, a breathing focal lobe, a
vignette and per-frame grain. It runs behind *every* scene — one shader, one
ticker, one `RepaintBoundary` — and each scene writes its wishes (`uIntensity`,
`uBreath`, `uFocus`) into a controller that eases toward them, so the background
never cuts. Scene 3 drives `uBreath` from live voice amplitude.

The part that matters and that nobody asks for: **the grain.** Force's palette
runs `#141515 → #222324`, a four percent luminance swing. Any smooth gradient in
that range bands visibly on an OLED. A ±0.016 per-pixel dither kills it. There is
no way to do that with a CSS gradient.

The second demonstration: the same program in "ink mode" (`uMode = 1`) is used as
the **fill of the display serif** via `ShaderMask`, so the type is made of the
room it is standing in — warping and grainy, live. In a webview that means
rasterising text to a texture and compositing it in WebGL.

One real gotcha: a `ui.FragmentShader` is a *mutable* object and the recorded
picture only holds a reference. Using one instance twice in a frame with
different uniforms means the second `setFloat` retroactively changes the first
draw. Two instances off the same `FragmentProgram` is the fix, and it costs
nothing.

### 6 · The sharpening — `lib/scenes/sharpen_scene.dart` (my pick)
**Class of motion: layout-aware text choreography from a keyed diff.**

D4 says "rewording until it's true *is* the work"; D9 puts the first forced
rewrite on day seven. It is the one moment in Force where a sentence *changes* —
and every other app would render that as a crossfade between two blocks of text.

This runs an LCS diff over lowercased tokens and animates three classes at once:

- words that **survive** translate to their new position and never fade
- words that **die** blur out and drift up, fast, in the first 42%
- words that **arrive** blur in from below, staggered

The result is that the sentence visibly rewrites itself — "I" holds its place
while everything around it is replaced. It walks the three claims from D2:
*"takes care of their body"* (unfalsifiable) → *"I train four times a week"* (a
habit in an identity costume) → *"trains when I don't feel like it"*.

This is the scene that convinced me Flutter's text stack is a real one: I get
per-word metrics out of `TextPainter` and lay them out myself. Positions are
measured once per (draft, width) and memoised.

---

## Legibility

Force is opened on the nights you are least sharp. That is not an edge case for
this product, it is the design case, so the type has a hard floor rather than a
target. The whole scale was rebuilt against it partway through:

| role | before | now |
|---|---|---|
| prose / testimony / transcript | 14 | **17** |
| supporting prose | 12.5 | **16** |
| smallest readable text | 9–11 | **15** |
| uppercase tracked labels | 10 (1.7 tracking) | **14 (2.2 tracking)** |
| button / verdict | 12 | **15** |
| record strip day letters | 9 | **14** |

Contrast, measured against `base` `#141515`:

- `ink` #F2F2F0 — **16.32:1** · `inkContainer` #C9C9C6 — 11.1:1 · `mute` #9A9E9F — **6.77:1**
- **`stone` #60646A is 3.07:1 and has been retired as a text colour.** It fails
  4.5:1 outright. It survives only as the *fill* of a `broken` mark, where the
  3:1 non-text minimum applies and it passes. Every place that used stone for
  type now uses `mute`, which is now the quietest voice in the app.
- `outline` #3C3F40 is 1.72:1 — a 1.4 px `unsettled` ring in it is invisible on a
  dark phone at night. The unsettled ring and the empty "today" slot are now
  `mute` at 1.6 px.
- No text sits below 0.7 opacity in a resting state. The record strip's day
  letters had a 0.42 alpha floor; it is now 0.78. The strip no longer dims at all
  on selection — `broken` is already *at* the 3:1 floor, so any knock-down puts
  it under. Selection is carried by a halo and by size, which cost no contrast.

`MediaQuery.textScaler` is honoured, not clamped:

- reserved-height boxes (the transcript slot, the record detail panel, the scene
  bottom margin) scale their reserves through a `scaled(context, px)` helper,
  because honouring the setting while holding fixed space open just means
  clipping at 200%
- the claim in scene 1 is laid out word-by-word in a `Row`, which cannot wrap, so
  it sits in a `FittedBox(scaleDown)` — the choreography survives, the overflow
  does not
- eyebrow rows use `Wrap(spaceBetween)`, which pins both ends when they fit and
  drops the second onto its own line when they do not

One deliberate compromise: the scene-indicator ticks are 44×30 pt, not 44×44.
Swiping is the primary navigation and the ticks are a secondary shortcut; 44 pt
of vertical there would have eaten the bottom margin.

### A Flutter layout trap worth writing down

`Row(children: [Flexible(a), SizedBox(), Expanded(b)])` does **not** push `b` to
the right margin. Flex space is *allocated* before children are laid out, so a
loose `Flexible` that under-uses its half leaves the leftover stranded and `b`
lands mid-screen. It looked correct in code and wrong on the device.
`Wrap(alignment: spaceBetween)` is the right primitive and degrades better.

---

## Memory — no leak

Auto-drive cycles all six scenes on a 9 s dwell and exercises every animation:
the claim replays, days are selected, the mic starts and stops, verdicts are
chosen and *retargeted mid-flight*, the field's focus moves, the claim rewrites.
RSS sampled with `ps -o rss=` every 10 s, final build:

```
  0s 350.7   70s 303.0  140s 301.3  210s 272.7  280s 291.6  350s 262.7
 10s 355.8   80s 304.7  150s 304.3  220s 274.4  290s 291.6  360s 262.7
 20s 323.2   90s 305.4  160s 304.7  230s 278.8  300s 295.4  370s 262.8
 30s 327.2  100s 307.3  170s 303.8  240s 295.2  310s 262.5  380s 262.8
 40s 333.2  110s 307.8  180s 283.7  250s 294.5  320s 262.5  390s 262.8
 50s 299.3  120s 308.2  190s 278.7  260s 294.7  330s 262.6
 60s 301.0  130s 308.8  200s 267.5  270s 291.6  340s 262.6
```
(MB, 6 min 30 s of continuous animation)

**Verdict: plateau. No leak.** Peak 355.8 MB in the first 10 s, then a net
*decline* to 262.8 MB. The final 90 s are flat to within 0.3 MB. The sawtooth
between 50 s and 300 s is the Dart heap growing toward each major GC and being
reclaimed; the floor drops, it never rises.

**A methodology note that changed my answer.** A 3-minute window would have been
misleading. On an earlier 9-minute run the 70 s → 240 s stretch climbed
monotonically from 305 MB to 325 MB with no GC drop at all — 7 MB/min, which
reads exactly like a leak. It was the heap approaching its next major-GC
threshold. It did not resolve until 350 s. If you sample this app for three
minutes and stop, you will report a leak that is not there. Both runs plateau
below their starting RSS once the collector catches up.

Caveats, stated plainly:

- **These are debug-mode numbers.** The iOS Simulator only supports JIT, so
  `--profile` and `--release` are not available on it. 260–350 MB includes the
  Dart VM in JIT mode, the hot-reload machinery and the VM service. Release AOT
  on a physical device will be dramatically lower and is not measured here.
- The riskiest path for a native leak is the `record` PCM stream, which
  auto-drive starts and stops roughly every 6 s while scene 3 is on screen. It
  is inside the plateau. `SpeechEngine.stop()` cancels the subscription and stops
  the recorder; `dispose()` disposes the `AudioRecorder`.
- Two caches are static and deliberate: the strip's day-letter `TextPainter`s
  (keyed by letter × 16 alpha steps — 112 entries maximum) and the sharpening's
  per-draft word metrics (keyed by draft × width). Both are bounded, so they are
  caches, not leaks.

---

## Frame rate

`FPSLOG=true` installs a `SchedulerBinding.addTimingsCallback` and prints build
and raster percentiles every 5 s. Over the 6.5-minute auto-drive run:

- **14,884 frames**, zero exceptions, zero layout overflows
- **22 frames (0.15%)** exceeded the 8.33 ms 120 Hz budget
- **3 frames (0.02%)** exceeded the 16.67 ms 60 Hz budget
- typical: `build p50 0.4–1.3 ms · p95 1.0–2.4 ms` — `raster p50 0.6–1.1 ms · p95 0.8–4.8 ms`

Per-scene, 40 s locked on each:

| scene | build p50 | raster p50 | raster p95 | note |
|---|---|---|---|---|
| 1 claim | 0.88 | 1.00 | 3.7–4.0 | blur-shadow text is the raster cost |
| 2 record | 1.2 | 0.78 | 1.15 | cheapest |
| 3 speak | 1.3 | 0.82 | 1.27 | 96 particles + 3×168-point contours, flat |
| 4 settle | 1.5–2.1 | 0.6 | 0.86 | build-bound: pill chrome rebuilds per frame |
| 5 field | 1.1 | 0.84 | 1.16 | full-screen shader is ~0.3 ms of raster |
| 6 sharpen | 0.7 | 0.75 | 4.2–4.7 | per-word blur across 11 words |

**Nothing dropped a 60 Hz frame in any scene.** Two honest caveats:

1. **The iOS Simulator vsyncs at 60 Hz** (n ≈ 305 frames per 5 s = 61 fps).
   120 Hz was never actually exercised. What the table shows is *work per frame*,
   and at 1–2 ms of build plus 1–5 ms of raster there is comfortable headroom
   inside an 8.33 ms budget — but that is an inference, not a measurement. It
   needs a ProMotion device to confirm.
2. Debug mode is slower than release for build (no AOT) and roughly equivalent
   for raster. The build figures should improve; the raster figures are the
   honest ones.

The worst raster p95 belongs to the two scenes using blurred text
(claim, sharpen) at ~4.7 ms. That is the price of the shadow-blur trick — still
half of a 60 Hz budget, and far cheaper than the `saveLayer` alternative.

---

## What Flutter made easy

- **`CustomPainter(repaint: someListenable)`.** This is the whole performance
  story. Point a painter at a `ChangeNotifier`, tick the notifier from a
  `Ticker`, and a 120 Hz animation invalidates exactly one `RenderObject` — no
  rebuild, no relayout, no `setState`. Every heavy scene here is built this way.
- **`TickerMode`.** Wrapping each page in `TickerMode(enabled: visible)` stops
  every `Ticker` and `AnimationController` beneath it. Six live animated scenes
  cost roughly one scene's frames. One widget, no bookkeeping.
- **Fragment shaders.** Drop a `.frag` in `pubspec.yaml`, `FragmentProgram.fromAsset`,
  `setFloat`. It compiles at build time via `impellerc` and runs as a Metal
  shader. Genuinely first-class, and `ShaderMask` composes with it for free.
- **Text metrics.** `TextPainter` gives per-word widths on demand, which is what
  makes the scene-6 diff choreography possible at all. Trying that against a
  browser's text layout would be considerably worse.
- **Springs are in the box.** `SpringSimulation`, `SpringDescription`, and an
  analytic `x(t)`/`dx(t)` that can be sampled at any time — which is what makes
  staggered spring entrances and mid-flight retargeting a dozen lines each.
- **No design system tax.** `WidgetsApp` with no Material or Cupertino. Force
  uses neither, and both put an inherited lookup on the path of every `Text`.

## What Flutter made hard

- **Variable fonts.** Flutter instantiates the fvar *default* instance. Fraunces'
  default is `wght 900 / opsz 9` — Black at caption optical size. Every style has
  to pin `wght` and `opsz` explicitly (`theme.dart`), and there is no automatic
  optical-size mapping the way CoreText does it for free on the SwiftUI build.
  This is the sharpest edge in the whole port and it is silent — you just get
  the wrong weight and wonder why the type looks heavy.
- **Blur is expensive by default.** The obvious API (`ImageFiltered`) costs a
  `saveLayer` each. The performant path is a non-obvious trick with `Shadow`.
- **`AnimationController` cannot retarget a spring.** For anything genuinely
  interruptible you end up writing your own simulation clock. ~35 lines, but you
  do have to know that you need it.
- **`FragmentShader` uniform aliasing.** Reusing one instance twice in a frame
  silently corrupts the earlier draw. Nothing warns you.
- **Flex allocation vs. layout.** See the `Flexible`/`Expanded` trap above.
  It reads correctly and renders wrongly.
- **Overflow is an error, not a reflow.** Useful discipline, but every type-size
  change is a layout change; the accessibility pass broke three compositions that
  had to be re-laid-out rather than re-sized.
- **The simulator is not the device.** No profile/release mode, 60 Hz only, and
  memory numbers that include the JIT. Every performance claim here needs a
  physical ProMotion device to be conclusive.

---

## Verdict on the ceiling

The ceiling is high enough that **I did not hit it on design or motion.** I hit
platform and tooling limits — the simulator's 60 Hz cap, no release build to
measure — not rendering limits.

Concretely: per-word animated blur, a full-screen domain-warped GLSL field, live
per-pixel dithering, type filled with a running shader, a 96-particle field over
three 168-point contours driven by real microphone PCM, velocity-carrying
interruptible springs, and a word-level text diff choreography — all composited
together, all under a 60 Hz frame budget with 0.02% of frames missing it.

Where I would expect to find the real ceiling, and did not get to test it here:

- **Very large scrolling surfaces of live-animated content.** Everything here is
  one screen at a time. `ListView` of 200 shader-backed cells is a different
  question.
- **Text rendering at the very top end.** Fraunces renders beautifully, but the
  variable-font default-instance problem suggests the OpenType path is shallower
  than CoreText's. Anything relying on advanced typographic features
  (contextual alternates, optical sizing curves, complex scripts) deserves its
  own spike.
- **120 Hz sustained under thermal load** on a real phone.

For Force specifically — a quiet, typographic, dark, once-a-night app whose most
demanding surface is a voice visualiser — Flutter is not the constraint. My taste
is.
