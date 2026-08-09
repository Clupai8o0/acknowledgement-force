import Foundation

// Wire models and errors for the Supabase sync backend.

/// An authenticated Supabase session (GoTrue tokens + identity).
///
/// Treat as a credential: the refresh token is long-lived. Persist only via a
/// ``SessionStore`` (Keychain on macOS, owner-only file elsewhere).
public struct SupabaseSession: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String
    public var userId: String
    public var email: String?

    public init(accessToken: String, refreshToken: String, userId: String, email: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userId = userId
        self.email = email
    }
}

/// One row of the `contents` table — the user's synced editable content.
public struct RemoteContent: Codable, Sendable {
    public var contractMd: String
    public var quotes: [String]
    public var goals: [RemoteGoal]
    public var reflection: String
    public var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case contractMd = "contract_md"
        case quotes
        case goals
        case reflection
        case updatedAt = "updated_at"
    }

    public init(contractMd: String, quotes: [String], goals: [RemoteGoal], reflection: String, updatedAt: String?) {
        self.contractMd = contractMd
        self.quotes = quotes
        self.goals = goals
        self.reflection = reflection
        self.updatedAt = updatedAt
    }
}

/// A goal as stored in the `contents.goals` JSON column.
public struct RemoteGoal: Codable, Sendable {
    public var id: String
    public var label: String

    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }
}

/// Errors surfaced by the sync layer. `message` is safe to show in UI.
public enum SyncError: Error, Equatable {
    /// Base URL or anon key missing/malformed.
    case badConfig
    /// An authenticated call was made with no stored session.
    case notLoggedIn
    /// The server rejected the request; the associated value is a
    /// user-presentable message extracted from the response.
    case server(String)

    /// A short, user-presentable description.
    public var message: String {
        switch self {
        case .badConfig: return "Check the Supabase URL and key."
        case .notLoggedIn: return "Not logged in."
        case .server(let m): return m
        }
    }
}

/// Parses PostgREST `timestamptz` strings ("2026-05-22T10:00:00.123456+00:00").
public enum PostgresTimestamp {
    /// Converts to epoch milliseconds; returns 0 for nil/unparseable input.
    /// Fractional seconds are trimmed to milliseconds, which is the most
    /// ISO8601DateFormatter accepts.
    public static func epochMs(_ s: String?) -> Double {
        guard var str = s else { return 0 }
        if let dot = str.firstIndex(of: ".") {
            var i = str.index(after: dot)
            var frac = ""
            while i < str.endIndex, str[i].isNumber {
                frac.append(str[i])
                i = str.index(after: i)
            }
            let ms = String(frac.prefix(3))
            str.replaceSubrange(dot..<i, with: ms.isEmpty ? "" : "." + ms)
        }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: str) { return d.timeIntervalSince1970 * 1000 }
        f.formatOptions = [.withInternetDateTime]
        if let d = f.date(from: str) { return d.timeIntervalSince1970 * 1000 }
        return 0
    }
}
