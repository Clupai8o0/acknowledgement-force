import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking // URLSession on Linux/Windows lives here
#endif

/// Stateless HTTP client for the Supabase backend (GoTrue auth + PostgREST).
///
/// One method per remote operation; no token storage, no retry policy — those
/// belong to ``SyncEngine``. All requests are HTTPS-only: a non-`https` base
/// URL is rejected at construction so credentials can never travel plaintext.
public struct SupabaseClient: Sendable {
    private let baseURL: URL
    private let anonKey: String

    /// - Parameters:
    ///   - baseURLString: The project URL, e.g. `https://xxxx.supabase.co`.
    ///     Trailing slashes are tolerated. Must be `https`.
    ///   - anonKey: The *public* (publishable) API key. Row-level security is
    ///     what protects data — never put a service key here.
    /// - Throws: ``SyncError/badConfig`` for empty/malformed/non-HTTPS URLs.
    public init(baseURLString: String, anonKey: String) throws {
        var s = baseURLString.trimmingCharacters(in: .whitespaces)
        while s.hasSuffix("/") { s.removeLast() }
        guard !s.isEmpty, !anonKey.isEmpty,
              let url = URL(string: s), url.scheme == "https"
        else { throw SyncError.badConfig }
        self.baseURL = url
        self.anonKey = anonKey
    }

    // MARK: Auth (GoTrue)

    /// Exchanges email + password for a session.
    public func signIn(email: String, password: String) async throws -> SupabaseSession {
        try await requestToken(grant: "password", body: ["email": email, "password": password])
    }

    /// Exchanges a refresh token for a fresh session.
    public func refresh(refreshToken: String) async throws -> SupabaseSession {
        try await requestToken(grant: "refresh_token", body: ["refresh_token": refreshToken])
    }

    /// Revokes the session server-side. Best-effort: a failure here should not
    /// block a local logout, but successful revocation means a stolen refresh
    /// token from an old backup is useless.
    public func signOut(session: SupabaseSession) async {
        var req = URLRequest(url: baseURL.appendingPathComponent("auth/v1/logout"))
        req.httpMethod = "POST"
        applyHeaders(&req, accessToken: session.accessToken)
        _ = try? await send(req)
    }

    // MARK: Content (PostgREST `contents` table)

    /// Fetches the signed-in user's content row.
    ///
    /// The query filters on `user_id` explicitly even though row-level
    /// security already scopes results — defense in depth against a future
    /// policy regression.
    public func fetchContent(session: SupabaseSession) async throws -> RemoteContent {
        var comps = URLComponents(
            url: baseURL.appendingPathComponent("rest/v1/contents"),
            resolvingAgainstBaseURL: false
        )
        comps?.queryItems = [
            URLQueryItem(name: "select", value: "contract_md,quotes,goals,reflection,updated_at"),
            URLQueryItem(name: "user_id", value: "eq.\(session.userId)"),
            URLQueryItem(name: "limit", value: "1"),
        ]
        guard let url = comps?.url else { throw SyncError.badConfig }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        applyHeaders(&req, accessToken: session.accessToken)
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let data = try await send(req)
        let rows = try decode([RemoteContent].self, from: data)
        guard let row = rows.first else {
            throw SyncError.server("No contract found for this account.")
        }
        return row
    }

    /// PATCHes the locally-owned fields (contract + goals). Quotes and
    /// reflection stay under the web editor's control and are left untouched.
    public func pushContent(session: SupabaseSession, contractMd: String, goals: [RemoteGoal]) async throws {
        var comps = URLComponents(
            url: baseURL.appendingPathComponent("rest/v1/contents"),
            resolvingAgainstBaseURL: false
        )
        comps?.queryItems = [URLQueryItem(name: "user_id", value: "eq.\(session.userId)")]
        guard let url = comps?.url else { throw SyncError.badConfig }

        struct Patch: Encodable {
            let contract_md: String
            let goals: [RemoteGoal]
        }

        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        applyHeaders(&req, accessToken: session.accessToken)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode(Patch(contract_md: contractMd, goals: goals))

        _ = try await send(req)
    }

    // MARK: Internals

    private func requestToken(grant: String, body: [String: String]) async throws -> SupabaseSession {
        var comps = URLComponents(
            url: baseURL.appendingPathComponent("auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        comps?.queryItems = [URLQueryItem(name: "grant_type", value: grant)]
        guard let url = comps?.url else { throw SyncError.badConfig }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let data = try await send(req)

        struct TokenResponse: Codable {
            let access_token: String
            let refresh_token: String
            let user: User
            struct User: Codable {
                let id: String
                let email: String?
            }
        }
        let token = try decode(TokenResponse.self, from: data)
        return SupabaseSession(
            accessToken: token.access_token,
            refreshToken: token.refresh_token,
            userId: token.user.id,
            email: token.user.email
        )
    }

    private func applyHeaders(_ req: inout URLRequest, accessToken: String) {
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    /// Sends the request and returns the body on 2xx. Maps 401 to
    /// ``HTTPStatusError`` so callers can refresh-and-retry, and other
    /// failures to ``SyncError/server(_:)`` with a friendly message.
    private func send(_ req: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.asyncData(for: req)
        let code = response.statusCode
        guard (200..<300).contains(code) else {
            throw HTTPStatusError(status: code, message: serverMessage(data) ?? "Request failed (\(code)).")
        }
        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try JSONDecoder().decode(type, from: data) }
        catch { throw SyncError.server("Unexpected response from the server.") }
    }

    /// Pulls the most useful message out of a Supabase error body.
    private func serverMessage(_ data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return (obj["error_description"] as? String)
            ?? (obj["msg"] as? String)
            ?? (obj["message"] as? String)
            ?? (obj["error"] as? String)
    }
}

/// A non-2xx response, preserving the status so the engine can decide whether
/// to refresh the session (401) or surface the message.
public struct HTTPStatusError: Error {
    public let status: Int
    public let message: String
}

// MARK: - Cross-platform URLSession async shim

extension URLSession {
    /// `data(for:)` exists natively on Apple platforms but not reliably in
    /// swift-corelibs-foundation, so we bridge the completion-handler API with
    /// a continuation. Also guarantees the response is HTTP.
    func asyncData(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let http = response as? HTTPURLResponse {
                    continuation.resume(returning: (data, http))
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }
            task.resume()
        }
    }
}
