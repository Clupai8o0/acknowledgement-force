import Foundation
import ForceKit

/// Wires ForceKit up for the desktop GUI: resolves the per-user state directory
/// and constructs the stores and sync engine the model operates on.
///
/// This is the GUI twin of `CLIEnvironment` and uses the *same* on-disk layout,
/// so `force-desktop` and `force-cli` on one machine share local state:
///   state.json    — settings + journal (FileKeyValueStore, chmod 600)
///   session.json  — Supabase session (FileSessionStore, chmod 600)
///
/// Location (overridable via `FORCE_STATE_DIR`): `~/Library/Application Support/
/// Force` on macOS, `~/.local/share/Force` on Linux, `%APPDATA%\Force` on
/// Windows.
struct DesktopEnvironment {
    let store: FileKeyValueStore
    let settings: SettingsStorage
    let journal: AcknowledgementJournal
    let engine: SyncEngine

    /// Persistence keys shared with the CLI/macOS sync layer.
    enum Keys {
        static let baseURL = "af-supabase-url-v1"
        static let anonKey = "af-supabase-anon-v1"
        static let localDirty = "af-sync-dirty-v1"
        static let localUpdatedAt = "af-sync-local-ms-v1"
    }

    init(directory: URL = DesktopEnvironment.stateDirectory()) {
        let stateURL = directory.appendingPathComponent("state.json")
        let store = FileKeyValueStore(url: stateURL)
        self.store = store
        settings = SettingsStorage(store: store)
        journal = AcknowledgementJournal(store: store)

        let sessionStore = FileSessionStore(url: directory.appendingPathComponent("session.json"))
        engine = SyncEngine(sessionStore: sessionStore) {
            // Read connection overrides fresh from disk each call so edits in
            // the Settings panel apply without a relaunch (mirrors CLIEnvironment).
            let fresh = FileKeyValueStore(url: stateURL)
            let url = fresh.string(forKey: Keys.baseURL) ?? SupabaseConfig.url
            let key = fresh.string(forKey: Keys.anonKey) ?? SupabaseConfig.anonKey
            return try SupabaseClient(baseURLString: url, anonKey: key)
        }
    }

    /// Resolves the platform-appropriate state directory.
    static func stateDirectory() -> URL {
        let env = ProcessInfo.processInfo.environment
        if let custom = env["FORCE_STATE_DIR"], !custom.isEmpty {
            return URL(fileURLWithPath: custom, isDirectory: true)
        }
        #if os(Windows)
        if let appData = env["APPDATA"], !appData.isEmpty {
            return URL(fileURLWithPath: appData, isDirectory: true)
                .appendingPathComponent("Force", isDirectory: true)
        }
        #endif
        if let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return dir.appendingPathComponent("Force", isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".force", isDirectory: true)
    }
}
