import Foundation
import SwiftUI
import ForceKit

/// Observable façade over ForceKit's ``SettingsStorage`` for the macOS UI.
///
/// Each `@Published` property mirrors a persisted setting and writes through
/// on change; side effects that belong to the platform (LaunchAgent installs,
/// gate recomputation, sync dirty-marking) hang off the `didSet`s here, not in
/// the storage layer.
@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private let storage = SettingsStorage(store: UserDefaultsKeyValueStore())

    @Published var frequency: Frequency {
        didSet {
            storage.frequency = frequency
            Store.shared.recomputeGate()
            if autoLaunch { LaunchAgent.install(for: frequency) }
        }
    }

    @Published var autoLaunch: Bool {
        didSet {
            storage.autoLaunch = autoLaunch
            if autoLaunch { LaunchAgent.install(for: frequency) } else { LaunchAgent.uninstall() }
        }
    }

    @Published var motivation: String {
        didSet {
            storage.motivation = motivation
            RemoteSync.shared.markLocalEdit()
        }
    }

    @Published var contractText: String {
        didSet {
            storage.contractText = contractText
            RemoteSync.shared.markLocalEdit()
        }
    }

    @Published var reflection: String {
        didSet { storage.reflection = reflection }
    }

    @Published var nonNegotiables: [NonNegotiable] {
        didSet {
            storage.nonNegotiables = nonNegotiables
            Store.shared.syncChecklist()
            RemoteSync.shared.markLocalEdit()
        }
    }

    @Published var hasOnboarded: Bool {
        didSet { storage.hasOnboarded = hasOnboarded }
    }

    @Published var displayName: String {
        didSet { storage.displayName = displayName }
    }

    private init() {
        frequency = storage.frequency
        autoLaunch = storage.autoLaunch
        hasOnboarded = storage.hasOnboarded
        displayName = storage.displayName
        motivation = storage.motivation
        contractText = storage.contractText
        reflection = storage.reflection
        nonNegotiables = storage.nonNegotiables

        if autoLaunch { LaunchAgent.migrateIfNeeded(for: frequency) }
    }
}

// MARK: - LaunchAgent integration (macOS auto-launch)

/// Installs/removes a user LaunchAgent so Force auto-launches on login and on
/// the chosen interval. User-initiated only (toggled in onboarding/settings).
enum LaunchAgent {
    static let label = "com.acknowledgementforce.agent"

    private static var plistURL: URL? {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .appendingPathComponent("LaunchAgents/\(label).plist")
    }

    // Launch via `open` so LaunchServices activates the existing app when one
    // is already running. Executing the bare Mach-O directly spawns a second
    // GUI process with the same bundle ID, which macOS terminates with a crash
    // report before SingleInstance can hand off.
    private static var programArguments: [String] {
        let bundle = Bundle.main.bundlePath
        if bundle.hasSuffix(".app") { return ["/usr/bin/open", bundle] }
        return [Bundle.main.executablePath ?? CommandLine.arguments.first ?? ""]
    }

    static func install(for frequency: Frequency) {
        guard let url = plistURL else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        var dict: [String: Any] = [
            "Label": label,
            "ProgramArguments": programArguments,
            "RunAtLoad": true,
            "ProcessType": "Interactive",
        ]
        if let interval = frequency.startInterval {
            dict["StartInterval"] = interval
        } else if frequency == .daily {
            dict["StartCalendarInterval"] = ["Hour": 6, "Minute": 0]
        } else if frequency == .weekly {
            dict["StartCalendarInterval"] = ["Weekday": 1, "Hour": 6, "Minute": 0]
        }

        guard let data = try? PropertyListSerialization.data(
            fromPropertyList: dict, format: .xml, options: 0) else { return }
        try? data.write(to: url)
        reload(url: url)
    }

    /// Rewrites the plist if it predates the `/usr/bin/open` fix. Old installs
    /// run the bare binary, which crashes when the app is already up.
    static func migrateIfNeeded(for frequency: Frequency) {
        guard let url = plistURL,
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let args = plist["ProgramArguments"] as? [String]
        else { return }
        if args.first != "/usr/bin/open" { install(for: frequency) }
    }

    static func uninstall() {
        guard let url = plistURL else { return }
        run(["/bin/launchctl", "bootout", "gui/\(getuid())/\(label)"])
        try? FileManager.default.removeItem(at: url)
    }

    private static func reload(url: URL) {
        let domain = "gui/\(getuid())"
        run(["/bin/launchctl", "bootout", "\(domain)/\(label)"])
        run(["/bin/launchctl", "bootstrap", domain, url.path])
    }

    @discardableResult
    private static func run(_ args: [String]) -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: args[0])
        p.arguments = Array(args.dropFirst())
        p.standardOutput = nil
        p.standardError = nil
        do { try p.run(); p.waitUntilExit(); return p.terminationStatus }
        catch { return -1 }
    }
}
