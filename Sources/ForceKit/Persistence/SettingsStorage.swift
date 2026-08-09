import Foundation

/// Persisted user settings, shared by every front end.
///
/// This is plain storage with typed accessors — no UI observation. The macOS
/// app wraps it in an `ObservableObject` (`SettingsStore`); the CLI reads and
/// writes it directly. Keys match the original app's UserDefaults keys so
/// existing macOS installs keep their data after the refactor.
public final class SettingsStorage {
    public enum Keys {
        public static let frequency = "af-frequency-v1"
        public static let autoLaunch = "af-autolaunch-v1"
        public static let motivation = "af-motivation-v1"
        public static let contractText = "af-contract-text-v1"
        public static let nonNegotiables = "af-nonnegotiables-v1"
        public static let onboarded = "af-onboarded-v1"
        public static let reflection = "af-reflection-v1"
        public static let displayName = "af-display-name-v1"
    }

    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    /// How often the contract re-locks.
    public var frequency: Frequency {
        get { store.string(forKey: Keys.frequency).flatMap(Frequency.init(rawValue:)) ?? .daily }
        set { store.set(newValue.rawValue, forKey: Keys.frequency) }
    }

    /// Whether the app should be auto-launched by the platform scheduler.
    /// (Installing/removing the scheduler entry is platform code's job.)
    public var autoLaunch: Bool {
        get { store.bool(forKey: Keys.autoLaunch) }
        set { store.set(newValue, forKey: Keys.autoLaunch) }
    }

    /// The dashboard quote.
    public var motivation: String {
        get { store.string(forKey: Keys.motivation) ?? DefaultCopy.motivation }
        set { store.set(newValue, forKey: Keys.motivation) }
    }

    /// The contract source Markdown.
    public var contractText: String {
        get { store.string(forKey: Keys.contractText) ?? Contract.defaultMarkdown }
        set { store.set(newValue, forKey: Keys.contractText) }
    }

    /// Free-form reflection text, edited on the web and pulled down by sync.
    public var reflection: String {
        get { store.string(forKey: Keys.reflection) ?? "" }
        set { store.set(newValue, forKey: Keys.reflection) }
    }

    /// Substituted for `{{NAME}}` in the contract and used in greetings.
    public var displayName: String {
        get { store.string(forKey: Keys.displayName) ?? "" }
        set { store.set(newValue, forKey: Keys.displayName) }
    }

    /// Whether first-run onboarding has been completed.
    public var hasOnboarded: Bool {
        get { store.bool(forKey: Keys.onboarded) }
        set { store.set(newValue, forKey: Keys.onboarded) }
    }

    /// The editable daily checklist items.
    public var nonNegotiables: [NonNegotiable] {
        get {
            guard let data = store.data(forKey: Keys.nonNegotiables),
                  let decoded = try? JSONDecoder().decode([NonNegotiable].self, from: data)
            else { return DefaultCopy.nonNegotiables }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                store.set(data, forKey: Keys.nonNegotiables)
            }
        }
    }
}
