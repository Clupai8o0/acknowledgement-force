import Foundation

// Persistence abstraction (Dependency Inversion): engines in ForceKit write
// through this protocol instead of reaching for UserDefaults, so the macOS app
// can keep its existing UserDefaults data while the CLI (and any future
// platform) persists to a plain JSON file.

/// Minimal key-value persistence used by ForceKit engines.
public protocol KeyValueStore: AnyObject {
    func data(forKey key: String) -> Data?
    func string(forKey key: String) -> String?
    func double(forKey key: String) -> Double
    func bool(forKey key: String) -> Bool

    func set(_ value: Data?, forKey key: String)
    func set(_ value: String?, forKey key: String)
    func set(_ value: Double, forKey key: String)
    func set(_ value: Bool, forKey key: String)

    func removeValue(forKey key: String)
}

// MARK: - UserDefaults adapter

/// Adapts `UserDefaults` to ``KeyValueStore``. The macOS app uses this with
/// `UserDefaults.standard` so all pre-refactor user data keeps working.
public final class UserDefaultsKeyValueStore: KeyValueStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func data(forKey key: String) -> Data? { defaults.data(forKey: key) }
    public func string(forKey key: String) -> String? { defaults.string(forKey: key) }
    public func double(forKey key: String) -> Double { defaults.double(forKey: key) }
    public func bool(forKey key: String) -> Bool { defaults.bool(forKey: key) }

    public func set(_ value: Data?, forKey key: String) { defaults.set(value, forKey: key) }
    public func set(_ value: String?, forKey key: String) { defaults.set(value, forKey: key) }
    public func set(_ value: Double, forKey key: String) { defaults.set(value, forKey: key) }
    public func set(_ value: Bool, forKey key: String) { defaults.set(value, forKey: key) }

    public func removeValue(forKey key: String) { defaults.removeObject(forKey: key) }
}

// MARK: - File-backed store

/// A ``KeyValueStore`` persisted as a single JSON file — the cross-platform
/// backend used by the CLI on Linux/Windows (and anywhere UserDefaults isn't
/// appropriate). Writes are atomic; the file is chmod 600 on POSIX systems
/// because it can hold user content.
public final class FileKeyValueStore: KeyValueStore {
    /// JSON-representable variants a value can take on disk.
    private enum Value: Codable {
        case string(String)
        case double(Double)
        case bool(Bool)
        case data(Data)
    }

    private let url: URL
    private var values: [String: Value]

    /// - Parameter url: Location of the backing JSON file. Parent directories
    ///   are created on first write. A missing or unreadable file starts empty.
    public init(url: URL) {
        self.url = url
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: Value].self, from: data) {
            values = decoded
        } else {
            values = [:]
        }
    }

    public func data(forKey key: String) -> Data? {
        if case .data(let d)? = values[key] { return d }
        return nil
    }
    public func string(forKey key: String) -> String? {
        if case .string(let s)? = values[key] { return s }
        return nil
    }
    public func double(forKey key: String) -> Double {
        if case .double(let d)? = values[key] { return d }
        return 0
    }
    public func bool(forKey key: String) -> Bool {
        if case .bool(let b)? = values[key] { return b }
        return false
    }

    public func set(_ value: Data?, forKey key: String) {
        values[key] = value.map(Value.data)
        save()
    }
    public func set(_ value: String?, forKey key: String) {
        values[key] = value.map(Value.string)
        save()
    }
    public func set(_ value: Double, forKey key: String) {
        values[key] = .double(value)
        save()
    }
    public func set(_ value: Bool, forKey key: String) {
        values[key] = .bool(value)
        save()
    }

    public func removeValue(forKey key: String) {
        values[key] = nil
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(values) else { return }
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
        FilePermissions.restrictToOwner(url)
    }
}

/// POSIX permission helper — no-op on Windows, where NTFS ACLs already scope
/// `%APPDATA%` to the user.
public enum FilePermissions {
    /// Sets `rw-------` (0600) on the file at `url`.
    public static func restrictToOwner(_ url: URL) {
        #if !os(Windows)
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o600], ofItemAtPath: url.path)
        #endif
    }
}
