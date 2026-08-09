import { createClient as createSupabaseClient } from "@supabase/supabase-js";

// Service-role Supabase client for server-only code paths that have already
// resolved the caller themselves (e.g. API-key middleware). RLS is bypassed,
// so every query MUST be scoped with `.eq("user_id", userId)`.
export function createAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceKey) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY"
    );
  }
  return createSupabaseClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
