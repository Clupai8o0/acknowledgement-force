package com.clupai.force

import androidx.compose.runtime.compositionLocalOf
import com.clupai.force.data.AppStore
import com.clupai.force.data.RemoteSync
import com.clupai.force.data.SettingsStore
import com.clupai.force.ui.theme.ThemeManager

class AppDeps(
    val settings: SettingsStore,
    val store: AppStore,
    val remote: RemoteSync,
    val themeManager: ThemeManager,
)

val LocalAppDeps = compositionLocalOf<AppDeps> { error("AppDeps not provided") }
