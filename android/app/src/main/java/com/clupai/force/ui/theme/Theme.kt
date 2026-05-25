package com.clupai.force.ui.theme

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.runtime.remember
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.foundation.isSystemInDarkTheme
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

// Color helper: 0xRRGGBB -> Compose Color.
fun rgb(hex: Int): Color {
    val r = (hex shr 16) and 0xFF
    val g = (hex shr 8) and 0xFF
    val b = hex and 0xFF
    return Color(r / 255f, g / 255f, b / 255f, 1f)
}

fun Color.toRgbHex(): Int {
    val r = (red * 255f).toInt().coerceIn(0, 255)
    val g = (green * 255f).toInt().coerceIn(0, 255)
    val b = (blue * 255f).toInt().coerceIn(0, 255)
    return (r shl 16) or (g shl 8) or b
}

enum class AppearanceMode(val label: String) {
    Light("Light"), Dark("Dark"), System("Follow System");
}

// The Digital Curator palette — strictly monochrome, surface tiers stacked
// like sheets of cotton paper; structural boundaries from tonal shifts.
@Serializable
data class ThemePalette(
    val base: Int,
    val containerLow: Int,
    val container: Int,
    val containerHigh: Int,
    val containerHighest: Int,
    val bright: Int,
    val ink: Int,
    val inkContainer: Int,
    val ash: Int,
    val mute: Int,
    val stone: Int,
    val outline: Int,
    val outlineSoft: Int,
    val onPrimary: Int,
) {
    companion object {
        val Light = ThemePalette(
            base = 0xF9F9F9, containerLow = 0xF3F3F3, container = 0xEEEEEE,
            containerHigh = 0xE8E8E8, containerHighest = 0xE3E3E3, bright = 0xFFFFFF,
            ink = 0x1A1C1C, inkContainer = 0x3A3C3D, ash = 0x2E3133,
            mute = 0x6B6F72, stone = 0xA9ADB0, outline = 0xC4C7C9, outlineSoft = 0xD8DADC,
            onPrimary = 0xFFFFFF,
        )
        val Dark = ThemePalette(
            base = 0x141515, containerLow = 0x1B1C1D, container = 0x222324,
            containerHigh = 0x2A2B2C, containerHighest = 0x313334, bright = 0x3A3C3D,
            ink = 0xF2F2F0, inkContainer = 0xC9C9C6, ash = 0xDADAD7,
            mute = 0x9A9E9F, stone = 0x60646A, outline = 0x3C3F40, outlineSoft = 0x2A2C2D,
            onPrimary = 0x141515,
        )
    }
}

// Resolved Ink namespace — read from CompositionLocal at call sites.
class Ink internal constructor(p: ThemePalette) {
    val base = rgb(p.base)
    val containerLow = rgb(p.containerLow)
    val container = rgb(p.container)
    val containerHigh = rgb(p.containerHigh)
    val containerHighest = rgb(p.containerHighest)
    val bright = rgb(p.bright)
    val ink = rgb(p.ink)
    val inkContainer = rgb(p.inkContainer)
    val ash = rgb(p.ash)
    val mute = rgb(p.mute)
    val stone = rgb(p.stone)
    val outline = rgb(p.outline)
    val outlineSoft = rgb(p.outlineSoft)
    val onPrimary = rgb(p.onPrimary)
    val onSurfaceVariant get() = mute
    val charcoal get() = inkContainer
    val hairline get() = outline
    val hairlineSoft get() = outlineSoft
}

val LocalInk = compositionLocalOf<Ink> { Ink(ThemePalette.Dark) }

// Manages theme persistence to SharedPreferences. Held as a single instance
// in ForceApp and exposed via CompositionLocal for the whole tree.
class ThemeManager(context: Context) {
    private val prefs = context.getSharedPreferences("force-theme", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true }

    val mode: MutableState<AppearanceMode> = mutableStateOf(loadMode())
    val lightTheme: MutableState<ThemePalette> = mutableStateOf(loadTheme(KEY_LIGHT) ?: ThemePalette.Light)
    val darkTheme: MutableState<ThemePalette> = mutableStateOf(loadTheme(KEY_DARK) ?: ThemePalette.Dark)

    fun setMode(m: AppearanceMode) {
        mode.value = m
        prefs.edit().putString(KEY_MODE, m.name).apply()
    }

    fun updateActive(systemDark: Boolean, transform: (ThemePalette) -> ThemePalette) {
        val editingDark = editingIsDark(systemDark)
        if (editingDark) {
            darkTheme.value = transform(darkTheme.value).also { persist(it, KEY_DARK) }
        } else {
            lightTheme.value = transform(lightTheme.value).also { persist(it, KEY_LIGHT) }
        }
    }

    fun resetActive(systemDark: Boolean) {
        if (editingIsDark(systemDark)) {
            darkTheme.value = ThemePalette.Dark
            persist(darkTheme.value, KEY_DARK)
        } else {
            lightTheme.value = ThemePalette.Light
            persist(lightTheme.value, KEY_LIGHT)
        }
    }

    fun editingIsDark(systemDark: Boolean) = when (mode.value) {
        AppearanceMode.Light -> false
        AppearanceMode.Dark -> true
        AppearanceMode.System -> systemDark
    }

    fun effective(systemDark: Boolean): ThemePalette = when (mode.value) {
        AppearanceMode.Light -> lightTheme.value
        AppearanceMode.Dark -> darkTheme.value
        AppearanceMode.System -> if (systemDark) darkTheme.value else lightTheme.value
    }

    private fun persist(p: ThemePalette, key: String) {
        prefs.edit().putString(key, json.encodeToString(p)).apply()
    }
    private fun loadTheme(key: String): ThemePalette? = runCatching {
        prefs.getString(key, null)?.let { json.decodeFromString<ThemePalette>(it) }
    }.getOrNull()
    private fun loadMode(): AppearanceMode = runCatching {
        AppearanceMode.valueOf(prefs.getString(KEY_MODE, AppearanceMode.Dark.name)!!)
    }.getOrDefault(AppearanceMode.Dark)

    companion object {
        private const val KEY_MODE = "af-appearance-mode-v1"
        private const val KEY_LIGHT = "af-theme-light-v1"
        private const val KEY_DARK = "af-theme-dark-v1"
    }
}

val LocalThemeManager = compositionLocalOf<ThemeManager> { error("ThemeManager not provided") }

@Composable
fun ForceTheme(themeManager: ThemeManager, content: @Composable () -> Unit) {
    val systemDark = isSystemInDarkTheme()
    // Recompose on any of the three observed mutable states.
    val mode = themeManager.mode.value
    val light = themeManager.lightTheme.value
    val dark = themeManager.darkTheme.value
    val palette = remember(mode, light, dark, systemDark) { themeManager.effective(systemDark) }
    val ink = remember(palette) { Ink(palette) }
    CompositionLocalProvider(LocalInk provides ink, LocalThemeManager provides themeManager) {
        content()
    }
}
