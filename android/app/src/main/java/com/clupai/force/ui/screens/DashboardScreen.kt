package com.clupai.force.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.clupai.force.LocalAppDeps
import com.clupai.force.data.AppDate
import com.clupai.force.data.Contract
import com.clupai.force.data.NonNegotiable
import com.clupai.force.ui.components.ContractBlocks
import com.clupai.force.ui.theme.AppType
import com.clupai.force.ui.theme.GhostTextButton
import com.clupai.force.ui.theme.LocalInk
import com.clupai.force.ui.theme.Radius
import com.clupai.force.ui.theme.RoundCheckbox
import com.clupai.force.ui.theme.Space
import com.clupai.force.ui.theme.primaryGradient

@Composable
fun DashboardScreen(
    onOpenHistory: () -> Unit,
    onOpenSettings: () -> Unit,
) {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    var editingAction by remember { mutableStateOf(false) }
    var actionDraft by remember(deps.store.todayAction.value) { mutableStateOf(deps.store.todayAction.value) }

    Column(
        Modifier
            .fillMaxSize()
            .background(ink.base)
            .verticalScroll(rememberScrollState())
            .padding(Space.lg),
        verticalArrangement = Arrangement.spacedBy(Space.xl),
    ) {
        // Header
        Row(verticalAlignment = Alignment.Top) {
            Column(verticalArrangement = Arrangement.spacedBy(Space.sm), modifier = Modifier.weight(1f)) {
                Box(Modifier.size(width = 40.dp, height = 2.dp).background(ink.ink, RoundedCornerShape(1.dp)))
                val name = deps.settings.displayName.value.ifBlank { "FRIEND" }
                Text(
                    "WELCOME BACK, ${name.uppercase()}",
                    style = AppType.display(28),
                    color = ink.ink,
                )
                Text(AppDate.longToday(), style = AppType.captionMD, color = ink.mute)
            }
            Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(Space.sm)) {
                GhostTextButton("Settings", onOpenSettings, color = ink.mute)
                GhostTextButton("History", onOpenHistory, color = ink.mute)
            }
        }

        // Today's action card
        Column(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Radius.lg))
                .background(ink.bright)
                .padding(Space.xl),
            verticalArrangement = Arrangement.spacedBy(Space.md),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("TODAY'S HIGHEST-LEVERAGE ACTION", style = AppType.captionSM, color = ink.mute, modifier = Modifier.weight(1f))
                GhostTextButton(
                    if (editingAction) "Save" else "Edit",
                    {
                        if (editingAction) {
                            deps.store.updateTodayAction(actionDraft)
                            editingAction = false
                        } else {
                            actionDraft = deps.store.todayAction.value
                            editingAction = true
                        }
                    },
                    color = ink.mute,
                )
            }
            if (editingAction) {
                ForceTextField(
                    value = actionDraft,
                    onChange = { actionDraft = it },
                    placeholder = "What is the ONE thing you must do today?",
                    textStyle = AppType.headingLG,
                )
            } else {
                Text(
                    deps.store.todayAction.value.ifEmpty { "—" },
                    style = AppType.headingLG,
                    color = ink.ink,
                )
            }
        }

        // Progress + non-negotiables
        ChecklistCard()

        // Reflection (from web editor)
        if (deps.settings.reflection.value.isNotBlank()) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(Radius.lg))
                    .background(ink.containerLow)
                    .padding(Space.xl),
                verticalArrangement = Arrangement.spacedBy(Space.sm),
            ) {
                Text("REFLECTION", style = AppType.captionSM, color = ink.mute)
                Text(deps.settings.reflection.value, style = AppType.bodyMD, color = ink.ash)
            }
        }

        // Motivation + contract preview
        if (deps.settings.motivation.value.isNotBlank()) {
            Column(verticalArrangement = Arrangement.spacedBy(Space.md)) {
                Text("“${deps.settings.motivation.value}”", style = AppType.headingLG, color = ink.ash)
                val blocks = remember(deps.settings.contractText.value, deps.settings.displayName.value) {
                    Contract.blocks(deps.settings.contractText.value, AppDate.longToday(), deps.settings.displayName.value)
                }
                ContractBlocks(blocks, compact = true)
            }
        }
    }
}

@Composable
private fun ChecklistCard() {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    val done = deps.store.completedCount
    val total = deps.store.totalCount
    val complete = total > 0 && done == total
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.lg))
            .background(ink.containerLow)
            .padding(Space.xl),
        verticalArrangement = Arrangement.spacedBy(Space.lg),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("DAILY NON-NEGOTIABLES", style = AppType.captionSM, color = ink.mute, modifier = Modifier.weight(1f))
            Box(
                Modifier
                    .clip(RoundedCornerShape(Radius.sm))
                    .then(if (complete) Modifier.background(primaryGradient()) else Modifier.background(ink.containerHigh))
                    .padding(horizontal = Space.md, vertical = Space.xs),
            ) {
                Text(
                    "$done/$total",
                    style = AppType.captionSM,
                    color = if (complete) ink.onPrimary else ink.ink,
                )
            }
        }
        for (item in deps.settings.nonNegotiables) {
            ChecklistRow(item, deps.store.checklistState[item.id] == true) { deps.store.toggle(item.id) }
        }
    }
}

@Composable
private fun ChecklistRow(item: NonNegotiable, checked: Boolean, onToggle: () -> Unit) {
    val ink = LocalInk.current
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.md))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onToggle,
            )
            .padding(vertical = Space.sm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Space.md),
    ) {
        RoundCheckbox(checked = checked, onToggle = onToggle)
        Text(
            item.label,
            style = AppType.bodyMD.copy(
                textDecoration = if (checked) TextDecoration.LineThrough else TextDecoration.None,
            ),
            color = if (checked) ink.mute else ink.ink,
            modifier = Modifier.weight(1f),
        )
    }
}
