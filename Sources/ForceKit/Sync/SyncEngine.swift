import Foundation

/// Orchestrates authenticated calls against Supabase: owns the persisted
/// session, refreshes it once on a 401, and exposes the operations front ends
/// need (login, logout, fetch, push).
///
/// UI concerns — dirty tracking, last-write-wins reconciliation, status
/// publishing — stay in the platform layer; this type is deliberately free of
/// observation so it works in a CLI as well as a GUI.
public final class SyncEngine: Sendable {
    private let makeClient: @Sendable () throws -> SupabaseClient
    private let sessionStore: SessionStore

    /// - Parameters:
    ///   - sessionStore: Where the session credential lives (Keychain/file).
    ///   - makeClient: Factory producing a client from the *current* config —
    ///     called per operation so settings edits take effect immediately.
    ///     Must be thread-safe; it can run off the caller's actor.
    public init(sessionStore: SessionStore, makeClient: @escaping @Sendable () throws -> SupabaseClient) {
        self.sessionStore = sessionStore
        self.makeClient = makeClient
    }

    /// The persisted session, if logged in.
    public var session: SupabaseSession? { sessionStore.load() }
    public var isLoggedIn: Bool { session != nil }

    /// Signs in with email + password and persists the session.
    @discardableResult
    public func login(email: String, password: String) async throws -> SupabaseSession {
        let session = try await makeClient().signIn(email: email, password: password)
        sessionStore.save(session)
        return session
    }

    /// Logs out: revokes the session server-side (best effort) and always
    /// clears the local credential.
    public func logout() async {
        if let session = sessionStore.load(), let client = try? makeClient() {
            await client.signOut(session: session)
        }
        sessionStore.clear()
    }

    /// Fetches the user's content row, transparently refreshing an expired
    /// session once.
    public func fetchContent() async throws -> RemoteContent {
        try await withSession { client, session in
            try await client.fetchContent(session: session)
        }
    }

    /// Pushes the locally-owned fields (contract + goals), transparently
    /// refreshing an expired session once.
    public func pushContent(contractMd: String, goals: [RemoteGoal]) async throws {
        try await withSession { client, session in
            try await client.pushContent(session: session, contractMd: contractMd, goals: goals)
        }
    }

    // MARK: Session lifecycle

    /// Runs `operation` with the stored session; on a 401, refreshes the
    /// session once and retries. A failed refresh clears the stored session
    /// (it is dead — keeping it would loop forever).
    private func withSession<T>(
        _ operation: (SupabaseClient, SupabaseSession) async throws -> T
    ) async throws -> T {
        guard let session = sessionStore.load() else { throw SyncError.notLoggedIn }
        let client = try makeClient()
        do {
            return try await operation(client, session)
        } catch let error as HTTPStatusError where error.status == 401 {
            let refreshed = try await refreshSession(client: client, expired: session)
            return try await operation(client, refreshed)
        } catch let error as HTTPStatusError {
            throw SyncError.server(error.message)
        }
    }

    private func refreshSession(client: SupabaseClient, expired: SupabaseSession) async throws -> SupabaseSession {
        do {
            let refreshed = try await client.refresh(refreshToken: expired.refreshToken)
            sessionStore.save(refreshed)
            return refreshed
        } catch {
            sessionStore.clear()
            throw SyncError.notLoggedIn
        }
    }
}
