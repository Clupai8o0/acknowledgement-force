import Foundation

/// Pure decision logic for whether the contract is currently "locked".
///
/// The gate is the heart of Force: until it opens, the front end must show the
/// contract and refuse to proceed. Keeping this as a pure function (inputs in,
/// Bool out — no clocks or singletons reached for internally) makes the policy
/// identical on every platform and trivially testable.
public enum AcknowledgementGate {
    /// Decides whether the latest acknowledgement still satisfies the schedule.
    ///
    /// - Parameters:
    ///   - lastAcknowledgedMs: Epoch ms of the most recent acknowledgement
    ///     (`0`/negative means "never").
    ///   - frequency: The user's chosen re-lock schedule.
    ///   - sessionAcknowledged: Whether an acknowledgement happened in *this*
    ///     process/session — backs the `everyLaunch`/`onLogin` modes.
    ///   - now: Injected for testability; defaults to the current time.
    ///   - calendar: Calendar used for day/week comparisons.
    /// - Returns: `true` when the gate is open (no acknowledgement required).
    public static func isOpen(
        lastAcknowledgedMs: Double,
        frequency: Frequency,
        sessionAcknowledged: Bool,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard lastAcknowledgedMs > 0 else { return false }
        let lastDate = Date(timeIntervalSince1970: lastAcknowledgedMs / 1000)
        switch frequency {
        case .everyLaunch, .onLogin:
            return sessionAcknowledged
        case .hourly:
            return now.timeIntervalSince(lastDate) < 3600
        case .every12h:
            return now.timeIntervalSince(lastDate) < 43_200
        case .daily:
            return calendar.isDate(lastDate, inSameDayAs: now)
        case .weekly:
            return calendar.isDate(lastDate, equalTo: now, toGranularity: .weekOfYear)
        }
    }
}
