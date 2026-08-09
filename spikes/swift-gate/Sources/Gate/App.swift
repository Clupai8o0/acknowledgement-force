import SwiftUI
import AppKit

@main
struct GateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() { Fonts.register() }

    var body: some Scene {
        WindowGroup {
            GateView()
                .frame(width: Metrics.windowWidth, height: Metrics.windowHeight)
                .background(Ink.base)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}

enum Metrics {
    static let windowWidth: CGFloat = 960
    static let windowHeight: CGFloat = 640
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            for window in NSApp.windows {
                window.title = "The Evening Gate"
                window.backgroundColor = NSColor(Ink.base)
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                window.center()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
