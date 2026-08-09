// A controllable decoy app used as the "other app" in the macOS strict-mode tests.
// Build:  see tools/build-decoy.sh
// Usage:  Decoy.app --fullscreen   (enters a real native full-screen Space)
//         Decoy.app               (plain window at a fixed rect)
// It keeps itself active and prints the frontmost app once a second, so the test
// harness can tell exactly who owns the screen without needing AppleScript
// (Automation permission is not granted to the shell here).

import Cocoa

final class Delegate: NSObject, NSApplicationDelegate {
  var window: NSWindow!
  let wantFullscreen = CommandLine.arguments.contains("--fullscreen")

  func applicationDidFinishLaunching(_ n: Notification) {
    let rect = NSRect(x: 60, y: 120, width: 980, height: 660)
    window = NSWindow(contentRect: rect,
                      styleMask: [.titled, .closable, .resizable, .miniaturizable],
                      backing: .buffered, defer: false)
    window.title = "DECOY"
    window.backgroundColor = NSColor(calibratedRed: 0.75, green: 0.05, blue: 0.45, alpha: 1)
    window.collectionBehavior = [.fullScreenPrimary]

    let label = NSTextField(labelWithString:
      wantFullscreen
        ? "DECOY — NATIVE FULL SCREEN\nOwn Space. Menu bar hidden.\nCan the Flutter gate appear over this?"
        : "DECOY — I AM THE FRONTMOST APP\nThe Flutter gate must raise itself over me, unprompted.")
    label.font = NSFont.boldSystemFont(ofSize: 30)
    label.textColor = .white
    label.alignment = .center
    label.maximumNumberOfLines = 0
    label.frame = NSRect(x: 40, y: rect.height / 2 - 90, width: rect.width - 80, height: 180)
    label.autoresizingMask = [.width, .minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
    window.contentView?.addSubview(label)

    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    if wantFullscreen {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
        self?.window.toggleFullScreen(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    }

    // Keep-alive reporter.
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      let fa = NSWorkspace.shared.frontmostApplication?.localizedName ?? "?"
      let fs = self?.window.styleMask.contains(.fullScreen) ?? false
      FileHandle.standardOutput.write(
        "frontmost=\(fa) decoyActive=\(NSApp.isActive) decoyFullScreen=\(fs)\n".data(using: .utf8)!)
    }
  }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let d = Delegate()
app.delegate = d
app.run()
