import Foundation
import SwiftUI
import ForceKit

// MARK: - Remote sync (Supabase) — macOS orchestrator
//
// Pulls the editable contract / quotes / goals / reflection from the same
// Supabase project the web editor writes to, so changes made anywhere land on
// this Mac. Auth is email + password via GoTrue; content is read over PostgREST
// (row-level security returns only the signed-in user's row). The fetched copy
// is applied to SettingsStore, which already persists locally — so the last
// successful sync is the offline fallback.
//
// Networking and session lifecycle live in ForceKit (`SyncEngine` /
// `SupabaseClient`); this type owns what's UI- and platform-specific:
// published status, dirty tracking, last-write-wins reconciliation, and the
// Keychain-backed credential (`KeychainSessionStore`).

/// Where the sync pipeline currently stands, for the Settings UI.
enum SyncStatus: Equatable {
    case needsConfig
    case loggedOut
    case syncing
    case synced(Date)
    case error(String)
}

@MainActor
final class RemoteSync: ObservableObject {
    static let shared = RemoteSync()

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let baseURL = "af-supabase-url-v1"
        static let anonKey = "af-supabase-anon-v1"
        static let localDirty = "af-sync-dirty-v1"
        static let localUpdatedAt = "af-sync-local-ms-v1"
        // Legacy plaintext token keys — migrated to the Keychain on first
        // launch after the security fix, then permanently removed.
        static let legacyAccess = "af-supabase-access-v1"
        static let legacyRefresh = "af-supabase-refresh-v1"
        static let legacyEmail = "af-supabase-email-v1"
        static let legacyUserId = "af-supabase-userid-v1"
    }

    /// User-entered connection overrides. Not secrets (the anon key is public
    /// by design), so plain UserDefaults is fine here — unlike the session.
    @Published var baseURL: String { didSet { defaults.set(baseURL, forKey: Keys.baseURL) } }
    @Published var anonKey: String { didSet { defaults.set(anonKey, forKey: Keys.anonKey) } }

    @Published private(set) var email: String?
    @Published private(set) var status: SyncStatus = .loggedOut

    /// True when the Mac holds edits to synced fields that haven't reached the
    /// cloud yet. Surfaced in Settings; cleared after a successful push/pull.
    @Published private(set) var localDirty: Bool

    /// Set while a remote pull is writing into SettingsStore, so the resulting
    /// `didSet`s don't get mistaken for user edits.
    private var applyingRemote = false

    private let sessionStore: SessionStore
    private let engine: SyncEngine

    private var localUpdatedAt: Double {
        get { defaults.double(forKey: Keys.localUpdatedAt) }
        set { defaults.set(newValue, forKey: Keys.localUpdatedAt) }
    }

    /// User-entered overrides win; otherwise fall back to the build-time baked
    /// config (set by install.sh). Lets distributed builds work with no setup.
    ///
    /// Static + UserDefaults-backed so the SyncEngine's client factory can
    /// read the current values from any thread (UserDefaults is thread-safe).
    nonisolated private static func currentEffectiveURL() -> String {
        let override = (UserDefaults.standard.string(forKey: Keys.baseURL) ?? "")
            .trimmingCharacters(in: .whitespaces)
        return override.isEmpty ? SupabaseConfig.url : override
    }
    nonisolated private static func currentEffectiveAnonKey() -> String {
        let override = (UserDefaults.standard.string(forKey: Keys.anonKey) ?? "")
            .trimmingCharacters(in: .whitespaces)
        return override.isEmpty ? SupabaseConfig.anonKey : override
    }

    var effectiveURL: String { Self.currentEffectiveURL() }
    var effectiveAnonKey: String { Self.currentEffectiveAnonKey() }

    var isConfigured: Bool {
        !effectiveURL.isEmpty && !effectiveAnonKey.isEmpty
    }
    var isLoggedIn: Bool { engine.isLoggedIn }

    private init() {
        let sessionStore = KeychainSessionStore()
        self.sessionStore = sessionStore

        baseURL = defaults.string(forKey: Keys.baseURL) ?? ""
        anonKey = defaults.string(forKey: Keys.anonKey) ?? ""
        localDirty = defaults.bool(forKey: Keys.localDirty)

        // The engine reads config lazily per operation, so edits to the URL or
        // key fields apply without restarting.
        engine = SyncEngine(sessionStore: sessionStore) {
            try SupabaseClient(
                baseURLString: Self.currentEffectiveURL(),
                anonKey: Self.currentEffectiveAnonKey()
            )
        }

        migrateLegacyTokensIfNeeded()
        email = sessionStore.load()?.email
        status = !isConfigured ? .needsConfig : (isLoggedIn ? .synced(.distantPast) : .loggedOut)
    }

    /// One-time security migration: sessions used to live in UserDefaults
    /// (world-readable plist, captured by backups). Move any legacy tokens
    /// into the Keychain and scrub the plist.
    private func migrateLegacyTokensIfNeeded() {
        if sessionStore.load() == nil,
           let access = defaults.string(forKey: Keys.legacyAccess),
           let refresh = defaults.string(forKey: Keys.legacyRefresh),
           let userId = defaults.string(forKey: Keys.legacyUserId) {
            sessionStore.save(SupabaseSession(
                accessToken: access,
                refreshToken: refresh,
                userId: userId,
                email: defaults.string(forKey: Keys.legacyEmail)
            ))
        }
        for key in [Keys.legacyAccess, Keys.legacyRefresh, Keys.legacyEmail, Keys.legacyUserId] {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: Local edit tracking

    /// Called from SettingsStore when the user edits a synced field on the Mac.
    /// Records the edit time so the next sync can decide push-vs-pull.
    func markLocalEdit() {
        guard !applyingRemote else { return }
        localUpdatedAt = Date().timeIntervalSince1970 * 1000
        localDirty = true
        defaults.set(true, forKey: Keys.localDirty)
    }

    private func clearDirty() {
        localDirty = false
        defaults.set(false, forKey: Keys.localDirty)
    }

    // MARK: Public API

    /// Called once on launch — refreshes content if we have a session.
    func launchSync() async {
        guard isConfigured, isLoggedIn else { return }
        await syncNow()
    }

    func login(email rawEmail: String, password: String) async {
        let email = rawEmail.trimmingCharacters(in: .whitespaces)
        guard isConfigured else { status = .needsConfig; return }
        guard !email.isEmpty, !password.isEmpty else {
            status = .error("Enter your email and password."); return
        }
        status = .syncing
        do {
            let session = try await engine.login(email: email, password: password)
            self.email = session.email ?? email
            await syncNow()
        } catch {
            status = .error(message(for: error))
        }
    }

    /// Logs out locally right away; server-side revocation happens best-effort
    /// in the background.
    func logout() {
        email = nil
        status = .loggedOut
        Task { await engine.logout() }
    }

    /// Reconciles local and cloud copies with last-write-wins. If the Mac holds
    /// newer edits, they're pushed; otherwise the cloud copy is pulled in.
    func syncNow() async {
        guard isConfigured, isLoggedIn else { return }
        status = .syncing
        do {
            let cloud = try await engine.fetchContent()
            let cloudMs = PostgresTimestamp.epochMs(cloud.updatedAt)
            if localDirty && localUpdatedAt > cloudMs {
                try await push()
            } else {
                apply(cloud)
                localUpdatedAt = cloudMs
            }
            clearDirty()
            status = .synced(Date())
        } catch {
            status = .error(message(for: error))
        }
    }

    /// Pushes pending local edits without pulling — used when leaving Settings.
    func pushIfDirty() async {
        guard isConfigured, isLoggedIn, localDirty else { return }
        status = .syncing
        do {
            try await push()
            clearDirty()
            status = .synced(Date())
        } catch {
            status = .error(message(for: error))
        }
    }

    // MARK: Internals

    private func push() async throws {
        let settings = SettingsStore.shared
        try await engine.pushContent(
            contractMd: settings.contractText,
            goals: settings.nonNegotiables.map { RemoteGoal(id: $0.id, label: $0.label) }
        )
    }

    /// Applies a cloud row to local settings (cloud → local direction only).
    private func apply(_ c: RemoteContent) {
        applyingRemote = true
        defer { applyingRemote = false }

        let settings = SettingsStore.shared
        let contract = c.contractMd.trimmingCharacters(in: .whitespacesAndNewlines)
        if !contract.isEmpty { settings.contractText = c.contractMd }

        if !c.goals.isEmpty {
            settings.nonNegotiables = c.goals.map { NonNegotiable(id: $0.id, label: $0.label) }
        }

        let quotes = c.quotes.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if let quote = quotes.randomElement() { settings.motivation = quote }

        settings.reflection = c.reflection
    }

    private func message(for error: Error) -> String {
        switch error {
        case let e as SyncError: return e.message
        case let e as HTTPStatusError: return e.message
        default: return (error as NSError).localizedDescription
        }
    }
}
