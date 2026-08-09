# Platform — what each OS actually permits

**Evidence base:** [`../spikes/strict-mode/FINDINGS.md`](../spikes/strict-mode/FINDINGS.md),
run 2026-08-04. Flutter 3.44.8 / Dart 3.12.2 · macOS 26.5.2 (Tahoe), Xcode 26.6 ·
Android 15 / API 35 on a Pixel 7 AVD, **emulator only** · iOS 26 on an iPhone 17 Pro simulator.
25 screenshots and a persistent event log are in `spikes/strict-mode/evidence/`.

Every claim in this document was executed on a machine, not read in a doc. The spike drove
itself over a loopback control port on `127.0.0.1:8787`, so each result is a recorded command
and its response. Where something was **not** tested, it says so in bold and it says why.
See [Not tested](#8-not-tested) — read that section, it is the load-bearing one.

Decisions are cited as (D7), (D8) etc. and live in [`../FORCE-V2.md`](../FORCE-V2.md).

> **Scope note.** Most of what follows describes *strict mode* — the opt-in daytime
> interruption tier. Strict mode is parked (D12: never auto-offered, lives in settings,
> mentioned once at onboarding). It does not ship in the first version. This document exists
> so that when it does ship, nobody rediscovers any of this at 1am. The
> [lifecycle law](#7-the-lifecycle-law-d8) in §7, by contrast, binds **every** build from
> day one, because that is the thing that silently killed v1.

---

## 1. The one-paragraph version

The wall the user remembers hitting in v1 — *my window can't get above a full-screen app* —
**was never a wall. It was the wrong window.** A second, borderless `NSPanel` covers another
app's full-screen Space instantly, without stealing focus and without a Space-switch
animation. Android's overlay works the same way and has one documented hole (the Settings
app). iOS cannot do any of it and never will, because it is an OS policy rather than a
missing API. And Flutter is not the constraint anywhere: 100% of strict mode is platform
code, but it is the same platform code you would write natively.

---

## 2. Capability matrix

| | macOS | Android | iOS |
|---|---|---|---|
| **Raise self to front, unprompted** | Yes, ~5 lines Swift. **Fails while the screen is locked** | Not the mechanism — use the overlay instead | **Impossible.** No API |
| **Cover another app's full-screen space** | Yes — **only from a separate `NSPanel`** | Yes, except over the Settings app | **Impossible** |
| **Refuse to close / refuse to quit** | Yes, both — **and we deliberately do not** (D7) | n/a | **Impossible** |
| **Launch itself on a schedule while not running** | Yes, LaunchAgent — **requires the sandbox off** | Yes, `BOOT_COMPLETED` + foreground service | **Impossible** |
| **Wake-from-sleep events reaching app code** | `screensDidWake` verified end to end; real `didWake` **not tested** | not tested | n/a — the process is suspended |
| **Non-Dart code required** | ~155 lines Swift | ~165 Kotlin + ~35 XML | ~20 Swift, for a notification |

Windows is absent from this table on purpose. **No strict-mode capability was tested on
Windows at all** — see §8.

---

## 3. Flutter changes nothing about the walls, and nothing about the escapes

This was the question the spike was built to answer, and the answer is clean.

Every capability that exists natively on macOS and Android still exists under Flutter. Every
one that didn't, still doesn't. What Flutter costs is that **not one line of strict mode can
be written in Dart** — when the gate appears, whether it may appear, staying alive long
enough to make it appear, coming back after a reboot: all of that is Swift and Kotlin. What
Flutter buys is that the *gate's pixels* are still Flutter, running on a second engine, on
both macOS and Android.

Call it 200 lines a platform. That number is a **constant, not a Flutter tax.** Those lines
are `NSPanel`, `NSWorkspace`, `launchctl`, `WindowManager`, `TYPE_APPLICATION_OVERLAY`,
foreground services — AppKit and Android framework calls that a native app makes verbatim.
Rewriting Force in Swift and Kotlin tomorrow would not delete a single one of them.

There is a genuine Flutter-specific tax and it is small: **two engine-hosting shims**, about
35 lines each. A `FlutterViewController` inside an `NSPanel` on macOS, a `FlutterView` inside
a `WindowManager` overlay on Android. Plus one trap (§5.3) that cost 20 minutes and is
documented nowhere.

| Capability | Swift | Dart |
|---|---|---|
| MethodChannel plumbing | ~25 | ~10 |
| Raise self to front | ~5 | 0 |
| Gate panel over full-screen (NSPanel + 2nd engine) | ~35 | ~25 |
| Window level / collection behaviour setters | ~15 | 0 |
| Refuse close + refuse quit *(available; not used)* | ~8 | 0 |
| LaunchAgent install / uninstall / status | ~55 | 0 |
| D8 lifecycle observers (9 notifications → 1 channel) | ~35 | ~10 |
| **macOS total** | **~155 Swift** | ~45 Dart |

| Capability | Kotlin / XML | Dart |
|---|---|---|
| Manifest: 8 permissions, `<service>` with `specialUse`, `<receiver>` | ~35 XML | 0 |
| `GateService`: FGS, notification channel, overlay window, 2nd engine, `FlutterView` lifecycle | ~110 Kotlin | 0 |
| `BootReceiver` | ~14 Kotlin | 0 |
| MethodChannel: permission check, deep-link to grant screen, start/stop, show/hide | ~45 Kotlin | ~15 |
| The gate's actual UI | 0 | ~35 Dart |
| **Android total** | **~165 Kotlin + 35 XML** | ~50 Dart |

Dart owns the widget tree inside the overlay and nothing else. That is the same split on both
platforms, and it is ~165 lines, not thousands. It is not a reason to leave Flutter (D13);
it *is* a reason not to expect a package to hand it to you.

---

## 4. macOS

### 4.1 The gate is not the main window

This is the finding that matters most, because it looks like a wall and isn't.

**Control.** Decoy app in a native full-screen Space. Flutter's default window, collection
behaviour `.fullScreenPrimary`, level `.normal`. Passively: `onActiveSpace: false`, invisible.
Call `activate(ignoringOtherApps:)` and it does come forward — by **switching Spaces away from
the full-screen app**, with the animation. That is the half-works answer, and it is worse than
useless for a gate: it yanks you out of whatever you were doing rather than sitting on top of it.

**Six attempts to fix the main window. All six failed.** Every one reported
`isOnActiveSpace: false`:

| Attempt | Result |
|---|---|
| `[.canJoinAllSpaces, .fullScreenAuxiliary]` + level `.floating` (3), passive | not on the Space |
| …plus `orderFrontRegardless()` | not on the Space |
| `[.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]` + level `.screenSaver` (1000) | not on the Space |
| …plus `activate(ignoringOtherApps:)` | becomes frontmost and key — **still not on that Space** |
| …plus `orderOut(nil)` then `orderFrontRegardless()` to force re-assignment | not on the Space |
| …plus `NSApp.setActivationPolicy(.accessory)` at runtime, then re-order | not on the Space |

**Then the control that settles it.** `tools/Overlay.swift` — a hand-written AppKit app,
`LSUIElement`, `.accessory` policy, **identical level and collection behaviour** — overlaid the
decoy's full-screen Space immediately, both as a plain `NSWindow` and as an `NSPanel`. The OS
allows this. The blocker is the window: Flutter's storyboard-created `MainFlutterWindow`,
belonging to a `.regular` app with a Dock tile and a menu bar, is never re-assignable to another
app's full-screen Space.

**So it was Flutter's main window, not macOS.** And the fix is not to fight that window — it is
to stop using it for the gate.

### 4.2 The shape that works

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

Result: `{onActiveSpace: true, isVisible: true, level: 1000, frontmost: Decoy}`, and a full-bleed
Flutter gate sitting over another app's full-screen Space. About 35 lines.

Two consequences, and both are good news:

1. **The gate is a distinct thing you show, not a mode the app window enters.** Separate panel,
   separate `FlutterEngine`, separate Dart entrypoint (`gateMain`). That matches D5 — one gate
   per day, a discrete event — architecturally rather than cosmetically.
2. **Because the panel is non-activating, keyboard focus stays with the app underneath.**
   `frontmost` stayed `Decoy` throughout. The gate is visually total and input-wise polite.
   If the evening beat needs typing (D3: typing available when in public), you must **also**
   activate — a deliberate second step, never a side effect.

### 4.3 Raising to front

`NSApp.activate(ignoringOtherApps: true)` + `makeKeyAndOrderFront` + `orderFrontRegardless`,
fired from a Dart timer while a decoy app owned the screen:
`frontmostBefore: Ghostty → frontmostAfter: strict_mode, isActive: true, isKeyWindow: true`.
Repeated against the decoy, same result. About 5 lines.

It also works **after launchd relaunches the app** — killed at 11:45:37, relaunched 11:46:29,
decoy frontmost at the time, and the app still took focus.

**It does not work while the screen is locked.** Same call, screen locked by display sleep:
`frontBefore=loginwindow frontAfter=loginwindow NSApp.isActive=false`. Twice. There is no gate
on a locked screen — plan around it rather than for it.

### 4.4 kill -TERM always wins, and that is the point

The OS gives you both refusals and both of them work:

| Escape | Blockable? | Evidence |
|---|---|---|
| Red close button / Cmd-W | **Yes** — `windowShouldClose -> false` | `stillVisible: true`, three times |
| Cmd-Q | **Yes** — `applicationShouldTerminate -> .terminateCancel` | `survivedTerminate: true` |
| `kill -TERM` | **No** | process gone immediately |
| Force Quit (Cmd-Opt-Esc), Activity Monitor, `killall`, `kill -9` | **No** — same signal path | by construction |
| Log out / restart / shut down | **NOT TESTED** — docs say `.terminateCancel` blocks these too | would not ship it either way |

`SIGTERM` is the floor and it cannot be blocked. Force Quit and Activity Monitor both go
through it. **That is not a defeat — it is the escape hatch D7 requires, enforced by the OS so
we cannot get it wrong.** The machine is never truly hostage.

**We do not take either refusal.** v1 did. `App.swift:30` carries the comment
`// Gates window close before today's acknowledgement — the "no escape" rule`, and
`App.swift:66` implements it. It produced exactly one outcome: total escape.
A gate blocking a machine you earn money on is a hostage situation with your income attached.

The panel already gives total visual presence without any of that. No close button, no menu
bar, one-tap *Not tonight*, and **every other app alive and killable underneath it.** Insistent
and always escapable, which is the shape D7 asks for.

### 4.5 Launching itself when it isn't running

A user LaunchAgent at `~/Library/LaunchAgents/*.plist` plus
`launchctl bootstrap gui/501`, `StartInterval 60`. App killed 11:23:01, **relaunched by launchd
11:23:52**, `launchedByLaunchd: true`, `launchctl print` reporting `runs = 1, last exit code = 0`.
About 55 lines.

**With the sandbox on — the `flutter create` default — it fails.** The plist is redirected into
`~/Library/Containers/com.example.strictMode/Data/Library/LaunchAgents/` and
`launchctl bootstrap` returns status 5, `Input/output error`.

One good side-finding: `open -a <bundle>` on a live app does **not** spawn a second process
(`processes before=1 after=1`). The v1 `SingleInstance` hazard does not reappear if you launch
through `/usr/bin/open`. Note carefully that this is the *mechanism* v1's lifecycle bug rode in
on — see §7 — but the hand-off itself is not the bug.

### 4.6 Distribution: the cost, and the call that was made on it

**Strict mode forces Force out of the Mac App Store.** The LaunchAgent needs
`com.apple.security.app-sandbox = false`; the App Store requires the sandbox on. There is no
version of this where both are true.

The consequence: Developer ID signing, notarization, direct download, and an updater we write
and host ourselves. That is a product and distribution decision wearing an engineering costume,
and it is caused entirely by one sentence — *the gate can appear when the app isn't running*
(D18, D12).

**The call is made. D21: GitHub + Developer ID, not the App Store.** Force ships openly from its
repository's Releases page, signed and notarised, with Gatekeeper bypass instructions in the
README — the way v1 already distributed. D21's reasoning: keeping the interruption feature that
was the original point of Force matters more than store presence.

---

## 5. Android

Tested on a Pixel 7 AVD, Android 15 / API 35. **No physical device was available.**

### 5.1 The overlay works

`TYPE_APPLICATION_OVERLAY`, sized from `currentWindowMetrics`, hosting a real `FlutterView` on a
second `FlutterEngine` running an `overlayMain` Dart entrypoint. Full-bleed Flutter gate over the
**launcher**, over **Chrome**, over the **Clock** app. It survives HOME followed by BACK.
`dumpsys` confirms `ty=APPLICATION_OVERLAY … appop=SYSTEM_ALERT_WINDOW`, `(1080x2400)`.

Without the permission it refuses correctly rather than failing weirdly:
`showOverlay REFUSED: SYSTEM_ALERT_WINDOW not granted`, returns `false`.

Boot survival works too, on a real `adb reboot`: `BOOT_COMPLETED` received at 11:34:40, foreground
service up at 11:34:41, `isForeground=true foregroundId=1 types=0x40000000`
(`FOREGROUND_SERVICE_TYPE_SPECIAL_USE`) with an ongoing notification. `MY_PACKAGE_REPLACED` re-arms
it after an app update, same second.

Pulling the *activity* to the foreground from the background (`FLAG_ACTIVITY_NEW_TASK |
REORDER_TO_FRONT`) is **not** the mechanism to use. Background-activity-launch restrictions from
Android 10 onward make it unreliable. The overlay is the supported path.

### 5.2 The Settings hole is real

Android force-hides **all** non-system overlays whenever a foreground app has called
`Window.setHideOverlayWindows(true)`. Settings does. So do system permission dialogs.

Verified: launch the overlay, then `am start -a android.settings.SETTINGS`. The overlay vanishes.
`dumpsys` shows `mPolicyVisibility=false … mForceHideNonSystemOverlayWindow=true`.

**The user can always escape the Android gate by opening Settings.** Under D7 that is fine — the
OS is enforcing our own rule for us. But it has one hard consequence for
[`./COPY.md`](./COPY.md): **any product copy promising "you can't get past it" would be a lie.**
Do not write that sentence anywhere.

### 5.3 The FlutterView zero-width trap

A `FlutterView` added to `WindowManager` with `MATCH_PARENT` layout params **never paints.** The
window is created. `dumpsys` shows it. The engine starts and logs `Using the Impeller rendering
backend`. The screen shows nothing, and the only clue is one log line:

```
FlutterRenderer: Width is zero. 0,0
```

The fix is explicit pixel dimensions from `wm.currentWindowMetrics.bounds` **and** wrapping the
`FlutterView` in a plain `FrameLayout`. This cost about 20 minutes of the spike and appears in no
documentation. It is one of only two genuine Flutter-specific costs in this whole document.

---

## 6. iOS

**An iOS app cannot force itself to the foreground. There is no API. There is no entitlement that
grants one. There is no workaround.** Strict mode as designed for macOS does not exist on iOS and
will not.

Tested, not assumed: `UIApplication.shared.open("strictmode://gate")` on itself returned
`canOpenOwnScheme: false` and `open(own scheme) -> false`; a search of UIKit for any activation
API returned `activateAPI: none exists`. Backgrounded, the process is suspended outright — the
native log shows **zero lines** between 11:36:55 and the next `didFinishLaunching` at 11:39:19. A
Dart timer armed before backgrounding never fires. Nothing runs, so nothing can even try.

**This is an OS policy, not a Flutter limitation.** A hand-written Swift app hits the identical
wall in the identical place. There is nothing to port to.

### 6.1 The Screen Time route — what real app-blockers actually use

Opal and its competitors do not force themselves forward. They use
**FamilyControls + ManagedSettings + DeviceActivity**, where **the OS draws the shield, not the
app.** You declare which apps are restricted; the system paints over them when they are opened.

Two costs, one verified and one structural.

**Verified.** `import FamilyControls` compiles and links into a stock Flutter iOS app
(`familyControlsCompiled: true`, build succeeded). Then
`AuthorizationCenter.shared.requestAuthorization(for: .individual)` fails at runtime:

```
NSCocoaErrorDomain Code=4099
"The connection to service named com.apple.FamilyControlsAgent was invalidated from this process."
```

That is the missing `com.apple.developer.family-controls` entitlement. Status stayed
`.notDetermined` before and after. The entitlement is Apple-gated: a request form for
distribution, and a paid account plus a provisioning-profile capability even to develop against.
It was not obtained, so **nothing about DeviceActivity or ManagedSettings shields is verified
here.**

**Structural, and it does not go away with an entitlement.** The shield UI is a
`ShieldConfiguration` app extension. The scheduling runs in a `DeviceActivityMonitor` extension.
Both are separate processes with SwiftUI-only UI. **Flutter can never render a shield.** If Force
ever ships iOS blocking, that surface is hand-written SwiftUI, permanently — a second design
system to keep in sync with [`./DESIGN.md`](./DESIGN.md).

### 6.2 What iOS does offer

- **Local notifications.** `interruptionLevel = .timeSensitive` is the strongest tier available
  without an entitlement and pierces Focus modes if the user allows it. The authorization prompt
  did appear while the app was backgrounded. **Banner delivery was not visually confirmed** — the
  simulator's permission alert cannot be tapped from the CLI.
  **Critical Alerts** (ignores mute and Focus outright) needs
  `com.apple.developer.usernotifications.critical-alerts`, granted by application only. Not
  obtained, not tested.
- **Live Activities.** Persistent presence on the Lock Screen and Dynamic Island, and genuinely
  the closest thing to in-your-face that iOS permits. **Not tested.** Same structural catch: a
  Live Activity is a WidgetKit/SwiftUI extension, so Flutter cannot render into it either.

### 6.3 Net position

On iOS, Force *might* be able to shield apps — that needs an Apple-gated entitlement the spike
could not obtain, plus a permanent SwiftUI surface, and **nothing about it is verified** (§6.1).
What it can definitely do is offer a door into itself. **It cannot interrupt.** It can say
*the day hasn't settled*; it can never make you settle it.

Given D5 (the evening beat is the wall) and D14 (the gate can never live on the web), the honest
position is that **iOS is a companion, not a gate surface.** That happens to be fine: D13 records
that the user has no iPhone and that iOS is a free by-product of choosing Flutter, not a target.

---

## 7. The lifecycle law (D8)

This section binds every build, not just strict mode. It is the thing that killed v1, and it
killed v1 *silently* — nobody noticed for 25 days until someone read a log file.

### 7.1 The v1 bug, quoted

`force-old/Sources/ForceKit/Engine/AcknowledgementGate.swift:31`:

```swift
case .everyLaunch, .onLogin:
    return sessionAcknowledged     // a per-process Bool
```

In those two modes the gate depended **only** on a boolean scoped to the process lifetime. The
failure chain:

Force is running in the background → you acknowledge → `sessionAcknowledged = true` → launchd
fires `open Force.app` → `SingleInstance` hands off to the **live process** instead of starting a
new one → `didBecomeActive` → `recomputeGate()` → the Bool is *still true* → **the gate never
re-locks for as long as that process lives.** Sleep, wake, days passing — nothing recovers it.

**A `Bool` has no clock.**

The 30-second timer at `Store.swift:50` papered over the `daily` and `hourly` modes but could not
help here, because there was no wall-clock fact to re-derive from. (The `flock`-based
single-instance lock was fine — the kernel releases it on process death. That part was never the
problem.)

### 7.2 The law

**Gate state is derived from persisted wall-clock facts. Never from process memory.**

### 7.3 The checklist

Every one of these is a hard requirement, and every one of them is checkable in review.

- [ ] **No process-scoped booleans anywhere in gate logic.** Not one. If a variable answers
      "has the gate been satisfied" and it lives in RAM, it is the v1 bug wearing new clothes.
- [ ] **The logical day is the unit, with a configurable boundary — default 4am, not midnight.**
      A 12:30am evening beat belongs to *that* day, not the next one. Shifts are chaos; the clock
      must match the life it is recording.
- [ ] **Every beat's state is persisted and re-derived from timestamps.**
- [ ] **Recomputation is idempotent.** Running it a hundred times equals running it once.
- [ ] **Recompute on all of:** launch · `didBecomeActive` · `NSWorkspace.didWakeNotification` ·
      `NSCalendarDayChangedNotification` · `significantTimeChangeNotification` · plus a coarse
      timer as a backstop. **v1 observed none of the middle three.**
- [ ] **Survives:** wake from sleep, not just cold boot · restart mid-day after the morning beat ·
      the app sitting in the background for days without ever quitting.

### 7.4 Why this cannot be done in Dart

Proved during the spike, and it is the reason the observers are mandatory rather than nice to have.

`AppLifecycleState` — the only lifecycle signal pure Dart gets — fired `inactive` / `hidden` /
`resumed` on activation changes, and **never fired for screen sleep or wake at all.**

What did work: a real `NSWorkspace` notification crossing into Dart. `pmset displaysleepnow` then
`caffeinate -u` produced `screensDidSleepNotification` and `screensDidWakeNotification`, both
logged natively **and** rendered in the Flutter UI. The delivery path
`NSWorkspace.shared.notificationCenter` observer → `FlutterMethodChannel.invokeMethod` → Dart
handler is verified end to end, five times, timestamped in `evidence/macos-events.log`.

So: **nine native observers, about 35 lines of Swift, forwarded over one channel.** Not optional.
The Android and Windows equivalents of that observer set are not established by this spike.

---

## 8. Not tested

Stated plainly, because a gap you know about is cheap and a gap you assumed away is what v1 died of.

| Gap | Why it wasn't tested | Risk |
|---|---|---|
| **Real `NSWorkspace.didWakeNotification`** — system sleep, the exact event that killed v1 | Needs `sudo pmset schedule wake` to guarantee the Mac wakes again; `sudo -n` fails on this machine and no password could be supplied. `pmset sleepnow` alone would have slept the Mac with nothing able to wake it | **Highest.** The observer is registered on the identical notification centre as the two that were proved, but proved-by-analogy is not proved |
| **Faking that notification** | Posting `NSWorkspaceDidWakeNotification` on `DistributedNotificationCenter` from a separate process **did not reach the observers**. Not a valid simulation, and it is not counted | — |
| **Physical Android hardware** | None available. Emulator only, throughout | Real |
| **OEM battery-killer behaviour** (Xiaomi, Oppo, Vivo, Samsung killing the foreground service) | Untestable on an emulator | **The single biggest real-world risk to the Android gate.** Already flagged in `force-old/plans/roadmap.md` Track 2; nothing in this spike changes it |
| **Play Store policy** | Not submitted | `SYSTEM_ALERT_WINDOW`, `QUERY_ALL_PACKAGES` and the `specialUse` foreground-service type all attract review. The Track-2 `AccessibilityService` blocking design is a harder review still. Unaffected by Flutter either way |
| **The `AccessibilityService` itself** (Track 2: `TYPE_WINDOW_STATE_CHANGED` → blocklist → overlay) | Out of scope | What *is* proved is that the overlay half of that design works, with Flutter UI inside it |
| **Windows, entirely** | Cannot be built or felt from this Mac; needs CI | Windows is in the D13 target set and is the market. **No strict-mode capability has been tested there at all** |
| **iOS notification banner delivery** | The simulator's permission alert cannot be tapped from the CLI and there is no `simctl` verb for it | Low |
| **Live Activities, Critical Alerts, DeviceActivity, ManagedSettings shields** | Entitlements not obtained | Low for now — iOS is a companion (D13) |
| **Blocking log out / restart / shut down** | Not verified, and would not be shipped regardless (D7) | None |

The wake gap has a two-minute manual confirmation attached to it: `evidence/macos-events.log` is
left in place and the app appends on every launch. Run it, close the lid, reopen, and the line is
either there or it isn't. **Do that before building anything on top of `didWakeNotification`.**

---

## 9. Open questions

Genuinely undecided. Not quietly resolved here.

1. **What strict mode actually *does*.** D18 proves what the OS *permits*; nothing decides what
   Force should do with it — interrupt on a schedule, or block chosen apps until the day is
   settled. `FORCE-V2.md` §4 lists this under "genuinely undecided", and notes the Kotlin work
   in `force-old/android` was built for the second one. Those are different products.
2. **The Android and Windows equivalents of the D8 observer set.** macOS has nine named
   notifications. The other two platforms have no equivalent list yet.
3. **Whether the LaunchAgent is needed at all** if the gate is day-close-based rather than
   clock-based (D5). It no longer costs anything at the store — D21 already chose direct
   distribution — but it is still ~55 lines of platform code plus an updater, and it may not be
   a capability the first version needs.

**Not on this list any more:** the distribution channel. D21 settles it — GitHub Releases,
Developer ID, notarised. See [§4.6](#46-distribution-the-cost-and-the-call-that-was-made-on-it).

---

## 10. Re-running any of this

```bash
export PATH="/opt/homebrew/bin:$PATH"
cd /Users/clupa/Documents/projects/force/spikes/strict-mode

# macOS (unsandboxed release build)
flutter build macos --release
open build/macos/Build/Products/Release/strict_mode.app

curl "http://127.0.0.1:8787/info"
curl "http://127.0.0.1:8787/delayedRaise?ms=9000&mode=activateIgnoringOtherApps"   # raise
open -n tools/Decoy.app --args --fullscreen && sleep 7
curl "http://127.0.0.1:8787/showGatePanel?cover=true"                              # the panel
curl "http://127.0.0.1:8787/installLaunchAgent?intervalSeconds=60"
curl "http://127.0.0.1:8787/uninstallLaunchAgent"   # <- always clean this up

# Android
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
~/Library/Android/sdk/emulator/emulator -avd force_spike &
flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell appops set com.example.strict_mode SYSTEM_ALERT_WINDOW allow
adb forward tcp:8788 tcp:8787
curl "http://127.0.0.1:8788/showOverlay"
adb reboot   # then: curl "http://127.0.0.1:8788/readLog"

# iOS
flutter build ios --simulator --debug
curl "http://127.0.0.1:8787/familyControls"
```

> **Trap.** The macOS and iOS builds both bind `127.0.0.1:8787`, and the iOS simulator shares the
> host's loopback. Run one at a time, or the second silently fails to bind and your `curl` hits the
> wrong app. This cost one bad test run during the spike.

**State left on the machine after the spike: none.** LaunchAgent uninstalled and the plist deleted,
emulator killed, `caffeinate` assertion killed, no app left running. The `force_spike` AVD and its
downloaded system image remain installed.

---

## See also

- [`../FORCE-V2.md`](../FORCE-V2.md) — the decision record. D5, D7, D8, D12, D13, D18 and D21
  (distribution) are the ones this document serves.
- [`../spikes/strict-mode/FINDINGS.md`](../spikes/strict-mode/FINDINGS.md) — the raw evidence,
  screenshot by screenshot.
- [`./ARCHITECTURE.md`](./ARCHITECTURE.md) — where the second engine, the entrypoints and the
  persisted day-state actually live in the codebase.
- [`./DATA-MODEL.md`](./DATA-MODEL.md) — the persisted wall-clock facts §7 insists on, and the
  4am logical-day boundary.
- [`./COPY.md`](./COPY.md) — and specifically the sentence we are not allowed to write (§5.2).
- [`../plans/ROADMAP.md`](../plans/ROADMAP.md) — when strict mode returns, and what has to be
  re-verified first.
