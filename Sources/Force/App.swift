import SwiftUI
import AppKit

@main
struct ForceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = Store.shared
    @StateObject private var theme = ThemeManager.shared
    @StateObject private var settings = SettingsStore.shared
    @StateObject private var remote = RemoteSync.shared

    init() { Fonts.register() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(theme)
                .environmentObject(settings)
                .environmentObject(remote)
                .frame(minWidth: 1100, minHeight: 760)
                .background(Ink.base)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}

// Gates window close before today's acknowledgement — the "no escape" rule.
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Bail out before any window is built if another Force is already up.
        guard SingleInstance.acquire() else { SingleInstance.handoffAndExit() }
        SingleInstance.listenForActivation()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            for window in NSApp.windows {
                window.delegate = self
                window.title = "Acknowledgement Force"
                window.setContentSize(NSSize(width: 1400, height: 900))
                window.center()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // launchd's hourly `open Force.app` lands here when Force is already running.
    // Without this, a minimized window stays in the Dock (makeKeyAndOrderFront
    // doesn't deminiaturize) and the user never sees the freshly-locked contract.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if window.isMiniaturized { window.deminiaturize(nil) }
            if window.canBecomeMain { window.makeKeyAndOrderFront(nil) }
        }
        Store.shared.recomputeGate()
        return true
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Allow close once today's contract is acknowledged, or when the
        // in-app Exit button explicitly authorizes it.
        Store.shared.gateOpen || ExitAuthorizer.shared.allowed
    }
}

// Lets the in-app Exit button bypass the close gate intentionally.
@MainActor
final class ExitAuthorizer {
    static let shared = ExitAuthorizer()
    var allowed = false
    func exit() {
        allowed = true
        NSApp.terminate(nil)
    }
}
