# design/ — the five review surfaces

The clickable design work: the demo, the flow chart, the screens, the motion lab and the
wireframe walkthrough. **This directory decides nothing.** `FORCE-V2.md` is the decision
record and it wins. Several of these pages deliberately show things the record does not
authorise — see [What these pages propose](#what-these-pages-propose) below.

## Recovered 2026-08-07

All five were published as claude.ai artifacts on 2026-08-04/05 and **all five were later
deleted from the server**. Every one of the URLs listed in `HANDOFF.md:220` now returns
"artifact not found", and the account's artifact listing shows nothing newer than
2026-07-31. `HANDOFF.md:216` had already recorded that the build source was gone and
assumed the published HTML could be re-derived from. It could not — both copies were gone
at once.

What survived is `~/.claude/file-history/7d6102db-e380-49d1-9586-1a9b98ab9e71/`: 119
byte-exact snapshots of every part file, because each was written with the Write tool.
The true filenames were confirmed against the session transcript at
`~/.claude/projects/-Users-clupa-Documents-projects-force/7d6102db-….jsonl`, which records
all 26 part paths and the original `build_demo.py`.

**The lesson is the one Phase 0 already carries.** The root is still not a git repo. The
one design surface that lived only off-disk is the one that vanished. These files are now
on disk; they are not yet under version control, because nothing here is.

## Layout

```
design/
  build.py                     rebuild all five — recovered build_demo.py, widened
  parts/demo/   10 files       "Force — the desktop demo"      27 states, six acts
  parts/flow/    3 files       "Force — the whole shape"       24 screens, Copy notes
  parts/ui/     13 files       "Force — the screens"           34 plates, A–H
  standalone/    2 files       Motion & Palette Lab, Wireframe Walkthrough
  assets/                      Fraunces-Italic.ttf — the one font with no other copy here
  built/                       generated; not source
```

`build.py` concatenates each part directory in `sorted()` order, exactly as the original
did. Part order is load-bearing and is not obvious: `03-b1.html` sorts **before**
`03-b1b.html`, which puts plate B3b between B3 and B4. Getting that wrong reorders the
screens page and drops an anchor.

## Rebuilding

```sh
python3 design/build.py
open design/built/force-desktop-demo.html
```

Needs `fonttools`, `brotli` and `Pillow` — all present in the anaconda python3 on this
machine. Output is two files per page: `*.body.html` for publishing (the artifact
publisher supplies its own `<!doctype>`/`<head>`/`<body>` skeleton) and `*.html` wrapped
for opening locally.

### The two asset files that did not survive

`fonts_b64.json` and `masks_b64.json` were built with Bash rather than Write, so file
history never captured them. `build.py` regenerates both:

| Asset | Source | Treatment |
|---|---|---|
| Fraunces, Inter | `spikes/flutter-showcase/assets/fonts/` | subset to Latin + margin, → woff2 |
| Fraunces Italic | `design/assets/Fraunces-Italic.ttf` | same; from google/fonts, SIL OFL |
| tally, hand | `spikes/illustration/eng-{tally,hand}-alpha.png` | 768 px, lossless webp |

The pages use only `wght` and `opsz` — `SOFT` and `WONK` are never touched — but the
subset keeps all four axes. Masks are read as **alpha only**: the engraving is recoloured
through its own luminance as a CSS `mask-image` and never ships as pixels of its own
colour (D16, D24). 768 px covers the largest on-screen use, 330 px, at 2×; the
cross-hatching survives the downscale, which is the thing D24 warns about.

Rebuilt payload is 889 KB of base64 against the original build log's ~760 KB. The
difference is subsetting choices, not content.

## Verified after rebuild

Rendered in headless Chrome, not just parsed:

| | |
|---|---|
| Demo | 27 `STEPS`, six acts, `1 / 27` counter, Motion panel on **B**, Fraunces rendering |
| Flow | 24 `.node` boxes, the four edge kinds, the single orange irreversible edge, Copy notes |
| Screens | 34 plates `a1`→`h5` in nav order, **zero unresolved anchors** |
| Masks | both engravings recolour through `ink3`, hatch lines intact |
| JS | every embedded script passes `node --check`; all tag counts balance |

## What these pages propose

`HANDOFF.md:232` lists **seven things the demo implements that `FORCE-V2.md` does not
authorise**. They are tagged `open` in the demo's own Notes drawer and none may be treated
as settled until each lands in the record as a numbered decision with reasoning:

- the commit flood — accent filling the window, which breaks D19's one-use rule *and* D17,
  since nothing clears 4.5:1 on that orange
- the moving line replacing D20's layered ring
- the line being orange and still at rest, putting two accents on five screens
- the reversibility rule — "everything before a commitment is reversible, the commitment
  is not, and the screen says which it is"
- directional page transitions with no blur
- stagger only where order is information
- the bloom at 0.95 s against D20's ~1.15 s

The screens page carries its own **NOT DECIDED** section, which is the honest list: a
fourth verdict (`partial`), `unsettled` measuring 2.97:1 against the 3:1 floor, Fraunces
Italic, and the landing page.

## Reading them

Start with **the screens** — it is the product plate by plate at review fidelity, it names
the decision each screen obeys, and anything undecided is drawn dashed and says so. Then
**the whole shape** for how the screens connect. The **demo** is the one to judge motion
on, and the only one where the Motion panel is live.

One process rule attaches, from `FORCE-V2.md` §6 and the roadmap's closing line: **ship a
control, not a value.** Feedback on the demo arrived as felt symptoms — "comes in too
fast" — never as a spec, and "too fast" turned out to have three different root causes.
The Motion panel is where those numbers get decided. One ask per pass; do not batch.
