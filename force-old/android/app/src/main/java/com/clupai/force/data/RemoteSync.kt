package com.clupai.force.data

import android.content.Context
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.add
import kotlinx.serialization.json.buildJsonArray
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

sealed class SyncStatus {
    object NeedsConfig : SyncStatus()
    object LoggedOut : SyncStatus()
    object Syncing : SyncStatus()
    data class Synced(val at: Long) : SyncStatus()
    data class Error(val message: String) : SyncStatus()
}

class RemoteSync(context: Context, private val settings: SettingsStore) {
    private val prefs = context.getSharedPreferences("force-sync", Context.MODE_PRIVATE)
    private val client = OkHttpClient()
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    val baseURL: MutableState<String> = mutableStateOf(prefs.getString(KEY_URL, "") ?: "")
    val anonKey: MutableState<String> = mutableStateOf(prefs.getString(KEY_ANON, "") ?: "")
    val email: MutableState<String?> = mutableStateOf(prefs.getString(KEY_EMAIL, null))
    val status: MutableState<SyncStatus> = mutableStateOf(SyncStatus.LoggedOut)
    val localDirty: MutableState<Boolean> = mutableStateOf(prefs.getBoolean(KEY_DIRTY, false))

    init {
        status.value = when {
            !isConfigured -> SyncStatus.NeedsConfig
            isLoggedIn -> SyncStatus.Synced(0L)
            else -> SyncStatus.LoggedOut
        }
        settings.onLocalEdit = ::markLocalEdit
    }

    fun setBaseURL(v: String) {
        baseURL.value = v
        prefs.edit().putString(KEY_URL, v).apply()
        if (status.value == SyncStatus.NeedsConfig && isConfigured) {
            status.value = if (isLoggedIn) SyncStatus.Synced(0L) else SyncStatus.LoggedOut
        } else if (!isConfigured) status.value = SyncStatus.NeedsConfig
    }

    fun setAnonKey(v: String) {
        anonKey.value = v
        prefs.edit().putString(KEY_ANON, v).apply()
        if (status.value == SyncStatus.NeedsConfig && isConfigured) {
            status.value = if (isLoggedIn) SyncStatus.Synced(0L) else SyncStatus.LoggedOut
        } else if (!isConfigured) status.value = SyncStatus.NeedsConfig
    }

    val effectiveURL: String get() = baseURL.value.trim().ifEmpty { SupabaseConfig.url }
    val effectiveAnonKey: String get() = anonKey.value.trim().ifEmpty { SupabaseConfig.anonKey }

    val isConfigured: Boolean get() = effectiveURL.isNotEmpty() && effectiveAnonKey.isNotEmpty()
    val isLoggedIn: Boolean get() = !prefs.getString(KEY_ACCESS, null).isNullOrEmpty()

    private var accessToken: String?
        get() = prefs.getString(KEY_ACCESS, null)
        set(v) { prefs.edit().putString(KEY_ACCESS, v).apply() }
    private var refreshToken: String?
        get() = prefs.getString(KEY_REFRESH, null)
        set(v) { prefs.edit().putString(KEY_REFRESH, v).apply() }
    private var userId: String?
        get() = prefs.getString(KEY_USER, null)
        set(v) { prefs.edit().putString(KEY_USER, v).apply() }
    private var localUpdatedAt: Long
        get() = prefs.getLong(KEY_LOCAL_MS, 0L)
        set(v) { prefs.edit().putLong(KEY_LOCAL_MS, v).apply() }

    fun markLocalEdit() {
        localUpdatedAt = System.currentTimeMillis()
        localDirty.value = true
        prefs.edit().putBoolean(KEY_DIRTY, true).apply()
    }

    private fun clearDirty() {
        localDirty.value = false
        prefs.edit().putBoolean(KEY_DIRTY, false).apply()
    }

    suspend fun launchSync() {
        if (!isConfigured || !isLoggedIn) return
        syncNow()
    }

    suspend fun login(rawEmail: String, password: String) {
        val emailIn = rawEmail.trim()
        if (!isConfigured) { status.value = SyncStatus.NeedsConfig; return }
        if (emailIn.isEmpty() || password.isEmpty()) {
            status.value = SyncStatus.Error("Enter your email and password.")
            return
        }
        status.value = SyncStatus.Syncing
        runCatching {
            val token = requestToken("password", mapOf("email" to emailIn, "password" to password))
            store(token, token.user.email ?: emailIn)
            syncNow()
        }.onFailure { status.value = SyncStatus.Error(messageFor(it)) }
    }

    fun logout() {
        accessToken = null
        refreshToken = null
        userId = null
        email.value = null
        prefs.edit().remove(KEY_EMAIL).apply()
        status.value = SyncStatus.LoggedOut
    }

    /// Last-write-wins reconciliation.
    suspend fun syncNow() {
        if (!isConfigured || !isLoggedIn) return
        status.value = SyncStatus.Syncing
        runCatching {
            val cloud = fetchContent(retryOn401 = true)
            val cloudMs = parseTimestamp(cloud.updated_at)
            if (localDirty.value && localUpdatedAt > cloudMs) {
                push(retryOn401 = true)
            } else {
                apply(cloud)
                localUpdatedAt = cloudMs
            }
            clearDirty()
            status.value = SyncStatus.Synced(System.currentTimeMillis())
        }.onFailure { status.value = SyncStatus.Error(messageFor(it)) }
    }

    suspend fun pushIfDirty() {
        if (!isConfigured || !isLoggedIn || !localDirty.value) return
        status.value = SyncStatus.Syncing
        runCatching {
            push(retryOn401 = true)
            clearDirty()
            status.value = SyncStatus.Synced(System.currentTimeMillis())
        }.onFailure { status.value = SyncStatus.Error(messageFor(it)) }
    }

    // MARK: Apply (cloud -> local)
    private fun apply(c: RemoteContent) {
        settings.applyingRemote {
            val md = c.contract_md.trim()
            if (md.isNotEmpty()) settings.setContractText(c.contract_md)
            if (c.goals.isNotEmpty()) {
                settings.setNonNegotiables(c.goals.map { NonNegotiable(it.id, it.label) })
            }
            val quotes = c.quotes.map { it.trim() }.filter { it.isNotEmpty() }
            quotes.randomOrNull()?.let { settings.setMotivation(it) }
            settings.setReflection(c.reflection)
        }
    }

    // MARK: Networking
    private suspend fun fetchContent(retryOn401: Boolean): RemoteContent = withContext(Dispatchers.IO) {
        val token = accessToken ?: throw SyncException("Not logged in.")
        val req = Request.Builder()
            .url(restURL())
            .header("apikey", effectiveAnonKey)
            .header("Authorization", "Bearer $token")
            .header("Accept", "application/json")
            .get()
            .build()
        client.newCall(req).execute().use { resp ->
            if (resp.code == 401 && retryOn401) {
                refreshSession()
                return@use fetchContent(retryOn401 = false)
            }
            if (!resp.isSuccessful) {
                throw SyncException(serverMessage(resp.body?.string()) ?: "Request failed (${resp.code}).")
            }
            val body = resp.body!!.string()
            val rows = json.decodeFromString(ListSerializer(RemoteContent.serializer()), body)
            return@use rows.firstOrNull() ?: throw SyncException("No contract found for this account.")
        }
    }

    private suspend fun push(retryOn401: Boolean): Unit = withContext(Dispatchers.IO) {
        val token = accessToken ?: throw SyncException("Not logged in.")
        val uid = userId ?: throw SyncException("Not logged in.")
        val body = buildJsonObject {
            put("contract_md", settings.contractText.value)
            put("goals", buildJsonArray {
                for (g in settings.nonNegotiables) {
                    add(buildJsonObject { put("id", g.id); put("label", g.label) })
                }
            })
        }
        val req = Request.Builder()
            .url(patchURL(uid))
            .header("apikey", effectiveAnonKey)
            .header("Authorization", "Bearer $token")
            .header("Content-Type", "application/json")
            .header("Prefer", "return=minimal")
            .patch(body.toString().toRequestBody("application/json".toMediaType()))
            .build()
        client.newCall(req).execute().use { resp ->
            if (resp.code == 401 && retryOn401) {
                refreshSession()
                return@use push(retryOn401 = false)
            }
            if (!resp.isSuccessful) {
                throw SyncException(serverMessage(resp.body?.string()) ?: "Save failed (${resp.code}).")
            }
        }
    }

    private suspend fun refreshSession() {
        val refresh = refreshToken ?: throw SyncException("Not logged in.")
        val token = requestToken("refresh_token", mapOf("refresh_token" to refresh))
        store(token, token.user.email ?: email.value ?: "")
    }

    private suspend fun requestToken(grant: String, body: Map<String, String>): TokenResponse = withContext(Dispatchers.IO) {
        val url = authBase().toHttpUrl().newBuilder().addQueryParameter("grant_type", grant).build()
        val payload = buildJsonObject { for ((k, v) in body) put(k, v) }.toString()
        val req = Request.Builder()
            .url(url)
            .header("apikey", effectiveAnonKey)
            .header("Content-Type", "application/json")
            .post(payload.toRequestBody("application/json".toMediaType()))
            .build()
        client.newCall(req).execute().use { resp ->
            if (!resp.isSuccessful) {
                if (grant == "refresh_token") logout()
                throw SyncException(serverMessage(resp.body?.string()) ?: "Login failed (${resp.code}).")
            }
            json.decodeFromString(TokenResponse.serializer(), resp.body!!.string())
        }
    }

    private fun store(token: TokenResponse, emailIn: String) {
        accessToken = token.access_token
        refreshToken = token.refresh_token
        userId = token.user.id
        email.value = emailIn
        prefs.edit().putString(KEY_EMAIL, emailIn).apply()
    }

    // MARK: URL helpers
    private fun normalizedBase(): String {
        var s = effectiveURL
        if (s.endsWith("/")) s = s.dropLast(1)
        if (!s.startsWith("http")) throw SyncException("Check the Supabase URL and key.")
        return s
    }
    private fun authBase() = "${normalizedBase()}/auth/v1/token"
    private fun restURL() = "${normalizedBase()}/rest/v1/contents".toHttpUrl().newBuilder()
        .addQueryParameter("select", "contract_md,quotes,goals,reflection,updated_at")
        .addQueryParameter("limit", "1")
        .build()
    private fun patchURL(uid: String) = "${normalizedBase()}/rest/v1/contents".toHttpUrl().newBuilder()
        .addQueryParameter("user_id", "eq.$uid")
        .build()

    private fun parseTimestamp(s: String?): Long {
        if (s == null) return 0L
        // Trim fractional seconds to 3 digits for ISO-8601.
        val cleaned = run {
            val dot = s.indexOf('.')
            if (dot < 0) s else {
                var i = dot + 1; val frac = StringBuilder()
                while (i < s.length && s[i].isDigit()) { frac.append(s[i]); i++ }
                val ms = frac.toString().take(3)
                s.substring(0, dot) + (if (ms.isEmpty()) "" else ".$ms") + s.substring(i)
            }
        }
        for (pattern in listOf("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", "yyyy-MM-dd'T'HH:mm:ssXXX")) {
            try {
                val f = SimpleDateFormat(pattern, Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
                return f.parse(cleaned)?.time ?: 0L
            } catch (_: Throwable) {}
        }
        return 0L
    }

    private fun serverMessage(body: String?): String? {
        if (body.isNullOrEmpty()) return null
        return runCatching {
            val obj = json.parseToJsonElement(body) as? JsonObject ?: return null
            (obj["error_description"]?.toString()
                ?: obj["msg"]?.toString()
                ?: obj["message"]?.toString()
                ?: obj["error"]?.toString())?.trim('"')
        }.getOrNull()
    }

    private fun messageFor(t: Throwable): String = when (t) {
        is SyncException -> t.message ?: "Sync error"
        is IOException -> t.localizedMessage ?: "Network error"
        else -> t.localizedMessage ?: "Sync error"
    }

    companion object {
        private const val KEY_URL = "af-supabase-url-v1"
        private const val KEY_ANON = "af-supabase-anon-v1"
        private const val KEY_ACCESS = "af-supabase-access-v1"
        private const val KEY_REFRESH = "af-supabase-refresh-v1"
        private const val KEY_EMAIL = "af-supabase-email-v1"
        private const val KEY_USER = "af-supabase-userid-v1"
        private const val KEY_DIRTY = "af-sync-dirty-v1"
        private const val KEY_LOCAL_MS = "af-sync-local-ms-v1"
    }
}

class SyncException(message: String) : Exception(message)

@Serializable
private data class TokenResponse(val access_token: String, val refresh_token: String, val user: TokenUser)
@Serializable
private data class TokenUser(val id: String, val email: String? = null)
@Serializable
private data class RemoteGoal(val id: String, val label: String)
@Serializable
private data class RemoteContent(
    val contract_md: String,
    val quotes: List<String> = emptyList(),
    val goals: List<RemoteGoal> = emptyList(),
    val reflection: String = "",
    val updated_at: String? = null,
)
