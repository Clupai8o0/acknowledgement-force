package com.clupai.force.data

import android.content.Context
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.snapshots.SnapshotStateList
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class SettingsStore(context: Context) {
    private val prefs = context.getSharedPreferences("force-settings", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true }
    private var applyingRemote = false
    var onLocalEdit: (() -> Unit)? = null
    var onNonNegotiablesChanged: (() -> Unit)? = null

    val frequency: MutableState<Frequency> = mutableStateOf(loadFrequency())
    val hasOnboarded: MutableState<Boolean> = mutableStateOf(prefs.getBoolean(KEY_ONBOARDED, false))
    val displayName: MutableState<String> = mutableStateOf(prefs.getString(KEY_NAME, "") ?: "")
    val motivation: MutableState<String> = mutableStateOf(prefs.getString(KEY_MOTIVATION, null) ?: DefaultCopy.motivation)
    val contractText: MutableState<String> = mutableStateOf(prefs.getString(KEY_CONTRACT, null) ?: Contract.defaultMarkdown)
    val reflection: MutableState<String> = mutableStateOf(prefs.getString(KEY_REFLECTION, "") ?: "")
    val nonNegotiables: SnapshotStateList<NonNegotiable> = mutableStateListOf<NonNegotiable>().apply {
        addAll(loadNonNegotiables() ?: DefaultCopy.nonNegotiables)
    }

    fun setFrequency(f: Frequency) {
        frequency.value = f
        prefs.edit().putString(KEY_FREQ, f.name).apply()
    }
    fun setHasOnboarded(v: Boolean) {
        hasOnboarded.value = v
        prefs.edit().putBoolean(KEY_ONBOARDED, v).apply()
    }
    fun setDisplayName(v: String) {
        displayName.value = v
        prefs.edit().putString(KEY_NAME, v).apply()
    }
    fun setMotivation(v: String) {
        motivation.value = v
        prefs.edit().putString(KEY_MOTIVATION, v).apply()
        if (!applyingRemote) onLocalEdit?.invoke()
    }
    fun setContractText(v: String) {
        contractText.value = v
        prefs.edit().putString(KEY_CONTRACT, v).apply()
        if (!applyingRemote) onLocalEdit?.invoke()
    }
    fun setReflection(v: String) {
        reflection.value = v
        prefs.edit().putString(KEY_REFLECTION, v).apply()
    }
    fun setNonNegotiables(items: List<NonNegotiable>) {
        nonNegotiables.clear()
        nonNegotiables.addAll(items)
        persistNonNegotiables()
        onNonNegotiablesChanged?.invoke()
        if (!applyingRemote) onLocalEdit?.invoke()
    }
    fun updateNonNegotiableLabel(id: String, label: String) {
        val idx = nonNegotiables.indexOfFirst { it.id == id }
        if (idx >= 0) {
            nonNegotiables[idx] = nonNegotiables[idx].copy(label = label)
            persistNonNegotiables()
            if (!applyingRemote) onLocalEdit?.invoke()
        }
    }
    fun removeNonNegotiable(id: String) {
        nonNegotiables.removeAll { it.id == id }
        persistNonNegotiables()
        onNonNegotiablesChanged?.invoke()
        if (!applyingRemote) onLocalEdit?.invoke()
    }
    fun addNonNegotiable(item: NonNegotiable) {
        nonNegotiables.add(item)
        persistNonNegotiables()
        onNonNegotiablesChanged?.invoke()
        if (!applyingRemote) onLocalEdit?.invoke()
    }

    /// Guarded mutation block for RemoteSync applying cloud edits.
    fun applyingRemote(block: () -> Unit) {
        applyingRemote = true
        try { block() } finally { applyingRemote = false }
    }

    private fun persistNonNegotiables() {
        val data = json.encodeToString(ListSerializer(NonNegotiable.serializer()), nonNegotiables.toList())
        prefs.edit().putString(KEY_NN, data).apply()
    }
    private fun loadNonNegotiables(): List<NonNegotiable>? = runCatching {
        prefs.getString(KEY_NN, null)?.let { json.decodeFromString(ListSerializer(NonNegotiable.serializer()), it) }
    }.getOrNull()
    private fun loadFrequency(): Frequency = runCatching {
        Frequency.valueOf(prefs.getString(KEY_FREQ, Frequency.Daily.name)!!)
    }.getOrDefault(Frequency.Daily)

    companion object {
        private const val KEY_FREQ = "af-frequency-v1"
        private const val KEY_ONBOARDED = "af-onboarded-v1"
        private const val KEY_NAME = "af-display-name-v1"
        private const val KEY_MOTIVATION = "af-motivation-v1"
        private const val KEY_CONTRACT = "af-contract-text-v1"
        private const val KEY_REFLECTION = "af-reflection-v1"
        private const val KEY_NN = "af-nonnegotiables-v1"
    }
}
