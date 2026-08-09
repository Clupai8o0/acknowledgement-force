import Foundation

/// Records acknowledgements, the rolling 30-day history, and the daily
/// checklist state — the persistent half of the gate.
///
/// Pure storage + bookkeeping: no UI observation, no singletons. Checklist
/// items are passed in by the caller rather than read from settings here, so
/// the journal has a single responsibility and no hidden dependencies.
/// Keys match the original macOS UserDefaults keys for data continuity.
public final class AcknowledgementJournal {
    public enum Keys {
        public static let acknowledgement = "af-acknowledgement-v1"
        public static let checklist = "af-checklist-v1"
        public static let checklistDate = "af-checklist-v1-date"
        public static let history = "af-history-v1"
        public static let lastAckMs = "af-last-ack-ms-v1"
    }

    /// Days of history retained when appending a new entry.
    public static let historyRetentionDays = 30

    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    // MARK: Acknowledgement

    /// Epoch ms of the most recent acknowledgement; `0` when never acknowledged.
    public var lastAcknowledgedMs: Double {
        store.double(forKey: Keys.lastAckMs)
    }

    /// The most recent stored acknowledgement, if any.
    public func acknowledgement() -> Acknowledgement? {
        guard let data = store.data(forKey: Keys.acknowledgement) else { return nil }
        return try? JSONDecoder().decode(Acknowledgement.self, from: data)
    }

    /// Records a fresh acknowledgement: stores it, appends to history, resets
    /// the checklist for the day, and bumps the last-acknowledged stamp.
    ///
    /// - Parameters:
    ///   - action: The user's highest-leverage action for the period.
    ///   - items: Current checklist items (used to seed a fresh checklist).
    ///   - now: Injected clock for testability.
    public func confirm(action: String, items: [NonNegotiable], now: Date = Date()) {
        let today = AppDate.todayKey(now: now)
        let ms = now.timeIntervalSince1970 * 1000
        let ack = Acknowledgement(date: today, action: action, timestamp: ms)
        if let data = try? JSONEncoder().encode(ack) {
            store.set(data, forKey: Keys.acknowledgement)
        }
        appendHistory(action: action, date: today, now: now)
        resetChecklist(items: items, for: today)
        store.set(ms, forKey: Keys.lastAckMs)
    }

    /// Edits the acknowledged action in place: updates the stored
    /// acknowledgement and today's most recent history entry (rather than
    /// appending a new one). Returns the trimmed value actually stored, or
    /// nil when the edit was empty/unchanged and nothing was written.
    @discardableResult
    public func updateTodayAction(_ newAction: String, currentAction: String, now: Date = Date()) -> String? {
        let trimmed = newAction.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != currentAction else { return nil }
        let today = AppDate.todayKey(now: now)

        if var ack = acknowledgement() {
            ack.action = trimmed
            if let data = try? JSONEncoder().encode(ack) {
                store.set(data, forKey: Keys.acknowledgement)
            }
        }

        var entries = history()
        if let idx = entries.firstIndex(where: { $0.date == today }) {
            entries[idx].action = trimmed
        } else {
            entries.insert(
                HistoryEntry(date: today, action: trimmed, timestamp: now.timeIntervalSince1970 * 1000),
                at: 0
            )
        }
        persistHistory(entries)
        return trimmed
    }

    // MARK: History

    /// All retained history entries, newest first.
    public func history() -> [HistoryEntry] {
        guard let data = store.data(forKey: Keys.history) else { return [] }
        return (try? JSONDecoder().decode([HistoryEntry].self, from: data)) ?? []
    }

    private func appendHistory(action: String, date: String, now: Date) {
        let cutoff = Calendar.current.date(
            byAdding: .day, value: -Self.historyRetentionDays, to: now) ?? .distantPast
        var entries = history().filter { (AppDate.parse($0.date) ?? .distantPast) >= cutoff }
        entries.insert(
            HistoryEntry(date: date, action: action, timestamp: now.timeIntervalSince1970 * 1000),
            at: 0
        )
        persistHistory(entries)
    }

    private func persistHistory(_ entries: [HistoryEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            store.set(data, forKey: Keys.history)
        }
    }

    // MARK: Checklist

    /// Loads the checklist for `today`, resetting it (all unchecked) when the
    /// stored one belongs to a previous day.
    public func loadChecklist(items: [NonNegotiable], today: String = AppDate.todayKey()) -> [String: Bool] {
        if let data = store.data(forKey: Keys.checklist),
           let stored = try? JSONDecoder().decode([String: [String: Bool]].self, from: data),
           store.string(forKey: Keys.checklistDate) == today,
           let saved = stored["items"] {
            return saved
        }
        return resetChecklist(items: items, for: today)
    }

    /// Replaces the checklist with a fresh all-unchecked one for `day`.
    @discardableResult
    public func resetChecklist(items: [NonNegotiable], for day: String) -> [String: Bool] {
        var fresh: [String: Bool] = [:]
        for item in items { fresh[item.id] = false }
        persistChecklist(fresh, for: day)
        return fresh
    }

    /// Reconciles checklist state with an edited item list: drops removed
    /// items, defaults newly added ones to unchecked.
    public func reconcileChecklist(_ state: [String: Bool], items: [NonNegotiable], today: String = AppDate.todayKey()) -> [String: Bool] {
        var next: [String: Bool] = [:]
        for item in items { next[item.id] = state[item.id] ?? false }
        persistChecklist(next, for: today)
        return next
    }

    /// Persists the given checklist state for `day`.
    public func persistChecklist(_ state: [String: Bool], for day: String) {
        // Wrapped in {"items": ...} to stay byte-compatible with the original
        // macOS storage format.
        if let data = try? JSONEncoder().encode(["items": state]) {
            store.set(data, forKey: Keys.checklist)
            store.set(day, forKey: Keys.checklistDate)
        }
    }
}
