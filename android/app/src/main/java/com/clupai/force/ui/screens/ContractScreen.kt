package com.clupai.force.ui.screens

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.unit.dp
import com.clupai.force.LocalAppDeps
import com.clupai.force.data.AppDate
import com.clupai.force.data.Contract
import com.clupai.force.ui.components.ContractBlocks
import com.clupai.force.ui.theme.AppType
import com.clupai.force.ui.theme.LocalInk
import com.clupai.force.ui.theme.PrimaryButton
import com.clupai.force.ui.theme.Radius
import com.clupai.force.ui.theme.Space
import com.clupai.force.ui.theme.SquareCheckbox
import kotlinx.coroutines.delay

@Composable
fun ContractScreen() {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    val blocks = remember(deps.settings.contractText.value, deps.settings.displayName.value) {
        Contract.blocks(deps.settings.contractText.value, AppDate.longToday(), deps.settings.displayName.value)
    }
    var acknowledged by remember { mutableStateOf(false) }
    var actionText by remember { mutableStateOf("") }
    var scrollUnlocked by remember { mutableStateOf(false) }
    var bodyAppeared by remember { mutableStateOf(false) }

    val listState = rememberLazyListState()
    val atBottom by remember {
        derivedStateOf {
            val info = listState.layoutInfo
            val last = info.visibleItemsInfo.lastOrNull() ?: return@derivedStateOf false
            last.index >= info.totalItemsCount - 1 && last.offset + last.size <= info.viewportEndOffset + 16
        }
    }

    LaunchedEffect(Unit) {
        delay(150)
        bodyAppeared = true
    }
    LaunchedEffect(atBottom) {
        if (atBottom && !scrollUnlocked) {
            delay(2000)
            scrollUnlocked = true
        }
    }

    val canConfirm = scrollUnlocked && acknowledged && actionText.trim().isNotEmpty()
    val statusMessage = when {
        !scrollUnlocked -> "Scroll to the bottom of the contract."
        !acknowledged -> "Check the acknowledgement box."
        actionText.trim().isEmpty() -> "Enter your highest-leverage action for today."
        else -> "Ready to confirm."
    }

    val bodyAlpha by animateFloatAsState(if (bodyAppeared) 1f else 0f, spring(0.85f, Spring.StiffnessLow), label = "fade")

    Column(
        Modifier
            .fillMaxSize()
            .background(ink.base),
    ) {
        LazyColumn(
            state = listState,
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .alpha(bodyAlpha),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(
                horizontal = Space.lg, vertical = Space.xl,
            ),
            verticalArrangement = Arrangement.spacedBy(Space.lg),
        ) {
            item {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .widthIn(max = 760.dp),
                    verticalArrangement = Arrangement.spacedBy(Space.md),
                ) {
                    Text("DAILY CONTRACT", style = AppType.captionSM, color = ink.mute)
                    Box(Modifier.size(width = 40.dp, height = 2.dp).background(ink.ink, RoundedCornerShape(1.dp)))
                    Text(
                        "ACKNOWLEDGEMENT\nFORCE",
                        style = AppType.display(36),
                        color = ink.ink,
                    )
                    Text("Read carefully. Acknowledge intentionally.", style = AppType.bodyMD, color = ink.mute)
                }
            }
            item { ContractBlocks(blocks) }
        }

        // Acknowledgement form pinned to the bottom.
        Column(
            Modifier
                .fillMaxWidth()
                .background(ink.containerLow)
                .padding(horizontal = Space.lg, vertical = Space.xl)
                .alpha(bodyAlpha),
            verticalArrangement = Arrangement.spacedBy(Space.lg),
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(Space.md),
            ) {
                SquareCheckbox(
                    checked = acknowledged,
                    onToggle = { if (scrollUnlocked) acknowledged = !acknowledged },
                    enabled = scrollUnlocked,
                )
                Text(
                    "I have read and acknowledge this contract for today",
                    style = AppType.bodyStrong,
                    color = if (scrollUnlocked) ink.ink else ink.stone,
                )
            }

            Column(verticalArrangement = Arrangement.spacedBy(Space.sm)) {
                Text("TODAY'S SINGLE HIGHEST-LEVERAGE ACTION", style = AppType.captionSM, color = ink.mute)
                ForceTextField(
                    value = actionText,
                    onChange = { if (scrollUnlocked) actionText = it },
                    placeholder = "What is the ONE thing you must do today?",
                )
            }

            Column(verticalArrangement = Arrangement.spacedBy(Space.sm)) {
                PrimaryButton(
                    "Confirm & Continue",
                    onClick = {
                        deps.store.confirm(actionText.trim())
                    },
                    enabled = canConfirm,
                    modifier = Modifier.fillMaxWidth(),
                )
                Text(statusMessage, style = AppType.captionMD, color = ink.mute)
            }
        }
    }
}
