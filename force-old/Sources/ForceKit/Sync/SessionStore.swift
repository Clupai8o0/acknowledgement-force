import Foundation

/// Where the Supabase session (access + refresh tokens) is kept.
///
/// Sessions are credentials, so storage is abstracted away from the sync
/// logic: the macOS app provides a Keychain-backed implementation; other
/// platforms use ``FileSessionStore`` (owner-only JSON file). Never put
/// sessions in UserDefaults/plists — those are world-readable backups waiting
/// to happen.
public protocol SessionStore: AnyObject, Sendable {
    /// The persisted session, or nil when logged out.
    func load() -> SupabaseSession?
    /// Persists (or replaces) the session.
    func save(_ session: SupabaseSession)
    /// Removes any persisted session.
    func clear()
}

/// File-backed ``SessionStore`` for platforms without a system keychain.
/// The file is written atomically and restricted to the owner (0600) on POSIX.
public final class FileSessionStore: SessionStore {
    // Sendable: the only stored property is the immutable file URL.
    private let url: URL

    /// - Parameter url: Location of the session file, e.g.
    ///   `<state dir>/session.json`.
    public init(url: URL) {
        self.url = url
    }

    public func load() -> SupabaseSession? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SupabaseSession.self, from: data)
    }

    public func save(_ session: SupabaseSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
        FilePermissions.restrictToOwner(url)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
