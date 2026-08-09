// Native AppKit control for Q2: can *any* AppKit window overlay ANOTHER app's
// native full-screen Space? If a hand-written NSWindow/NSPanel can't either, the
// limitation is macOS, not Flutter — that distinction decides the architecture.
//
//   Overlay.app --window   plain NSWindow  (what Flutter's MainFlutterWindow is)
//   Overlay.app --panel    NSPanel + .nonactivatingPanel  (the Alfred/Spotlight recipe)

import Cocoa

final class Delegate: NSObject, NSApplicationDelegate {
  var win: NSWindow!
  let usePanel = CommandLine.arguments.contains("--panel")

  func applicationDidFinishLaunching(_ n: Notification) {
    let rect = NSRect(x: 300, y: 300, width: 720, height: 300)
    if usePanel {
      let p = NSPanel(contentRect: rect,
                      styleMask: [.titled, .nonactivatingPanel, .utilityWindow],
                      backing: .buffered, defer: false)
      p.isFloatingPanel = true
      p.hidesOnDeactivate = false
      win = p
    } else {
      win = NSWindow(contentRect: rect,
                     styleMask: [.titled, .closable],
                     backing: .buffered, defer: false)
    }
    win.title = usePanel ? "OVERLAY (NSPanel)" : "OVERLAY (NSWindow)"
    win.backgroundColor = NSColor(calibratedRed: 0.05, green: 0.65, blue: 0.25, alpha: 1)
    win.level = .screenSaver
    win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

    let label = NSTextField(labelWithString:
      (usePanel ? "NSPanel + .nonactivatingPanel" : "plain NSWindow")
      + "\nlevel = .screenSaver\n[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]")
    label.font = NSFont.boldSystemFont(ofSize: 24)
    label.textColor = .white
    label.alignment = .center
    label.maximumNumberOfLines = 0
    label.frame = NSRect(x: 20, y: 60, width: rect.width - 40, height: 160)
    win.contentView?.addSubview(label)

    win.orderFrontRegardless()

    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self else { return }
      self.win.orderFrontRegardless()
      let fa = NSWorkspace.shared.frontmostApplication?.localizedName ?? "?"
      FileHandle.standardOutput.write(
        "onActiveSpace=\(self.win.isOnActiveSpace) visible=\(self.win.isVisible) frontmost=\(fa)\n"
          .data(using: .utf8)!)
    }
  }
}

let app = NSApplication.shared
// .accessory keeps it out of the Dock and, critically, means activating it never
// forces a Space switch — the property a gate overlay wants.
app.setActivationPolicy(.accessory)
let d = Delegate()
app.delegate = d
app.run()
