package com.clupai.force.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.clupai.force.LocalAppDeps
import com.clupai.force.ui.theme.AppType
import com.clupai.force.ui.theme.GhostTextButton
import com.clupai.force.ui.theme.LocalInk
import com.clupai.force.ui.theme.Space
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(onClose: () -> Unit, onExit: () -> Unit) {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    val scope = rememberCoroutineScope()

    // Push pending edits on exit, mirroring the macOS `.onDisappear`.
    DisposableEffect(Unit) {
        onDispose { scope.launch { deps.remote.pushIfDirty() } }
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(ink.base),
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .background(ink.containerLow)
                .padding(horizontal = Space.lg, vertical = Space.xl),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("SETTINGS", style = AppType.headingXL, color = ink.ink, modifier = Modifier.weight(1f))
            GhostTextButton("Done", onClose, color = ink.mute)
        }
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Space.lg, vertical = Space.xl),
            verticalArrangement = Arrangement.spacedBy(Space.xxl),
        ) {
            ProfileSection()
            AppearanceSection()
            ScheduleSection()
            SyncSection()
            MessagesSection()
            NonNegotiablesSection()
            EmergencyStopSection(onStop = onExit)
        }
    }
}
