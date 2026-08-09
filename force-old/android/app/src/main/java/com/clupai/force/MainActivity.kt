package com.clupai.force

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.clupai.force.ui.screens.ContractScreen
import com.clupai.force.ui.screens.DashboardScreen
import com.clupai.force.ui.screens.HistoryScreen
import com.clupai.force.ui.screens.OnboardingScreen
import com.clupai.force.ui.screens.SettingsScreen
import com.clupai.force.ui.theme.ForceTheme
import com.clupai.force.ui.theme.LocalInk

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val app = application as ForceApp
        val deps = AppDeps(app.settings, app.store, app.remote, app.themeManager)

        setContent {
            ForceTheme(themeManager = app.themeManager) {
                CompositionLocalProvider(LocalAppDeps provides deps) {
                    val ink = LocalInk.current
                    Surface(Modifier.fillMaxSize(), color = ink.base) {
                        RootRouter()
                    }
                    LaunchedEffect(Unit) { deps.remote.launchSync() }
                }
            }
        }
    }
}

private enum class Route { Dashboard, History, Settings }

@androidx.compose.runtime.Composable
private fun RootRouter() {
    val deps = LocalAppDeps.current
    var route by remember { mutableStateOf(Route.Dashboard) }

    when {
        !deps.settings.hasOnboarded.value -> OnboardingScreen()
        !deps.store.gateOpen.value -> ContractScreen()
        else -> when (route) {
            Route.Dashboard -> DashboardScreen(
                onOpenHistory = { route = Route.History },
                onOpenSettings = { route = Route.Settings },
            )
            Route.History -> HistoryScreen(onClose = { route = Route.Dashboard })
            Route.Settings -> SettingsScreen(
                onClose = { route = Route.Dashboard },
                onExit = { android.os.Process.killProcess(android.os.Process.myPid()) },
            )
        }
    }
}
