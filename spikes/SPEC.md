# Spike spec — "The Evening Gate"

**Purpose:** decide the v2 stack by feel, not by argument. Three builds of the *same*
screen, on the same Mac, judged side by side.

**Rule:** every build implements this spec exactly. If the screens differ, the comparison
measures my taste instead of the stack, and the whole exercise is wasted.

**This is a throwaway.** Functionality only. It reuses v1's theme and fonts on purpose so
the comparison is about the stack, never the design. None of this code survives.

---

## The three builds

| Build | Path | Role |
|---|---|---|
| **SwiftUI** | `swift-gate/` | the **benchmark** — the quality bar the user already trusts |
| **Tauri v2 + React** | `tauri-gate/` | contender: shares components with the Vercel web |
| **Flutter** | `flutter-gate/` | contender: identical rendering on every platform |

---

## The screen

A single full-window view. Dark theme only for the spike.

```
┌────────────────────────────────────────────────────┐
│                                                    │
│   TUESDAY, 4 AUGUST                    ·····••     │   ← record strip, last 7 days
│                                                    │
│                                                    │
│        I am someone who trains                     │   ← the claim (Fraunces, ~44px)
│        when I don't feel like it.                  │
│                                                    │
│        this morning you said:                      │   ← muted, small (Inter, 13px)
│        "gym after the 4pm shift"                   │
│                                                    │
│                                                    │
│              ╭──────────────────╮                  │
│              │  HOLD  TO  SPEAK │                  │   ← primary action
│              ╰──────────────────╯                  │
│                                                    │
│                   Not tonight                      │   ← one tap, no confirm
│                                                    │
└────────────────────────────────────────────────────┘
```

### Interaction sequence (all three must do all of it)

1. **Idle.** Claim visible. Record strip shows the last 7 days.
2. **Press and hold** the button. Recording starts.
   - The button morphs into a **live audio level meter** — a row of ~40 bars driven by
     real microphone amplitude at ~60fps. *This is the main animation stress test.*
   - A timer counts up.
3. **Release.** Recording stops. A stubbed transcript fades in below the claim.
   *(Real STT is out of scope for the spike — a canned string after ~400ms is fine.
   We are measuring rendering and feel, not transcription.)*
4. **Settle.** Two verdict buttons appear: `KEPT` / `BROKEN`.
   On tap, the day's mark animates into the right-hand end of the record strip —
   a spring transition, ~600ms. The screen then fades to a closing state.
5. **"Not tonight"** at any point: one tap, no confirmation dialog, immediate close.
   The day is recorded `unsettled` (a hollow mark).

### Why these specific elements

Each one exists to stress something the stacks genuinely differ on:

| Element | What it tests |
|---|---|
| Custom fonts (Fraunces + Inter) | font loading, text rendering quality, optical weight |
| Large serif display type | subpixel/antialiasing differences between engines |
| 40-bar live audio meter @ 60fps | sustained animation under real-time data |
| Microphone access | native permission plumbing from each stack |
| Spring settle transition | animation curve quality and interruptibility |
| Full-window borderless-ish shell | window management from each stack |
| Cold start to first paint | the number the user actually feels every night |

---

## Theme (from `force-old/Sources/Force/Theme.swift` — dark)

```
base              #141515      containerLow      #1B1C1D
container         #222324      containerHigh     #2A2B2C
containerHighest  #313334      bright            #3A3C3D
ink               #F2F2F0      inkContainer      #C9C9C6
ash               #DADAD7      mute              #9A9E9F
stone             #60646A      outline           #3C3F40
outlineSoft       #2A2C2D      onPrimary         #141515
```

Record strip marks (spike-only, since the real palette can't express these yet):
`kept` = filled ink · `broken` = filled stone · `unsettled` = hollow outline ring

**Fonts:** `force-old/Sources/Force/Resources/Fonts/Fraunces.ttf` (display) and
`Inter.ttf` (UI). Copy into each build.

---

## Measurements to collect for each build

| Metric | How |
|---|---|
| Cold start → first paint | timed launch, 5 runs, median |
| Idle memory (RSS) | `ps` after 30s idle |
| Memory while metering | `ps` during a 10s hold |
| Bundle size | release build, `du -sh` |
| Animation smoothness | subjective, plus dropped-frame observation |
| Build time (clean, release) | wall clock |
| Lines of code for the same screen | `wc -l` |

Results land in `spikes/RESULTS.md`.

---

## Explicitly out of scope

- Real speech-to-text
- Any backend, sync, or auth
- Any LLM call
- Light theme
- Windows or Android builds *(neither can be felt from this Mac — Windows needs CI,
  Android needs ~5 GB of SDK. Earn them after the Mac comparison decides something.)*
- Anything resembling final design
