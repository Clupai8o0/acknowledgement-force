import Foundation

// Core domain models shared by every Force front end (macOS app, CLI).
// Everything here is a plain value type: Codable for persistence/wire use,
// Sendable so it can cross concurrency domains freely.

/// A single signed acknowledgement of the daily contract.
public struct Acknowledgement: Codable, Equatable, Sendable {
    /// Day the contract was acknowledged, as a `yyyy-MM-dd` key (see ``AppDate``).
    public var date: String
    /// The user's "highest-leverage action" entered at acknowledgement time.
    public var action: String
    /// Epoch milliseconds when the acknowledgement was confirmed.
    public var timestamp: Double

    public init(date: String, action: String, timestamp: Double) {
        self.date = date
        self.action = action
        self.timestamp = timestamp
    }
}

/// One line of the acknowledgement history (last 30 days are retained).
public struct HistoryEntry: Codable, Identifiable, Equatable, Sendable {
    public var date: String
    public var action: String
    public var timestamp: Double
    public var id: Double { timestamp }

    public init(date: String, action: String, timestamp: Double) {
        self.date = date
        self.action = action
        self.timestamp = timestamp
    }
}

/// An item on the daily non-negotiables checklist. `id` is stable across
/// renames so checklist completion state survives label edits.
public struct NonNegotiable: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var label: String

    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }
}

/// How often the contract re-locks and must be re-acknowledged.
public enum Frequency: String, Codable, CaseIterable, Identifiable, Sendable {
    case everyLaunch
    case hourly
    case every12h
    case daily
    case weekly
    case onLogin

    public var id: String { rawValue }

    /// Short human label for pickers.
    public var label: String {
        switch self {
        case .everyLaunch: return "Every launch"
        case .hourly:      return "Every hour"
        case .every12h:    return "Every 12 hours"
        case .daily:       return "Once a day"
        case .weekly:      return "Once a week"
        case .onLogin:     return "On login / restart"
        }
    }

    /// One-line explanation shown next to the label.
    public var detail: String {
        switch self {
        case .everyLaunch: return "Re-acknowledge each time Force opens."
        case .hourly:      return "Re-locks one hour after each acknowledgement."
        case .every12h:    return "Re-locks twelve hours after each acknowledgement."
        case .daily:       return "One acknowledgement carries the whole day."
        case .weekly:      return "One acknowledgement carries the whole week."
        case .onLogin:     return "Re-acknowledge on every login and restart."
        }
    }

    /// Seconds between forced relaunches for schedulers (launchd, systemd
    /// timers), when the frequency is interval-based. `nil` for calendar or
    /// session-based frequencies.
    public var startInterval: Int? {
        switch self {
        case .hourly:   return 3600
        case .every12h: return 43_200
        default:        return nil
        }
    }
}

/// Default copy used when the user hasn't customised anything yet.
public enum DefaultCopy {
    public static let motivation =
        "Execution beats planning. Commits, deployments, and documentation are the only valid measures."

    public static let nonNegotiables: [NonNegotiable] = [
        .init(id: "brush-teeth", label: "Brush teeth (morning & night)"),
        .init(id: "wash-face", label: "Wash face (morning & night)"),
        .init(id: "leetcode", label: "LeetCode: 1 problem minimum"),
        .init(id: "cold-message", label: "Send 1 cold message/email"),
        .init(id: "gym", label: "Gym/30min physical activity"),
        .init(id: "journal", label: "Journal: 5-10 minutes"),
        .init(id: "read", label: "Read: 15-30 minutes"),
        .init(id: "no-doomscroll", label: "No doomscrolling (sit in silence 5-10 min)"),
    ]
}
