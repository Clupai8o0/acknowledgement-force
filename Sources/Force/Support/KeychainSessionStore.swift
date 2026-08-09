import Foundation
import Security
import ForceKit

/// Keychain-backed ``SessionStore`` — the macOS home for the Supabase session.
///
/// The session (access + refresh token) is a long-lived credential; the
/// Keychain keeps it encrypted at rest and out of plaintext plists/backups,
/// unlike the UserDefaults storage this app used historically (see
/// ``RemoteSync`` for the one-time migration).
final class KeychainSessionStore: SessionStore {
    private let service = "com.acknowledgementforce.sync"
    private let account = "supabase-session"

    func load() -> SupabaseSession? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return try? JSONDecoder().decode(SupabaseSession.self, from: data)
    }

    func save(_ session: SupabaseSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        // Replace-then-add keeps this idempotent across repeated logins.
        SecItemDelete(baseQuery() as CFDictionary)

        var attributes = baseQuery()
        attributes[kSecValueData as String] = data
        // Readable after first unlock so the launchd-driven launch can sync,
        // but never migrates to another device via backups.
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func clear() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
