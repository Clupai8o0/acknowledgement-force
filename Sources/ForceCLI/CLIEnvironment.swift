import Foundation
import ForceKit

/// Wires ForceKit up for terminal use: resolves the per-user state directory
/// and constructs the stores and sync engine the commands operate on.
///
/// State layout (overridable via `FORCE_STATE_DIR`):
///   state.json    — settings + journal (FileKeyValueStore, chmod 600)
///   session.json  — Supabase session (FileSessionStore, chmod 600)
///
/// On macOS this lives in `~/Library/Application Support/Force`, on Linux in
/// `~/.local/share/Force` (or the platform's application-support equivalent),
/// on Windows in `%APPDATA%\Force`. The GUI app keeps its own UserDefaults
/// state; CLI and GUI are independent fronts over the same cloud account.
struct CLIEnvironment {
    let settings: SettingsStorage
    let journal: AcknowledgementJournal
    let engine: SyncEngine
    let store: KeyValueStore

    /// Connection override keys (same semantics as the macOS Settings fields:
    /// user-entered values win over the baked-in build config).
    enum Keys {
        static let baseURL = "af-supabase-url-v1"
        static let anonKey = "af-supabase-anon-v1"
    }

    init(directory: URL = CLIEnvironment.stateDirectory()) {
        let store = FileKeyValueStore(url: directory.appendingPathComponent("state.json"))
        self.store = store
        settings = SettingsStorage(store: store)
        journal = AcknowledgementJournal(store: store)

        let sessionStore = FileSessionStore(url: directory.appendingPathComponent("session.json"))
        engine = SyncEngine(sessionStore: sessionStore) {
            // Read overrides directly from disk so each operation sees the
            // latest `config set` values.
            let fresh = FileKeyValueStore(url: directory.appendingPathComponent("state.json"))
            let url = fresh.string(forKey: Keys.baseURL) ?? SupabaseConfig.url
            let key = fresh.string(forKey: Keys.anonKey) ?? SupabaseConfig.anonKey
            return try SupabaseClient(baseURLString: url, anonKey: key)
        }
    }

    var effectiveURL: String { store.string(forKey: Keys.baseURL) ?? SupabaseConfig.url }
    var effectiveAnonKey: String { store.string(forKey: Keys.anonKey) ?? SupabaseConfig.anonKey }
    var isConfigured: Bool { !effectiveURL.isEmpty && !effectiveAnonKey.isEmpty }

    /// Whether the contract currently requires (re-)acknowledgement.
    /// `everyLaunch`/`onLogin` always lock in the CLI: every invocation is a
    /// fresh process, so there is no session to carry an acknowledgement.
    var isLocked: Bool {
        !AcknowledgementGate.isOpen(
            lastAcknowledgedMs: journal.lastAcknowledgedMs,
            frequency: settings.frequency,
            sessionAcknowledged: false
        )
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
