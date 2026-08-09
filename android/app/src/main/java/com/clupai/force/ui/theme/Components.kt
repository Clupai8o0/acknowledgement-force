package com.clupai.force.ui.theme

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

// Monochrome "primary" gradient (135°) — only emphasis fill in the system.
@Composable
fun primaryGradient(): Brush {
    val ink = LocalInk.current
    return Brush.linearGradient(listOf(ink.ink, ink.inkContainer))
}

@Composable
fun PrimaryButton(
    text: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    val ink = LocalInk.current
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.97f else 1f, spring(0.6f, Spring.StiffnessMediumLow), label = "scale")
    val brush = if (enabled) primaryGradient()
                else Brush.linearGradient(listOf(ink.stone, ink.stone))
    Box(
        modifier
            .height(48.dp)
            .scale(scale)
            .alpha(if (pressed) 0.85f else 1f)
            .clip(RoundedCornerShape(Radius.sm))
            .background(brush)
            .clickable(interactionSource = interaction, indication = null, enabled = enabled) { onClick() }
            .padding(horizontal = Space.xl),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, style = AppType.buttonMD, color = ink.onPrimary)
    }
}

// Ghost — no background, ink text.
@Composable
fun SecondaryButton(
    text: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    val ink = LocalInk.current
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.97f else 1f, spring(0.6f, Spring.StiffnessMediumLow), label = "scale")
    Box(
        modifier
            .height(48.dp)
            .scale(scale)
            .alpha(if (pressed) 0.7f else 1f)
            .clip(RoundedCornerShape(Radius.sm))
            .clickable(interactionSource = interaction, indication = null, enabled = enabled) { onClick() }
            .padding(horizontal = Space.xl),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, style = AppType.buttonMD, color = ink.ink)
    }
}

@Composable
fun DangerButton(text: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    PrimaryButton(text, modifier, onClick = onClick) // monochrome system — confirmation dialog carries the warning
}

@Composable
fun GhostTextButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    color: Color? = null,
) {
    val ink = LocalInk.current
    val resolved = color ?: ink.ink
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.96f else 1f, spring(0.7f, Spring.StiffnessMediumLow), label = "scale")
    Text(
        text,
        style = AppType.buttonSM,
        color = resolved,
        modifier = modifier
            .scale(scale)
            .alpha(if (pressed) 0.4f else 1f)
            .clickable(interactionSource = interaction, indication = null) { onClick() },
    )
}

// Tonal card — no border, just a tonal surface.
@Composable
fun TonalCard(
    modifier: Modifier = Modifier,
    background: Color? = null,
    padding: androidx.compose.ui.unit.Dp = Space.xl,
    content: @Composable () -> Unit,
) {
    val ink = LocalInk.current
    Box(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.lg))
            .background(background ?: ink.bright)
            .padding(padding),
    ) { content() }
}

// Hairline — near-invisible ghost border (outline at 15% opacity).
@Composable
fun Hairline(modifier: Modifier = Modifier, color: Color? = null) {
    val ink = LocalInk.current
    Box(
        modifier
            .fillMaxWidth()
            .height(1.dp)
            .background((color ?: ink.outline).copy(alpha = 0.15f)),
    )
}

// Filled-field accent: 3px left bar in ink when focused, no outline.
@Composable
fun FilledFieldBackground(focused: Boolean, enabled: Boolean = true): Modifier {
    return Modifier // intentional, handled in screens via custom Box wrapper
}

// Round checkbox (for non-negotiables).
@Composable
fun RoundCheckbox(
    checked: Boolean,
    onToggle: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val ink = LocalInk.current
    val scale by animateFloatAsState(if (checked) 1.08f else 1f, spring(0.55f, Spring.StiffnessMediumLow), label = "check")
    Box(
        modifier
            .size(22.dp)
            .scale(scale)
            .clip(androidx.compose.foundation.shape.CircleShape)
            .then(if (checked) Modifier.background(primaryGradient()) else Modifier.background(ink.bright))
            .then(if (!checked) Modifier.border(1.5.dp, ink.outline, androidx.compose.foundation.shape.CircleShape) else Modifier)
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { onToggle() },
        contentAlignment = Alignment.Center,
    ) {
        AnimatedVisibility(
            visible = checked,
            enter = scaleIn(initialScale = 0.4f) + fadeIn(),
            exit = scaleOut(targetScale = 0.4f) + fadeOut(),
        ) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = ink.onPrimary, modifier = Modifier.size(12.dp))
        }
    }
}

// Square checkbox (for the contract acknowledgement).
@Composable
fun SquareCheckbox(
    checked: Boolean,
    onToggle: () -> Unit,
    enabled: Boolean = true,
    modifier: Modifier = Modifier,
) {
    val ink = LocalInk.current
    val scale by animateFloatAsState(if (checked) 1.08f else 1f, spring(0.55f, Spring.StiffnessMediumLow), label = "check2")
    Box(
        modifier
            .size(22.dp)
            .scale(scale)
            .clip(RoundedCornerShape(Radius.xs))
            .then(if (checked) Modifier.background(primaryGradient()) else Modifier.background(ink.bright))
            .then(if (!checked) Modifier.border(1.5.dp, ink.outline, RoundedCornerShape(Radius.xs)) else Modifier)
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, enabled = enabled) { onToggle() },
        contentAlignment = Alignment.Center,
    ) {
        AnimatedVisibility(
            visible = checked,
            enter = scaleIn(initialScale = 0.4f) + fadeIn(),
            exit = scaleOut(targetScale = 0.4f) + fadeOut(),
        ) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = ink.onPrimary, modifier = Modifier.size(12.dp))
        }
    }
}

// Segment chip — used in appearance mode picker.
@Composable
fun SegmentChip(label: String, selected: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val ink = LocalInk.current
    val scale by animateFloatAsState(if (selected) 1.02f else 1f, spring(0.65f, Spring.StiffnessMediumLow), label = "seg")
    Box(
        modifier
            .scale(scale)
            .height(40.dp)
            .clip(RoundedCornerShape(Radius.sm))
            .then(if (selected) Modifier.background(primaryGradient()) else Modifier.background(ink.containerHigh))
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { onClick() }
            .padding(horizontal = Space.lg),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, style = AppType.buttonSM, color = if (selected) ink.onPrimary else ink.ink)
    }
}

// Radio row — schedule frequency picker.
@Composable
fun RadioRow(title: String, detail: String, selected: Boolean, onClick: () -> Unit) {
    val ink = LocalInk.current
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.md))
            .then(if (selected) Modifier.background(ink.bright) else Modifier)
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { onClick() }
            .padding(Space.md),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(Space.md),
    ) {
        Box(
            Modifier
                .size(20.dp)
                .padding(top = 2.dp)
                .clip(androidx.compose.foundation.shape.CircleShape)
                .border(1.5.dp, if (selected) ink.ink else ink.outline, androidx.compose.foundation.shape.CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            if (selected) {
                Box(
                    Modifier
                        .size(10.dp)
                        .clip(androidx.compose.foundation.shape.CircleShape)
                        .background(primaryGradient()),
                )
            }
        }
        androidx.compose.foundation.layout.Column(verticalArrangement = Arrangement.spacedBy(Space.xxs)) {
            Text(title, style = AppType.bodyStrong, color = ink.ink)
            Text(detail, style = AppType.captionMD, color = ink.mute)
        }
    }
}
