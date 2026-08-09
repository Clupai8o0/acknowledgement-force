# Spike results — macOS

Same screen (`SPEC.md`), three stacks, same machine, measured 2026-08-04.
M-series Mac, macOS 26.5.2, release builds, nothing else running.

---

## The numbers

| | **SwiftUI** | **Tauri v2 + React** | **Flutter** |
|---|---|---|---|
| **Cold start → first paint** *(median of 5)* | **212 ms** | **458 ms** | **208 ms** |
| range across runs | 174–318 ms | 418–470 ms | 196–223 ms |
| **Idle memory (RSS)** | 103–107 MB | 111 MB | 99–100 MB |
| **Release bundle** | **1.7 MB** | 10 MB | 36 MB |
| **Lines of code** (same screen) | **799** | 881 | 944 |
| Renderer | AppKit / Core Animation | WKWebView | Impeller (own renderer) |

**How cold start was measured.** SwiftUI and Flutter both take `t0` from the kernel's
`kp_proc.p_starttime` — the actual `exec`, so dyld, runtime bring-up and (for Flutter) the
Dart VM snapshot load are all inside the number. `t1` is the first frame handed to the
compositor. Tauri reports absolute epoch marks on stderr instead, so `t0` came from a
Python wrapper that stamps the clock and then `execv`s the binary in the same process —
a few ms of overhead at most, and it flatters Tauri rather than penalising it. The Tauri
figure is `first-contentful-paint` with the real fonts already resolved, which is the
fair comparison to the other two.

---

## What the numbers say

**Flutter and SwiftUI are indistinguishable on cold start — and Flutter is the more
consistent of the two** (196–223 ms spread vs SwiftUI's 174–318 ms). That was not the
expected result. Flutter also used the *least* memory of the three.

**Tauri is ~2.2× slower to first paint: 458 ms vs ~210 ms.** That gap is above the
threshold where a launch stops feeling instant and starts feeling like a load. For an app
whose entire job is to appear at 11pm and be faced, this is the single most relevant
number in the table, and it is the one place the webview genuinely costs something.

**Bundle size splits the other way.** SwiftUI 1.7 MB, Tauri 10 MB, Flutter 36 MB. All
three are irrelevant at these magnitudes — nobody abandons a 36 MB download. Noted for
completeness, not as a factor.

**Memory is a wash.** 99–111 MB across all three. The Electron fear does not materialise;
Tauri's webview costs ~8 MB more than native, not 200 MB.

**Code volume is a wash.** 799 / 881 / 944 lines for an identical screen. No stack is
meaningfully more expressive than another at this scale.

---

## Screenshots

- `swift-gate/screenshot.png`
- `tauri-gate/screenshot.png`
- `flutter-gate/screenshot.png`

All three rendered the Fraunces display type cleanly and near-identically at a glance.
Flutter's own renderer did **not** produce the serif-quality penalty that was the main
qualitative worry going in.

---

## Notes from building them

**Tauri** — needs no Xcode, only Command Line Tools. Smallest install footprint of the
three. Its window did not come to the front on launch and landed on a secondary display;
minor, but window management is the layer you'd be writing Rust for anyway.

**Flutter** — **requires full Xcode** for macOS desktop (~15 GB), which Command Line Tools
alone will not satisfy. Its window also failed to raise to the front and had to be captured
by window ID. Logged `Running with merged UI and platform thread. Experimental.` on every
launch — worth watching, but it did not misbehave.

**SwiftUI** — builds with CLT alone via SPM, no Xcode project needed. Smallest bundle,
fewest lines. And the platform ceiling: macOS and iOS only, which is the wrong ceiling
for a Mac + Windows + Android target.

---

---

## Android — the tiebreaker

**Verdict: Flutter, decisively. Chosen 2026-08-04.**

| | **Flutter** | **Tauri** |
|---|---|---|
| Source changes needed | **none** | 1 × `#[cfg(desktop)]` guard |
| Generated Gradle wrapper | **9.1.0** — works with Android Studio's bundled Java 25 | 8.14.3 — rejects Java 25 (`Unsupported class file major version 69`) |
| Manual toolchain fixes | **0** | **3, and still not building** |
| Release APK | **39 MB, first attempt** | never produced |

**The three Tauri blockers, in order:**

1. **`set_always_on_top` does not exist in Tauri's Android build.** Desktop-only API; the
   same Rust that compiles for macOS fails for `aarch64-linux-android` until every
   desktop-only call is `#[cfg(desktop)]`-gated.
2. **Gradle/JDK conflict.** `tauri android init` generates Gradle 8.14.3, which cannot run
   under the Java 25 that a default Android Studio install ships.
3. **Bumping Gradle to 9.1.0 broke Tauri's own `buildSrc`** (`:buildSrc:compileKotlin`
   failed). The correct fix is a JDK 21 sidegrade, i.e. maintaining a second JDK purely
   for this stack.

This is a **maintenance-tax** finding, not a rendering one — and it landed on a screen with
*one* window API call. A real Force build does window management, notifications, launch-at-
login and wake-from-sleep, and **D8 says that exact layer is where v1 died silently.** For
one person shipping to Mac + Windows + Android, every divergence is a 1am debugging session
instead of product work.

**What choosing Flutter costs:** the design system lives in two places — Dart for the app,
React for the Vercel landing page and dashboard. That was Tauri's best argument and it was
real. It is a tax paid once at the design-token level, against a platform-divergence tax
charged forever plus a 2.2× slower launch.

---

## Still unmeasured

- **Sustained animation under load.** The 40-bar live mic meter exists in all three builds
  but was not profiled for dropped frames. That is the thing most likely to separate them
  and it needs a human watching it, not a number.
- **Windows.** Cannot be built or felt from this Mac; needs CI.
- **Android.** The decisive test — Flutter ships its own renderer there, Tauri inherits
  Android System WebView. Android Studio is now installed, so this is next.
