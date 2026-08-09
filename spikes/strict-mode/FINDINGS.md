# Strict mode — what Flutter can and cannot do

**Spike date:** 2026-08-04 · **Flutter 3.44.8** (Dart 3.12.2) · **macOS 26.5.2 (Tahoe)**, Xcode 26.6 ·
**Android 15 / API 35** (Pixel 7 AVD, emulator only) · **iOS 26** (iPhone 17 Pro simulator)

Everything below was executed. Nothing here is inferred from documentation unless it is
explicitly labelled **NOT TESTED**. Screenshots and the persistent event log are in
`evidence/`. The whole harness is driven over a loopback HTTP control port the Dart side
opens on `127.0.0.1:8787`, so every result is a recorded command + response, not a claim.

---

## 0. The headline

**Flutter changes nothing about the walls. It changes nothing about the escapes either.**
Every capability that exists on macOS and Android still exists; every one that didn't, still
doesn't. What Flutter costs you is that **100% of strict mode is platform code** — there is not
one line of this that Dart can do. What it buys you is that the *gate's UI* is still Flutter,
in a second engine, on both macOS and Android.

The one wall the user probably remembers hitting — *"my window can't get above a full-screen
app"* — **is not a wall.** It was a wrong window. See Q2.

| | macOS | Android | iOS |
|---|---|---|---|
| Raise self to front on a timer | Works (Swift) | Overlay instead of activity | Impossible |
| Cover another app's full-screen space | Works — but only from a second NSPanel | Works (except Settings) | Impossible |
| Refuse to close / refuse to quit | Works (and you must not use it) | n/a | Impossible |
| Launch itself on a schedule when not running | Works — **kills Mac App Store distribution** | Works (boot + FGS) | Impossible |
| Survive & re-fire after sleep | Partially verified (see Q5) | not tested | Impossible |
| Non-Dart code required | **~155 lines Swift** | **~165 lines Kotlin + 35 XML** | ~20 lines Swift, for a notification |

---

## 1. macOS

Source: `macos/Runner/StrictMode.swift` (442 lines as written for this spike — that includes the
test scaffolding; the minimal production subset is broken out per row below),
`macos/Runner/MainFlutterWindow.swift`, `macos/Runner/AppDelegate.swift`.
Control apps for the tests: `tools/Decoy.swift`, `tools/Overlay.swift`.

| # | Capability | Verdict | Test run | Result | Non-Dart cost |
|---|---|---|---|---|---|
| 1 | Raise self to front, unprompted, on a timer | **Works with platform code** | Dart `Timer(9s)` → `NSApp.activate(ignoringOtherApps:true)` + `makeKeyAndOrderFront` + `orderFrontRegardless`, while a decoy app owned the screen | `frontmostBefore: Ghostty → frontmostAfter: strict_mode, isActive: true, isKeyWindow: true`. Repeated against the decoy: `frontmostBefore: Decoy → strict_mode`. `evidence/q1-a-decoy-is-frontmost.png`, `q1-b-after-raise.png` | **~5 lines Swift** |
| 1b | …after the app was relaunched by launchd | **Works** | killed the app 11:45:37, launchd fired 11:46:29, decoy was frontmost at the time | `frontmost: strict_mode, selfIsActive: true, isKeyWindow: true` — `evidence/q4-launchd-relaunch-takes-focus.png` | included above |
| 1c | …while the screen is locked | **Fails** | same call, screen locked by display sleep | `frontBefore=loginwindow frontAfter=loginwindow NSApp.isActive=false` — twice, `evidence/macos-events.log` 11:25:08 and 11:25:46 | — |
| 2 | Show above a full-screen app / on all Spaces | **Works, but only in a separate NSPanel** | see the ladder below | `onActiveSpace: true`, other app's full-screen Space fully covered, and `frontmost` stayed `Decoy` — no activation, no Space switch. `evidence/q2-l-flutter-gate-panel-over-fullscreen.png` | **~35 lines Swift + 1 Dart entrypoint** |
| 3 | Refuse to close (red button / Cmd-W) | **Works** | `windowShouldClose -> false`, then `window.performClose(nil)` x3 | `stillVisible: true` each time, process alive. Baseline with `refuseClose=false`: window closed and the app quit | **~4 lines Swift** |
| 3b | Refuse to quit (Cmd-Q) | **Works** | `applicationShouldTerminate -> .terminateCancel`, then `NSApp.terminate(nil)` | `survivedTerminate: true`, process alive | **~4 lines Swift** |
| 3c | Can the user always still escape? | **Yes — at the signal boundary** | `kill -TERM <pid>` while refusing both close and quit | `SIGTERM: process GONE`. Force Quit (Cmd-Opt-Esc), Activity Monitor, `killall`, `kill -9` all go through this path and cannot be blocked | — |
| 4 | Launch itself when not running (LaunchAgent) | **Works — only unsandboxed** | write `~/Library/LaunchAgents/*.plist` + `launchctl bootstrap gui/501`, `StartInterval 60`, then kill the app | app killed 11:23:01 → **relaunched by launchd 11:23:52**, `launchedByLaunchd: true`. `launchctl print`: `runs = 1, last exit code = 0` | **~55 lines Swift** |
| 4b | …with the sandbox on (default `flutter create`) | **Fails** | same call, `com.apple.security.app-sandbox = true` | plist redirected to `~/Library/Containers/com.example.strictMode/Data/Library/LaunchAgents/`; `launchctl bootstrap` → **status 5, "Input/output error"** | — |
| 4c | Does `open -a` spawn a 2nd process while running? | **No** | `open -a <bundle>` with the app live | `processes before=1 after=1` — the v1 `SingleInstance` hazard does not reappear if you launch via `/usr/bin/open` | — |
| 5 | Survive & re-fire after wake | **Partially verified** | real OS display sleep/wake round trip: `pmset displaysleepnow` then `caffeinate -u` | `NSWorkspace.screensDidWakeNotification` / `screensDidSleepNotification` reached **Dart** — green `NATIVE EVENT` lines in `evidence/q5-wake-and-launchd-in-dart.png`, persisted at 11:24:34, 11:24:45, 11:25:26, 11:25:38, 11:25:59 in `evidence/macos-events.log` | **~35 lines Swift** for all 9 observers |
| 5b | `NSWorkspace.didWakeNotification` (real *system* sleep) | **NOT TESTED — see below** | — | — | observer registered; same notification centre as 5 |

### Q2 in detail — the important one

This is the finding that matters most, because it looks like a wall and isn't.

**Control (default Flutter window).** Decoy app in a native full-screen Space, Flutter window at
`collectionBehavior = .fullScreenPrimary (128)`, `level = .normal`:

- Passive: `onActiveSpace: false`, invisible (`q2-a`).
- After `activate(ignoringOtherApps:)`: it *does* come forward — by **switching Spaces away from
  the full-screen app** (`q2-b`). That is the half-works answer. It interrupts, but it yanks
  you out of whatever you were full-screened in, with the Space-switch animation.

**Every attempt to fix it on `MainFlutterWindow` failed.** All of these left `isOnActiveSpace: false`:

| Attempt | Result |
|---|---|
| `[.canJoinAllSpaces, .fullScreenAuxiliary]` + `level .floating (3)`, passive | `q2-c` — not on the Space |
| …+ `orderFrontRegardless()` | `q2-d` — not on the Space |
| `[.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]` + `level .screenSaver (1000)` | `q2-e` — not on the Space |
| …+ `activate(ignoringOtherApps:)` | `q2-f` — app becomes frontmost/key, **still not on that Space** |
| …+ `orderOut(nil)` then `orderFrontRegardless()` (force re-assignment) | `q2-g` — not on the Space |
| …+ `NSApp.setActivationPolicy(.accessory)` at runtime, then re-order | `q2-j`, `q2-k` — not on the Space |

**Then I checked whether it was macOS or Flutter.** `tools/Overlay.swift` — a hand-written AppKit
app, `LSUIElement`, `.accessory` policy, same level and collection behaviour — overlays the
decoy's full-screen Space immediately, **both as a plain `NSWindow` and as an `NSPanel`**
(`q2-h`, `q2-i`). So the OS allows it. The blocker is the *window*: Flutter's storyboard-created
`MainFlutterWindow`, belonging to a `.regular` app with a Dock tile and a menu bar, is never
re-assignable to another app's full-screen Space.

**The shape that works** (`showGatePanel` in `StrictMode.swift`, ~35 lines):

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

Result: `{onActiveSpace: true, isVisible: true, level: 1000, frontmost: Decoy}` and a full-bleed
Flutter gate over another app's full-screen Space — `evidence/q2-l-flutter-gate-panel-over-fullscreen.png`.

**Two consequences for Force:**

1. **The gate is not the main window.** It's a second, borderless, non-activating NSPanel with
   its own Flutter engine and its own Dart entrypoint. That is also cleaner for D5 — the gate is
   a distinct thing you show, not a mode the app window enters.
2. **Because the panel is non-activating, keyboard focus stays with the app underneath**
   (`frontmost` stayed `Decoy` throughout). The gate is visually total and input-wise polite.
   If the evening beat needs typing (D3's "typing available when in public"), you must
   *also* activate — a deliberate second step, not a side effect.

### Q3 in detail — where the OS lets you stop (D7)

Verified boundary, in order of increasing force:

| Escape | Blockable? | Evidence |
|---|---|---|
| Red close button / Cmd-W | **Yes** — `windowShouldClose -> false` | `stillVisible: true` x3 |
| Cmd-Q | **Yes** — `applicationShouldTerminate -> .terminateCancel` | `survivedTerminate: true` |
| `kill -TERM` | **No** | process gone immediately |
| Force Quit (Cmd-Opt-Esc), Activity Monitor, `kill -9` | **No** — same signal path | by construction |
| Log out / restart / shut down | **NOT TESTED.** AppKit docs say `.terminateCancel` blocks these too and the system shows a "prevented logout" dialog. I did not verify it and would not ship it | — |

**Recommendation, consistent with D7 and with what killed v1:** do not use either refusal. The
insistent-but-escapable shape you actually want is the one Q2 produced — a gate panel with no
close button and no menu bar, a one-tap *Not tonight*, and **every other app still alive and
killable underneath it**. The panel proves you can be visually total without ever taking the
machine hostage. `windowShouldClose -> false` is available; it is the thing that got v1 deleted;
leave it out.

### Q5 in detail — what I could and could not prove

**Proved.** A real OS-generated `NSWorkspace` notification crossed into Dart. `pmset
displaysleepnow` → `caffeinate -u` produced `screensDidSleepNotification` and
`screensDidWakeNotification`, both logged natively *and* rendered as `NATIVE EVENT` lines in the
Flutter UI (`evidence/q5-wake-and-launchd-in-dart.png`). The delivery path — `NSWorkspace.shared
.notificationCenter` observer → `FlutterMethodChannel.invokeMethod` → Dart handler — is
therefore verified end to end.

**Also proved, and it is the D8 point:** `AppLifecycleState`, the only lifecycle signal pure Dart
gets, fired `inactive` / `hidden` / `resumed` on activation changes and **never fired for the
screen sleep or wake events at all**. D8 cannot be satisfied in Dart. The nine NSWorkspace /
NSNotificationCenter observers are mandatory platform code.

**Not proved.** `NSWorkspace.didWakeNotification` — the real system-sleep one, the exact event
that killed v1. Triggering it requires `sudo pmset schedule wake` (to guarantee the machine wakes
again) and `sudo -n` fails on this machine — a password is required and I cannot supply one.
`pmset sleepnow` alone would have put the Mac to sleep with nothing able to wake it. I also tried
faking it by posting `NSWorkspaceDidWakeNotification` on `DistributedNotificationCenter` from a
separate process (`tools/PostWake.swift`): **it did not reach the observers**, so that is not a
valid simulation and I am not counting it.

The observer is registered on the identical notification centre as the two I did prove.
`evidence/macos-events.log` is left in place and the app appends to it on every launch — run the
app, close the lid, reopen, and the line will be there. That is a two-minute confirmation the
user can do; I could not.

### macOS distribution consequence — the real cost

**Strict mode forces the app out of the Mac App Store.** The LaunchAgent needs
`com.apple.security.app-sandbox = false` (Q4b: bootstrap fails with I/O error under the sandbox).
That means Developer ID + notarization, direct download, and your own updater. This is a
product/distribution decision, not an engineering one, and it is caused entirely by "the gate can
appear when the app isn't running".

### macOS — minimal production Swift, by capability

| Capability | Swift lines (minimal) | Dart lines |
|---|---|---|
| MethodChannel plumbing | ~25 | ~10 |
| Raise self to front | ~5 | 0 |
| Gate panel over full-screen (NSPanel + 2nd engine) | ~35 | ~25 (the gate widget + entrypoint) |
| Window level / collection behaviour setters | ~15 | 0 |
| Refuse close + refuse quit (if ever used) | ~8 | 0 |
| LaunchAgent install / uninstall / status | ~55 | 0 |
| D8 lifecycle observers (9 notifications → 1 channel) | ~35 | ~10 (the recompute call) |
| **Total** | **~155 Swift** | ~45 Dart |

---

## 2. Android

Source: `android/app/src/main/kotlin/com/example/strict_mode/GateService.kt` (172),
`MainActivity.kt` (93), `BootReceiver.kt` (14), `AndroidManifest.xml` (75).
Tested on a **Pixel 7 AVD, Android 15 (API 35)**. **No physical device was available** — see the
"not tested" list.

| # | Capability | Verdict | Test run | Result | Non-Dart cost |
|---|---|---|---|---|---|
| 6 | Draw over other apps | **Works with platform code** | `TYPE_APPLICATION_OVERLAY` window sized from `currentWindowMetrics`, hosting a real `FlutterView` on a **second `FlutterEngine`** running the `overlayMain` Dart entrypoint | Full-bleed Flutter gate over the **launcher** (`q6-a`), **Chrome** (`q6-d`), **Clock** (`q6-e`); survives HOME then BACK (`q6-c`). `dumpsys`: `ty=APPLICATION_OVERLAY … appop=SYSTEM_ALERT_WINDOW`, `(1080x2400)` | ~110 Kotlin |
| 6b | Without the permission | **Correctly refused** | `showOverlay` with `Settings.canDrawOverlays == false` | `showOverlay REFUSED: SYSTEM_ALERT_WINDOW not granted`, returned `false` | — |
| 6c | Over the **Settings** app | **The OS hides it** | same overlay, `am start -a android.settings.SETTINGS` | Overlay vanishes (`q6-b`). `dumpsys`: `mPolicyVisibility=false … mForceHideNonSystemOverlayWindow=true` | — |
| 6d | Pull the *activity* to the foreground from the background | Not the mechanism to use | `Intent … FLAG_ACTIVITY_NEW_TASK\|REORDER_TO_FRONT` | Background-activity-launch restrictions (Android 10+) make this unreliable; the overlay is the supported path and is what the tests use | — |
| 7 | Start on boot + foreground service | **Works** | real `adb reboot` at 11:34:21 | `BootReceiver got android.intent.action.BOOT_COMPLETED` **11:34:40**; `service onCreate (foreground started)` **11:34:41**. `dumpsys activity services`: `isForeground=true foregroundId=1 types=0x40000000` (`FOREGROUND_SERVICE_TYPE_SPECIAL_USE`) with an `ONGOING_EVENT\|FOREGROUND_SERVICE` notification | ~14 Kotlin + manifest |
| 7b | Re-arm after app update | **Works** | `MY_PACKAGE_REPLACED` on reinstall | `BootReceiver got android.intent.action.MY_PACKAGE_REPLACED` at 11:31:17, service up 11:31:17 | included |

### Q6 — the two things that will cost you a day if you do not know them

1. **`mForceHideNonSystemOverlayWindow`.** Android force-hides *all* non-system overlays whenever
   a foreground app has called `Window.setHideOverlayWindows(true)`. Settings does. So do system
   permission dialogs. **The user can always escape your gate by opening Settings.** For Force
   this is fine — it is exactly D7's "never hard-lock" — but it does mean the Android gate is not
   universal, and any product copy promising "you cannot get past it" would be a lie.
2. **`FlutterRenderer: Width is zero. 0,0`.** A `FlutterView` added to `WindowManager` with
   `MATCH_PARENT` layout params never paints. The window is created, `dumpsys` shows it, the
   engine starts ("Using the Impeller rendering backend"), and the screen shows nothing. The fix
   is explicit pixels from `wm.currentWindowMetrics.bounds` **and** wrapping the `FlutterView` in
   a plain `FrameLayout`. This cost about 20 minutes of this spike and it is not in any doc.

### Q8 — how much of Android needs Kotlin? Quantified.

| Capability | Kotlin/XML | Dart |
|---|---|---|
| Manifest: 8 permissions, `<service>` with `specialUse` + subtype property, `<receiver>` | **~35 XML** | 0 |
| `GateService`: foreground service, notification channel, overlay window, second `FlutterEngine`, `FlutterView` lifecycle | **~110 Kotlin** | 0 |
| `BootReceiver` | **~14 Kotlin** | 0 |
| MethodChannel: permission check, deep-link to the grant screen, start/stop, show/hide | **~45 Kotlin** | ~15 |
| The gate's actual UI | 0 | **~35 Dart** (`overlayMain`) |
| **Total** | **~165 Kotlin + 35 XML** | ~50 Dart |

**The honest read:** Flutter's ceiling on Android for this feature is "the pixels". Every
decision — when the gate appears, whether it may appear, staying alive to make it appear, coming
back after a reboot — is Kotlin. Dart owns the widget tree inside the overlay and nothing else.
That is the same split as macOS, and it is ~165 lines, not thousands. It is not a reason to leave
Flutter; it *is* a reason not to expect a package to hand it to you. (`flutter_overlay_window`
would replace roughly the `GateService` half; writing it yourself is ~2 hours and you own the
lifecycle, which for D8 you want to.)

### Android — NOT TESTED

- **No physical device was connected**, and none was available. Emulator only.
- **OEM background-kill behaviour** (Xiaomi / Oppo / Vivo / Samsung battery optimisation killing
  the foreground service) — untestable here, and it is the single biggest real-world risk to Q7.
  `force-old/plans/roadmap.md` Track 2 already flagged this; nothing in this spike changes it.
- **Play Store policy.** `SYSTEM_ALERT_WINDOW`, `QUERY_ALL_PACKAGES`, and the `specialUse`
  foreground-service type all attract review. The Track-2 `AccessibilityService` app-blocking
  design is a harder review still. Untested and unaffected by Flutter either way.
- **The AccessibilityService itself** (Track 2's `TYPE_WINDOW_STATE_CHANGED` → blocklist → overlay)
  was out of scope. What this spike proves is that the *overlay half* of that design works, and
  works with Flutter UI inside it.

---

## 3. iOS — the blunt version

Source: `ios/Runner/AppDelegate.swift` (152 lines). iPhone 17 Pro simulator, iOS 26.

**An iOS app cannot force itself to the foreground. There is no API. There is no entitlement that
grants one. There is no workaround.** Strict mode as designed for macOS does not exist on iOS and
will not.

| # | Capability | Verdict | Test run | Result |
|---|---|---|---|---|
| 9a | Raise self to front | **Impossible** | `tryRaiseToFront`: `UIApplication.shared.open("strictmode://gate")` on itself; searched UIKit for an activation API | `canOpenOwnScheme: false`, `open(own scheme) -> false`, `activateAPI: none exists on UIKit`. Logged natively at 11:36:55 |
| 9b | Run code on a timer while backgrounded | **Impossible** | armed a Dart timer, then backgrounded via `simctl launch com.apple.Preferences` | Process is suspended; the native log shows **zero lines** between 11:36:55 and the next `didFinishLaunching` at 11:39:19. Nothing runs, so nothing can even try |
| 9c | Local notification | **Available** (the only lever) | `UNTimeIntervalNotificationTrigger`, `interruptionLevel = .timeSensitive` | Authorization request fired and the system prompt appeared while the app was backgrounded — `evidence/q9-b-notification-while-backgrounded.png`. **Banner delivery not visually confirmed**: the simulator's permission alert cannot be tapped from the CLI and there is no `simctl` verb for it |
| 9d | FamilyControls / Screen Time | **Needs an Apple-gated entitlement** | `import FamilyControls` compiled and linked into a stock Flutter iOS app (`familyControlsCompiled: true`, build succeeded), then `AuthorizationCenter.shared.requestAuthorization(for: .individual)` | **FAILED:** `NSCocoaErrorDomain Code=4099 "The connection to service named com.apple.FamilyControlsAgent was invalidated from this process."` — i.e. missing `com.apple.developer.family-controls`. Status stayed `.notDetermined` (0) before and after |

### What iOS actually offers, and what it costs

- **Local notifications.** `.timeSensitive` interruption level is the strongest tier available
  without an entitlement — it pierces Focus modes if the user allows it. **Critical Alerts**
  (ignores mute and Focus outright) needs `com.apple.developer.usernotifications.critical-alerts`,
  which Apple grants by application only. Not obtained, not tested.
- **Live Activities.** Persistent presence on the Lock Screen and Dynamic Island. Genuinely the
  closest thing to "in your face" that iOS permits, and a real option for an unsettled day.
  **Not tested in this spike.** Note: a Live Activity is a **WidgetKit/SwiftUI extension** —
  Flutter cannot render into it. That UI would be hand-written SwiftUI, a second design system.
- **FamilyControls / DeviceActivity / ManagedSettings.** These *can* shield other apps — this is
  the API Opal and friends use. Two hard costs, one verified and one structural:
  1. **Verified:** without `com.apple.developer.family-controls`, `requestAuthorization` fails at
     runtime with XPC 4099. The entitlement is restricted — a request form to Apple for
     distribution, and a paid account + provisioning-profile capability even for development.
     I did not obtain it, so **nothing about DeviceActivity or ManagedSettings shields is
     verified here.**
  2. **Structural:** the shield UI is a `ShieldConfiguration` app extension and the scheduling
     runs in a `DeviceActivityMonitor` extension. Both are separate processes with SwiftUI-only
     UI. **Flutter cannot render a shield.** If Force ever ships iOS blocking, that surface is
     hand-written Swift, permanently.

### iOS verdict for Force

iOS gets **notification + Live Activity**, and that is it. Given D5 ("one gate per day, and the
evening beat is the wall") and D14 ("the gate can never live on the web"), the honest position is
that **iOS is a companion, not a gate surface** — it can say *the day hasn't settled*, it can
never make you settle it. That happens to be fine: FORCE-V2 D13 already records that the user has
no iPhone and that iOS is a free by-product of the Flutter choice, not a target.

---

## 4. What this means for the FORCE-V2 decisions

- **D5 (two beats, one gate).** The macOS gate should be the NSPanel from Q2, not the main window.
  It covers full-screen apps, does not switch Spaces, does not steal keyboard focus, and gets its
  own Flutter engine and Dart entrypoint. That separation is architectural, not cosmetic.
- **D7 (never hard-lock).** The OS gives you `windowShouldClose -> false` and `.terminateCancel`
  and both work. **Do not take them.** `SIGTERM` is the floor and it cannot be blocked, so the
  machine is never truly hostage — but the *feeling* of being trapped is what deleted v1, and the
  panel already gives you total visual presence without it. On Android the OS enforces the escape
  for you: open Settings and the overlay disappears.
- **D8 (lifecycle law).** `AppLifecycleState` is not enough — proved. Nine native observers,
  ~35 lines of Swift, forwarded over one channel. And the one that mattered most,
  `didWakeNotification`, is the one I could not trigger without sudo; **verify it by hand before
  building on it.** The persistent log at `evidence/macos-events.log` is already wired for that.
- **D12 (strict mode is opt-in, never auto-offered).** It also now carries a distribution cost:
  turning it on means shipping unsandboxed, i.e. off the Mac App Store. Worth knowing before it is
  a setting.
- **D13 (Flutter).** Nothing here overturns it. Flutter costs you ~155 lines of Swift and ~165 of
  Kotlin for this feature, which is what native would have cost you *anyway* — those are AppKit
  and Android framework calls, not Flutter workarounds. The only genuine Flutter-specific tax is
  the two engine-hosting shims (`FlutterViewController` in an `NSPanel`, `FlutterView` in a
  `WindowManager` overlay), ~35 lines each, plus the `Width is zero` trap on Android.

---

## 5. How to re-run any of this

```bash
export PATH="/opt/homebrew/bin:$PATH"
cd /Users/clupa/Documents/projects/force/spikes/strict-mode

# macOS (unsandboxed release build)
flutter build macos --release
open build/macos/Build/Products/Release/strict_mode.app

curl "http://127.0.0.1:8787/info"
curl "http://127.0.0.1:8787/delayedRaise?ms=9000&mode=activateIgnoringOtherApps"   # Q1
open -n tools/Decoy.app --args --fullscreen && sleep 7
curl "http://127.0.0.1:8787/showGatePanel?cover=true"                              # Q2
curl "http://127.0.0.1:8787/setRefuseClose?value=true"                             # Q3
curl "http://127.0.0.1:8787/simulateUserClose"
curl "http://127.0.0.1:8787/installLaunchAgent?intervalSeconds=60"                 # Q4
curl "http://127.0.0.1:8787/uninstallLaunchAgent"   # <- always clean this up

# Android
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
~/Library/Android/sdk/emulator/emulator -avd force_spike &
flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell appops set com.example.strict_mode SYSTEM_ALERT_WINDOW allow
adb shell am start -n com.example.strict_mode/.MainActivity
adb forward tcp:8788 tcp:8787
curl "http://127.0.0.1:8788/showOverlay"                                           # Q6
adb reboot   # then: curl "http://127.0.0.1:8788/readLog"                          # Q7

# iOS
flutter build ios --simulator --debug
xcrun simctl install 9DC0D285-C3C1-4928-AB56-2598F36BAE87 build/ios/iphonesimulator/Runner.app
xcrun simctl launch  9DC0D285-C3C1-4928-AB56-2598F36BAE87 com.example.strictMode
curl "http://127.0.0.1:8787/familyControls"                                        # Q9
```

> The macOS and iOS builds both bind `127.0.0.1:8787`, and the iOS simulator shares the host's
> loopback — only run one at a time or the second silently fails to bind and your `curl` hits the
> wrong app. This cost one bad test run during the spike.

**State left on the machine:** none. The LaunchAgent was uninstalled
(`launchctl print` → not found, plist deleted), the emulator was killed, the `caffeinate`
assertion was killed, and no app is left running. The AVD `force_spike` and the downloaded
`system-images;android-35;google_apis;arm64-v8a` remain installed.
