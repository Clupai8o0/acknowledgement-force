package com.clupai.force.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import com.clupai.force.LocalAppDeps
import com.clupai.force.data.Contract
import com.clupai.force.data.DefaultCopy
import com.clupai.force.data.Frequency
import com.clupai.force.data.NonNegotiable
import com.clupai.force.data.SyncStatus
import com.clupai.force.ui.theme.AppType
import com.clupai.force.ui.theme.AppearanceMode
import com.clupai.force.ui.theme.GhostTextButton
import com.clupai.force.ui.theme.LocalInk
import com.clupai.force.ui.theme.PrimaryButton
import com.clupai.force.ui.theme.RadioRow
import com.clupai.force.ui.theme.Radius
import com.clupai.force.ui.theme.SecondaryButton
import com.clupai.force.ui.theme.SegmentChip
import com.clupai.force.ui.theme.Space
import com.clupai.force.ui.theme.ThemePalette
import com.clupai.force.ui.theme.rgb
import com.clupai.force.ui.theme.toRgbHex
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

@Composable
fun SectionHeader(kicker: String, title: String) {
    val ink = LocalInk.current
    Column(verticalArrangement = Arrangement.spacedBy(Space.xs)) {
        Text(kicker, style = AppType.captionSM, color = ink.mute)
        Text(title, style = AppType.headingLG, color = ink.ink)
    }
}

@Composable
fun ProfileSection() {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    Column(verticalArrangement = Arrangement.spacedBy(Space.lg)) {
        SectionHeader("00 — PROFILE", "Your name")
        Column(verticalArrangement = Arrangement.spacedBy(Space.sm)) {
            Text("DISPLAY NAME", style = AppType.captionSM, color = ink.mute)
            Text("Used in your contract wherever {{NAME}} appears.", style = AppType.captionMD, color = ink.mute)
            ForceTextField(deps.settings.displayName.value, { deps.settings.setDisplayName(it) }, "e.g. Jane Smith")
        }
    }
}

@Composable
fun AppearanceSection() {
    val deps = LocalAppDeps.current
    val tm = deps.themeManager
    val ink = LocalInk.current
    val systemDark = isSystemInDarkTheme()
    Column(verticalArrangement = Arrangement.spacedBy(Space.lg)) {
        SectionHeader("01 — APPEARANCE", "Theme & colors")
        Row(horizontalArrangement = Arrangement.spacedBy(Space.md)) {
            for (mode in AppearanceMode.entries) {
                SegmentChip(mode.label, tm.mode.value == mode) { tm.setMode(mode) }
            }
        }
        // Color preview rows (read-only on mobile; full picker UI optional).
        Column(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Radius.lg))
                .background(ink.containerLow)
                .padding(Space.lg),
            verticalArrangement = Arrangement.spacedBy(Space.md),
        ) {
            ColorRow("Page", { it.base })
            ColorRow("Surface", { it.containerHigh })
            ColorRow("Text", { it.ink })
            ColorRow("Muted text", { it.mute })
            ColorRow("Outline", { it.outline })
        }
        GhostTextButton(
            "Reset ${if (tm.editingIsDark(systemDark)) "dark" else "light"} colors",
            { tm.resetActive(systemDark) },
            color = ink.mute,
        )
    }
}

@Composable
private fun ColorRow(label: String, select: (ThemePalette) -> Int) {
    val deps = LocalAppDeps.current
    val tm = deps.themeManager
    val ink = LocalInk.current
    val systemDark = isSystemInDarkTheme()
    val palette = if (tm.editingIsDark(systemDark)) tm.darkTheme.value else tm.lightTheme.value
    val swatchHex = select(palette)
    Row(
        Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, style = AppType.bodyMD, color = ink.charcoal)
        Spacer(Modifier.weight(1f))
        Box(
            Modifier
                .size(28.dp)
                .clip(CircleShape)
                .background(rgb(swatchHex)),
        )
    }
}

@Composable
fun ScheduleSection() {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    Column(verticalArrangement = Arrangement.spacedBy(Space.lg)) {
        SectionHeader("02 — SCHEDULE", "How often Force locks in")
        Column(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Radius.lg))
                .background(ink.containerLow)
                .padding(Space.lg),
            verticalArrangement = Arrangement.spacedBy(Space.sm),
        ) {
            for (f in Frequency.entries) {
                RadioRow(f.label, f.detail, deps.settings.frequency.value == f) {
                    deps.settings.setFrequency(f)
                    deps.store.recomputeGate()
                }
            }
        }
    }
}

@Composable
fun MessagesSection() {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    Column(verticalArrangement = Arrangement.spacedBy(Space.lg)) {
        SectionHeader("04 — WORDS", "Your contract & quote")
        EditorField(
            label = "DASHBOARD QUOTE",
            hint = "Shown on the home screen. Keep it short.",
            value = deps.settings.motivation.value,
            onChange = { deps.settings.setMotivation(it) },
            minHeight = 64.dp,
        )
        EditorField(
            label = "DAILY CONTRACT",
            hint = "Markdown: # heading, --- rule, 1. numbered, - bullet, [ ] checkbox, **bold**. {{DATE}} fills in today.",
            value = deps.settings.contractText.value,
            onChange = { deps.settings.setContractText(it) },
            minHeight = 280.dp,
        )
        GhostTextButton(
            "Reset contract to default",
            { deps.settings.setContractText(Contract.defaultMarkdown) },
            color = ink.mute,
        )
    }
}

@Composable
private fun EditorField(
    label: String,
    hint: String,
    value: String,
    onChange: (String) -> Unit,
    minHeight: androidx.compose.ui.unit.Dp,
) {
    val ink = LocalInk.current
    Column(verticalArrangement = Arrangement.spacedBy(Space.sm)) {
        Text(label, style = AppType.captionSM, color = ink.mute)
        Text(hint, style = AppType.captionMD, color = ink.mute)
        OutlinedTextField(
            value = value,
            onValueChange = onChange,
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = minHeight),
            textStyle = AppType.bodyMD.copy(color = ink.ink),
            shape = RoundedCornerShape(Radius.md),
            colors = forceFieldColors(),
        )
    }
}

@Composable
fun NonNegotiablesSection() {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    Column(verticalArrangement = Arrangement.spacedBy(Space.lg)) {
        SectionHeader("05 — CHECKLIST", "Daily non-negotiables")
        Column(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Radius.lg))
                .background(ink.containerLow)
                .padding(Space.lg),
            verticalArrangement = Arrangement.spacedBy(Space.sm),
        ) {
            for (item in deps.settings.nonNegotiables.toList()) {
                NonNegotiableRow(item, deps.settings.nonNegotiables)
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(Space.lg), verticalAlignment = Alignment.CenterVertically) {
            SecondaryButton("Add item") {
                deps.settings.addNonNegotiable(NonNegotiable(UUID.randomUUID().toString(), ""))
            }
            GhostTextButton(
                "Reset to default",
                { deps.settings.setNonNegotiables(DefaultCopy.nonNegotiables) },
                color = ink.mute,
            )
        }
    }
}

@Composable
private fun NonNegotiableRow(item: NonNegotiable, list: SnapshotStateList<NonNegotiable>) {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Space.md)) {
        OutlinedTextField(
            value = item.label,
            onValueChange = { deps.settings.updateNonNegotiableLabel(item.id, it) },
            placeholder = { Text("Item", style = AppType.bodyMD, color = ink.mute) },
            modifier = Modifier
                .weight(1f)
                .height(56.dp),
            textStyle = AppType.bodyMD.copy(color = ink.ink),
            shape = RoundedCornerShape(Radius.md),
            singleLine = true,
            colors = forceFieldColors(container = ink.bright),
        )
        Icon(
            Icons.Filled.RemoveCircleOutline,
            contentDescription = "Remove",
            tint = ink.mute,
            modifier = Modifier
                .size(22.dp)
                .clip(CircleShape)
                .clickable(
                    interactionSource = remember { androidx.compose.foundation.interaction.MutableInteractionSource() },
                    indication = null,
                ) { deps.settings.removeNonNegotiable(item.id) },
        )
    }
}

@Composable
fun SyncSection() {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    val remote = deps.remote
    val scope = rememberCoroutineScope()
    var emailIn by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var showConfig by remember { mutableStateOf(false) }

    Column(verticalArrangement = Arrangement.spacedBy(Space.lg)) {
        SectionHeader("03 — SYNC", "Edit from anywhere")
        Text(
            "Sign in to the web editor's account to pull your contract, quotes, goals and reflection onto this phone. Changes sync on launch.",
            style = AppType.captionMD, color = ink.mute,
        )
        if (!remote.isConfigured || showConfig) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(Radius.lg))
                    .background(ink.containerLow)
                    .padding(Space.lg),
                verticalArrangement = Arrangement.spacedBy(Space.sm),
            ) {
                ForceTextField(
                    remote.baseURL.value, { remote.setBaseURL(it) }, "https://xxxx.supabase.co",
                    container = ink.bright,
                )
                ForceTextField(
                    remote.anonKey.value, { remote.setAnonKey(it) }, "eyJ…",
                    container = ink.bright,
                )
            }
        }
        if (remote.isConfigured) {
            if (remote.isLoggedIn) {
                LoggedInBlock(showConfig, { showConfig = true })
            } else {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(Radius.lg))
                        .background(ink.containerLow)
                        .padding(Space.lg),
                    verticalArrangement = Arrangement.spacedBy(Space.sm),
                ) {
                    ForceTextField(emailIn, { emailIn = it }, "you@example.com", container = ink.bright)
                    ForceTextField(password, { password = it }, "Password", container = ink.bright, isPassword = true)
                    Row(horizontalArrangement = Arrangement.spacedBy(Space.lg), verticalAlignment = Alignment.CenterVertically) {
                        SecondaryButton("Log in") {
                            scope.launch {
                                remote.login(emailIn, password); password = ""
                            }
                        }
                        if (!showConfig) {
                            GhostTextButton("Edit connection", { showConfig = true }, color = ink.mute)
                        }
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(Space.xs)) {
                        Text("No account yet?", style = AppType.captionMD, color = ink.mute)
                        Text(
                            "Sign up at force.clupai.com ↗",
                            style = AppType.captionMD,
                            color = ink.ink,
                        )
                    }
                }
            }
        }
        StatusLine()
    }
}

@Composable
private fun LoggedInBlock(showConfig: Boolean, onShowConfig: () -> Unit) {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    val remote = deps.remote
    val scope = rememberCoroutineScope()
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.lg))
            .background(ink.containerLow)
            .padding(Space.lg),
        verticalArrangement = Arrangement.spacedBy(Space.md),
    ) {
        Text("Signed in as ${remote.email.value ?: "—"}", style = AppType.bodyStrong, color = ink.ink)
        Text(
            if (remote.localDirty.value)
                "You have local edits not yet synced. They'll push on Sync now or when you close Settings."
            else
                "Your contract and goals sync both ways. Quotes and reflection are edited on the web.",
            style = AppType.captionMD, color = ink.mute,
        )
        Row(horizontalArrangement = Arrangement.spacedBy(Space.lg), verticalAlignment = Alignment.CenterVertically) {
            SecondaryButton("Sync now") { scope.launch { remote.syncNow() } }
            GhostTextButton("Log out", { remote.logout() }, color = ink.mute)
            if (!showConfig) {
                GhostTextButton("Edit connection", onShowConfig, color = ink.mute)
            }
        }
    }
}

@Composable
private fun StatusLine() {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    when (val s = deps.remote.status.value) {
        SyncStatus.Syncing -> Text("Syncing…", style = AppType.captionMD, color = ink.mute)
        is SyncStatus.Synced -> if (s.at != 0L) {
            val time = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(s.at))
            Text("Last synced $time", style = AppType.captionMD, color = ink.mute)
        }
        is SyncStatus.Error -> Text(s.message, style = AppType.captionMD, color = ink.ink)
        SyncStatus.NeedsConfig, SyncStatus.LoggedOut -> {}
    }
}

@Composable
fun EmergencyStopSection(onStop: () -> Unit) {
    val ink = LocalInk.current
    var confirming by remember { mutableStateOf(false) }
    Column(verticalArrangement = Arrangement.spacedBy(Space.lg)) {
        SectionHeader("06 — EMERGENCY", "Stop Force")
        Text(
            "Quits immediately, even before today's acknowledgement. Force will not reopen until you launch it again.",
            style = AppType.captionMD, color = ink.mute,
        )
        PrimaryButton("Stop Force now") { confirming = true }
    }
    if (confirming) {
        ConfirmDialog(
            title = "Stop Force?",
            message = "This closes the app right now. You can reopen it any time.",
            confirmText = "Stop Force",
            onConfirm = { confirming = false; onStop() },
            onDismiss = { confirming = false },
        )
    }
}

// MARK: - Shared field & utilities

@Composable
fun ForceTextField(
    value: String,
    onChange: (String) -> Unit,
    placeholder: String,
    container: Color? = null,
    isPassword: Boolean = false,
    textStyle: TextStyle = AppType.bodyMD,
    modifier: Modifier = Modifier,
    singleLine: Boolean = true,
) {
    val ink = LocalInk.current
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        placeholder = { Text(placeholder, style = textStyle, color = ink.mute) },
        modifier = modifier
            .fillMaxWidth()
            .height(56.dp),
        textStyle = textStyle.copy(color = ink.ink),
        shape = RoundedCornerShape(Radius.md),
        singleLine = singleLine,
        visualTransformation = if (isPassword) androidx.compose.ui.text.input.PasswordVisualTransformation()
                               else androidx.compose.ui.text.input.VisualTransformation.None,
        colors = forceFieldColors(container = container ?: ink.containerHigh),
    )
}

@Composable
fun forceFieldColors(container: Color? = null): androidx.compose.material3.TextFieldColors {
    val ink = LocalInk.current
    val fill = container ?: ink.containerHigh
    return TextFieldDefaults.colors(
        focusedContainerColor = fill,
        unfocusedContainerColor = fill,
        disabledContainerColor = fill.copy(alpha = 0.5f),
        focusedIndicatorColor = Color.Transparent,
        unfocusedIndicatorColor = Color.Transparent,
        disabledIndicatorColor = Color.Transparent,
        cursorColor = ink.ink,
        focusedTextColor = ink.ink,
        unfocusedTextColor = ink.ink,
    )
}

@Composable
private fun ConfirmDialog(
    title: String,
    message: String,
    confirmText: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    val ink = LocalInk.current
    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title, style = AppType.headingMD, color = ink.ink) },
        text = { Text(message, style = AppType.bodyMD, color = ink.ash) },
        confirmButton = { PrimaryButton(confirmText, onClick = onConfirm) },
        dismissButton = { GhostTextButton("Cancel", onDismiss, color = ink.mute) },
        containerColor = ink.base,
    )
}

