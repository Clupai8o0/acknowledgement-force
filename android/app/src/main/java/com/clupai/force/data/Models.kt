package com.clupai.force.data

import kotlinx.serialization.Serializable
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

enum class Frequency(val label: String, val detail: String) {
    EveryLaunch("Every launch", "Re-acknowledge each time Force opens."),
    Hourly("Every hour", "Re-locks one hour after each acknowledgement."),
    Every12h("Every 12 hours", "Re-locks twelve hours after each acknowledgement."),
    Daily("Once a day", "One acknowledgement carries the whole day."),
    Weekly("Once a week", "One acknowledgement carries the whole week."),
    OnLogin("On login / restart", "Re-acknowledge on every login and restart.");
}

@Serializable
data class NonNegotiable(val id: String, val label: String)

@Serializable
data class Acknowledgement(val date: String, val action: String, val timestamp: Double)

@Serializable
data class HistoryEntry(val date: String, val action: String, val timestamp: Double)

object DefaultCopy {
    const val motivation = "Execution beats planning. Commits, deployments, and documentation are the only valid measures."

    val nonNegotiables: List<NonNegotiable> = listOf(
        NonNegotiable("brush-teeth", "Brush teeth (morning & night)"),
        NonNegotiable("wash-face", "Wash face (morning & night)"),
        NonNegotiable("leetcode", "LeetCode: 1 problem minimum"),
        NonNegotiable("cold-message", "Send 1 cold message/email"),
        NonNegotiable("gym", "Gym/30min physical activity"),
        NonNegotiable("journal", "Journal: 5-10 minutes"),
        NonNegotiable("read", "Read: 15-30 minutes"),
        NonNegotiable("no-doomscroll", "No doomscrolling (sit in silence 5-10 min)"),
    )
}

object AppDate {
    fun todayKey(): String {
        val f = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        return f.format(Date())
    }
    fun longToday(): String {
        val f = SimpleDateFormat("EEEE, d MMMM yyyy", Locale("en", "AU"))
        return f.format(Date())
    }
    fun shortDate(key: String): String {
        val parser = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val d = runCatching { parser.parse(key) }.getOrNull() ?: return key
        val out = SimpleDateFormat("EEE, d MMM", Locale("en", "AU"))
        return out.format(d)
    }
    fun isSameDay(a: Date, b: Date): Boolean {
        val ca = Calendar.getInstance().apply { time = a }
        val cb = Calendar.getInstance().apply { time = b }
        return ca[Calendar.YEAR] == cb[Calendar.YEAR] && ca[Calendar.DAY_OF_YEAR] == cb[Calendar.DAY_OF_YEAR]
    }
    fun isSameWeek(a: Date, b: Date): Boolean {
        val ca = Calendar.getInstance().apply { time = a }
        val cb = Calendar.getInstance().apply { time = b }
        return ca[Calendar.YEAR] == cb[Calendar.YEAR] && ca[Calendar.WEEK_OF_YEAR] == cb[Calendar.WEEK_OF_YEAR]
    }
}
