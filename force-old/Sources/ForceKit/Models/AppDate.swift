import Foundation

/// Date formatting helpers shared by all front ends.
///
/// Day keys (`yyyy-MM-dd`, POSIX locale, Gregorian) are the canonical way the
/// app identifies "a day" in persisted state — they are locale-stable, so
/// stored data never shifts meaning when the user's locale changes.
public enum AppDate {
    /// Today's canonical day key, e.g. `2026-06-11`.
    public static func todayKey(now: Date = Date()) -> String {
        keyFormatter().string(from: now)
    }

    /// Today rendered for display, e.g. `Thursday, 11 June 2026`.
    public static func longToday(now: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_AU")
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f.string(from: now)
    }

    /// Renders a day key for compact display, e.g. `Thu, 11 Jun`.
    /// Returns the key unchanged if it doesn't parse.
    public static func short(_ key: String) -> String {
        guard let d = keyFormatter().date(from: key) else { return key }
        let out = DateFormatter()
        out.locale = Locale(identifier: "en_AU")
        out.dateFormat = "EEE, d MMM"
        return out.string(from: d)
    }

    /// Parses a canonical day key back to a `Date` (start of day, local zone).
    public static func parse(_ key: String) -> Date? {
        keyFormatter().date(from: key)
    }

    private static func keyFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }
}
