package com.clupai.force.data

import android.content.Context
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.snapshots.SnapshotStateMap
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import java.util.Date

// Mirror of Store.swift: gate computation, checklist, history.
class AppStore(context: Context, private val settings: SettingsStore) {
    private val prefs = context.getSharedPreferences("force-store", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true }

    val checklistState: SnapshotStateMap<String, Boolean> = mutableStateMapOf()
    val todayAction: MutableState<String> = mutableStateOf("")
    val gateOpen: MutableState<Boolean> = mutableStateOf(false)
    private var sessionAcknowledged = false

    init {
        loadAcknowledgement()?.let { todayAction.value = it.action }
        loadOrResetChecklist(AppDate.todayKey())
        recomputeGate()
        settings.onNonNegotiablesChanged = { syncChecklist() }
    }

    // MARK: Period gate
    private val lastAckMs: Long get() = prefs.getLong(KEY_LAST_ACK_L, 0L)

    fun recomputeGate() { gateOpen.value = isSatisfied() }

    private fun isSatisfied(): Boolean {
        val last = lastAckMs
        if (last <= 0L) return false
        val lastDate = Date(last)
        val now = Date()
        return when (settings.frequency.value) {
            Frequency.EveryLaunch, Frequency.OnLogin -> sessionAcknowledged
            Frequency.Hourly -> now.time - lastDate.time < 3_600_000
            Frequency.Every12h -> now.time - lastDate.time < 43_200_000
            Frequency.Daily -> AppDate.isSameDay(lastDate, now)
            Frequency.Weekly -> AppDate.isSameWeek(lastDate, now)
        }
    }

    // MARK: Acknowledgement
    fun loadAcknowledgement(): Acknowledgement? = runCatching {
        prefs.getString(KEY_ACK, null)?.let { json.decodeFromString(Acknowledgement.serializer(), it) }
    }.getOrNull()

    fun confirm(action: String) {
        val today = AppDate.todayKey()
        val nowMs = System.currentTimeMillis().toDouble()
        val ack = Acknowledgement(today, action, nowMs)
        prefs.edit()
            .putString(KEY_ACK, json.encodeToString(Acknowledgement.serializer(), ack))
            .putLong(KEY_LAST_ACK_L, nowMs.toLong())
            .apply()
        addToHistory(action, today)
        resetChecklist(today)
        sessionAcknowledged = true
        todayAction.value = action
        gateOpen.value = true
    }

    fun updateTodayAction(newAction: String) {
        val trimmed = newAction.trim()
        if (trimmed.isEmpty() || trimmed == todayAction.value) return
        val today = AppDate.todayKey()
        todayAction.value = trimmed
        loadAcknowledgement()?.let { ack ->
            val updated = ack.copy(action = trimmed)
            prefs.edit().putString(KEY_ACK, json.encodeToString(Acknowledgement.serializer(), updated)).apply()
        }
        val history = loadHistory().toMutableList()
        val idx = history.indexOfFirst { it.date == today }
        if (idx >= 0) history[idx] = history[idx].copy(action = trimmed)
        else history.add(0, HistoryEntry(today, trimmed, System.currentTimeMillis().toDouble()))
        saveHistory(history)
    }

    // MARK: Checklist
    private fun loadOrResetChecklist(today: String) {
        val storedDate = prefs.getString(KEY_CHECKLIST_DATE, null)
        if (storedDate == today) {
            val map = runCatching {
                prefs.getString(KEY_CHECKLIST, null)?.let {
                    json.decodeFromString(MapSerializer(String.serializer(), Boolean.serializer()), it)
                }
            }.getOrNull()
            if (map != null) {
                checklistState.clear()
                checklistState.putAll(map)
                return
            }
        }
        resetChecklist(today)
    }

    private fun resetChecklist(today: String) {
        checklistState.clear()
        for (item in settings.nonNegotiables) checklistState[item.id] = false
        persistChecklist(today)
    }

    fun syncChecklist() {
        val next = mutableMapOf<String, Boolean>()
        for (item in settings.nonNegotiables) next[item.id] = checklistState[item.id] ?: false
        checklistState.clear()
        checklistState.putAll(next)
        persistChecklist(AppDate.todayKey())
    }

    fun toggle(id: String) {
        checklistState[id] = !(checklistState[id] ?: false)
        persistChecklist(AppDate.todayKey())
    }

    private fun persistChecklist(today: String) {
        val data = json.encodeToString(
            MapSerializer(String.serializer(), Boolean.serializer()),
            checklistState.toMap(),
        )
        prefs.edit().putString(KEY_CHECKLIST, data).putString(KEY_CHECKLIST_DATE, today).apply()
    }

    val completedCount: Int get() = settings.nonNegotiables.count { checklistState[it.id] == true }
    val totalCount: Int get() = settings.nonNegotiables.size

    // MARK: History
    fun loadHistory(): List<HistoryEntry> = runCatching {
        prefs.getString(KEY_HISTORY, null)?.let {
            json.decodeFromString(ListSerializer(HistoryEntry.serializer()), it)
        } ?: emptyList()
    }.getOrDefault(emptyList())

    private fun saveHistory(entries: List<HistoryEntry>) {
        prefs.edit().putString(
            KEY_HISTORY,
            json.encodeToString(ListSerializer(HistoryEntry.serializer()), entries),
        ).apply()
    }

    private fun addToHistory(action: String, date: String) {
        val cutoff = System.currentTimeMillis() - 30L * 24 * 3600 * 1000
        val parser = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
        val filtered = loadHistory().filter {
            (runCatching { parser.parse(it.date)?.time }.getOrNull() ?: 0L) >= cutoff
        }
        val updated = listOf(HistoryEntry(date, action, System.currentTimeMillis().toDouble())) + filtered
        saveHistory(updated)
    }

    companion object {
        private const val KEY_ACK = "af-acknowledgement-v1"
        private const val KEY_CHECKLIST = "af-checklist-v1"
        private const val KEY_CHECKLIST_DATE = "af-checklist-v1-date"
        private const val KEY_HISTORY = "af-history-v1"
        private const val KEY_LAST_ACK_L = "af-last-ack-ms-l-v1"
    }
}
