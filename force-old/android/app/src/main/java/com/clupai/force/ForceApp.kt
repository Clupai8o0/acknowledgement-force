package com.clupai.force

import android.app.Application
import com.clupai.force.data.AppStore
import com.clupai.force.data.RemoteSync
import com.clupai.force.data.SettingsStore
import com.clupai.force.ui.theme.ThemeManager

class ForceApp : Application() {
    lateinit var settings: SettingsStore
        private set
    lateinit var store: AppStore
        private set
    lateinit var remote: RemoteSync
        private set
    lateinit var themeManager: ThemeManager
        private set

    override fun onCreate() {
        super.onCreate()
        settings = SettingsStore(this)
        store = AppStore(this, settings)
        remote = RemoteSync(this, settings)
        themeManager = ThemeManager(this)
    }
}
