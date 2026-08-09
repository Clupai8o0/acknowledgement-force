---
name: force-build
description: Build, run, test, screenshot or profile the Force app on any platform. Use whenever a task touches `flutter run`, `flutter build`, `flutter test`, Gradle, Xcode, the Android SDK/NDK/emulator, the iOS simulator, capturing a screenshot of the app, measuring cold start, or checking for memory leaks. Also use when a build fails with "This tool requires JDK 17", "Xcode installation is incomplete", "command not found: flutter", or a Gradle/JDK version error.
---

# Building and running Force

Force is Flutter (D13), chosen by measurement — `../../../spikes/RESULTS.md`. Everything below
ran on this machine and worked: Flutter 3.44.8 / Dart 3.12.2, macOS 26.5.2, Xcode 26.6, M5 Pro.

## Export this first, in every bash call — shell state does not persist between calls

```bash
export PATH="/opt/homebrew/bin:$PATH"                                       # flutter lives here
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
```

- **PATH** — `flutter` is a Homebrew cask symlink. Without it: `command not found`.
- **JAVA_HOME for anything Gradle** — the system `java` is **1.8.0_491**; every Gradle task under
  it dies with `This tool requires JDK 17 or later`. Android Studio's bundled JBR is the only
  usable JDK here. Set it even for `flutter doctor`.

## Per platform

```bash
# macOS — the primary dev surface
flutter run -d macos                                   # debug, hot reload
flutter build macos --release && open build/macos/Build/Products/Release/<app>.app

# iOS simulator — a free by-product of Flutter, NOT a target (D13: the user has no iPhone)
xcrun simctl list devices available | grep iPhone      # get the UDID
xcrun simctl boot 9DC0D285-C3C1-4928-AB56-2598F36BAE87 # iPhone 17 Pro, already created
open -a Simulator && flutter run -d 9DC0D285-C3C1-4928-AB56-2598F36BAE87

# Android — the user's phone is Android, so this is a real target
$ANDROID_HOME/emulator/emulator -avd force_spike &     # AVD exists: Pixel 7, API 35
flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release                            # ~39 MB, builds first try

flutter test && flutter analyze                        # these two need only the PATH export
# Windows — cannot be built or felt from this Mac. GitHub Actions only.
```

## Toolchain facts, discovered the hard way

- **Full Xcode is required for Flutter macOS *and* iOS.** Command Line Tools alone fail with
  `Xcode installation is incomplete`. Confirm: `xcode-select -p` must print a path inside
  `/Applications/Xcode.app`. SwiftUI and Tauri build on CLT; Flutter does not. A fresh install is
  ~15 GB via the App Store and needs the user's Apple ID — not automatable.
- **Android SDK: `~/Library/Android/sdk`.** Installed: platforms 35/36/37, build-tools 36.0.0,
  **NDK 27.0.12077973** (plus 28.2.13676358), cmake, platform-tools, emulator.
- **cmdline-tools had to be installed separately** — Android Studio ships without it. Settings →
  Languages & Frameworks → Android SDK → SDK Tools → *Android SDK Command-line Tools (latest)*.
  Now at `$ANDROID_HOME/cmdline-tools/latest`.
- **Accept licences or every Gradle build fails.** With `JAVA_HOME` set:
  `$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses` (or `flutter doctor --android-licenses`).
- Flutter generates **Gradle 9.1.0**, which the bundled JDK is happy with. Do not downgrade the
  wrapper — that was Tauri's failure mode, not ours.
- `android/local.properties` carries `sdk.dir` and `flutter.sdk`, is gitignored, and regenerates.
  If a build cannot find the SDK, check that file before debugging anything else.
- **`--dart-define` booleans accept only literal `true`/`false`.** `FOO=1` evaluates to `false`
  with no warning. It cost one wasted 4-minute soak.
- **Variable fonts instantiate the fvar *default* instance.** Fraunces defaults to `wght 900 /
  opsz 9` — Black at caption optical size. Pin both on every style or the type is silently wrong.

## Screenshots — read this before capturing anything

**The trap: this machine is driven with three displays, so a plain `screencapture out.png` often
captures a screen the app is not on and hands back a perfectly valid picture of nothing.**
Flutter's macOS window also does not reliably raise to the front, so "it's frontmost" is unsafe.

```bash
screencapture -x -D 1 shot.png            # main display; -D 2, -D 3 for the others
screencapture -x -l <windowid> shot.png   # exact window, whichever display it is on
screencapture -x -R x,y,w,h shot.png      # explicit rect
xcrun simctl io <udid> screenshot shot.png    # simulator — no trap
adb exec-out screencap -p > shot.png          # Android — no trap
```

Get a window id by having the app print its own, as the spike did inside
`MainFlutterWindow.awakeFromNib` behind an env var: `print("WINDOW_ID=\(self.windowNumber)")`.
Do **not** reach for `osascript`/System Events (Apple-events permission is denied here) or pyobjc
`Quartz` (not installed in any python3 here).

## Measuring cold start honestly

`t0` must be the kernel's record of `exec`, never a timestamp taken inside Dart — otherwise dyld,
engine bring-up and the Dart VM snapshot load fall outside the number and the result flatters
Flutter. Working code: `../../../spikes/flutter-gate/macos/Runner/MainFlutterWindow.swift`.

- **t0**: `sysctl` `[CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]` → `kinfo_proc.kp_proc.p_starttime`.
- **t1**: Dart calls back over a `MethodChannel` — `firstFrame` from
  `SchedulerBinding.addPostFrameCallback`, `firstPaint` from the first `addTimingsCallback`
  (rasterised, handed to the compositor). Report `firstPaint`.
- Median of 5 release runs, nothing else running. Bar to hold: **208 ms** (SwiftUI 212, Tauri 458).

## Memory soak — six minutes minimum, non-negotiable

**A 3-minute sample reports a leak that is not there.** In the showcase spike the 70 s → 240 s
window climbed monotonically 305 → 325 MB with no GC drop: 7 MB/min, exactly the shape of a
leak. It was the Dart heap walking toward its next *major* GC and it did not resolve until
**350 s**. Both runs then plateaued *below* their starting RSS.

```bash
while :; do ps -o rss= -p <pid>; sleep 10; done     # ≥ 6 min, ideally 6:30
```

Read the floor of the sawtooth, not the peaks: rising floor = leak, flat or falling = plateau.
Debug/simulator numbers include the JIT and VM service; never quote them as product figures. Full
run: `../../../spikes/flutter-showcase/NOTES.md`.

## Where strict mode lives

None of it is Dart (D18). macOS: ~155 lines Swift, and the gate is a second `NSPanel` on a second
`FlutterEngine`, never `MainFlutterWindow`. Android: ~165 Kotlin + ~35 XML. The D8 lifecycle
observers are Swift too — `AppLifecycleState` never fires for sleep/wake. Re-run commands:
`../../../spikes/strict-mode/FINDINGS.md` §5. See also `../../../docs/PLATFORM.md`,
`../../../docs/ARCHITECTURE.md`, `../../../FORCE-V2.md`.
