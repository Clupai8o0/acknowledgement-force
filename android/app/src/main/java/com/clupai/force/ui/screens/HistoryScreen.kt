package com.clupai.force.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.clupai.force.LocalAppDeps
import com.clupai.force.data.AppDate
import com.clupai.force.data.HistoryEntry
import com.clupai.force.ui.theme.AppType
import com.clupai.force.ui.theme.GhostTextButton
import com.clupai.force.ui.theme.LocalInk
import com.clupai.force.ui.theme.Radius
import com.clupai.force.ui.theme.Space

@Composable
fun HistoryScreen(onClose: () -> Unit) {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    val entries = remember { deps.store.loadHistory().take(7) }

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
            Text("PAST ACTIONS", style = AppType.headingXL, color = ink.ink, modifier = Modifier.weight(1f))
            GhostTextButton("Close", onClose, color = ink.mute)
        }

        if (entries.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(Space.xxl), contentAlignment = Alignment.Center) {
                Text("No past actions recorded yet.", style = AppType.bodyMD, color = ink.mute)
            }
        } else {
            LazyColumn(
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    horizontal = Space.lg, vertical = Space.xl,
                ),
                verticalArrangement = Arrangement.spacedBy(Space.sm),
            ) {
                items(entries, key = { it.timestamp }) { entry -> HistoryRow(entry) }
            }
        }
    }
}

@Composable
private fun HistoryRow(entry: HistoryEntry) {
    val ink = LocalInk.current
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.lg))
            .background(ink.containerLow)
            .padding(Space.lg),
        verticalArrangement = Arrangement.spacedBy(Space.xs),
    ) {
        Text(AppDate.shortDate(entry.date), style = AppType.captionSM, color = ink.mute)
        Text(entry.action, style = AppType.bodyStrong, color = ink.ink)
    }
}
