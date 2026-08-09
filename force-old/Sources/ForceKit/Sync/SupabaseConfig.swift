import Foundation

// Build-time Supabase configuration baked into release binaries.
//
// The placeholder tokens below are rewritten by install.sh when the
// FORCE_SUPABASE_URL / FORCE_SUPABASE_ANON_KEY environment variables are set,
// so a distributed build ships with the connection already configured and
// users only have to log in. Left as placeholders in dev builds, in which case
// the values must be entered in Settings → Sync (or `force-cli config`).
//
// The anon key is the *public* Supabase key, protected by row-level security —
// it is safe to embed in the client. Never bake a service key.
public enum SupabaseConfig {
    private static let bakedURL = "__FORCE_SUPABASE_URL__"
    private static let bakedAnonKey = "__FORCE_SUPABASE_ANON_KEY__"

    /// A placeholder that was never substituted resolves to empty.
    private static func resolved(_ value: String) -> String {
        value.hasPrefix("__FORCE_") ? "" : value
    }

    public static var url: String { resolved(bakedURL) }
    public static var anonKey: String { resolved(bakedAnonKey) }
}
