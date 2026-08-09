package com.clupai.force.data

import com.clupai.force.BuildConfig

// Build-time defaults for hosted Supabase project. User-entered values in
// Settings (Edit connection) override these. Mirrors SupabaseConfig.swift.
object SupabaseConfig {
    val url: String get() = BuildConfig.SUPABASE_URL
    val anonKey: String get() = BuildConfig.SUPABASE_ANON_KEY
}
