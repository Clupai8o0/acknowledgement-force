package com.clupai.force.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.ui.unit.dp
import com.clupai.force.LocalAppDeps
import com.clupai.force.ui.theme.AppType
import com.clupai.force.ui.theme.GhostTextButton
import com.clupai.force.ui.theme.LocalInk
import com.clupai.force.ui.theme.PrimaryButton
import com.clupai.force.ui.theme.Space
import com.clupai.force.ui.theme.primaryGradient

@Composable
fun OnboardingScreen() {
    val deps = LocalAppDeps.current
    val ink = LocalInk.current
    var step by remember { mutableStateOf(0) }
    var forward by remember { mutableStateOf(true) }
    val lastStep = 4

    Column(
        Modifier
            .fillMaxSize()
            .background(ink.base),
    ) {
        // Progress bar
        Box(
            Modifier
                .fillMaxWidth()
                .height(3.dp)
                .background(ink.containerHigh),
        ) {
            val targetFraction = (step + 1).toFloat() / (lastStep + 1).toFloat()
            val fraction by animateFloatAsState(
                targetFraction,
                spring(0.82f, Spring.StiffnessMediumLow),
                label = "progress",
            )
            Box(
                Modifier
                    .fillMaxWidth(fraction)
                    .height(3.dp)
                    .background(primaryGradient()),
            )
        }

        // Step content
        Box(
            Modifier
                .fillMaxWidth()
                .weight(1f),
        ) {
            AnimatedContent(
                targetState = step,
                transitionSpec = {
                    val dir = if (forward) 1 else -1
                    (slideInHorizontally { dir * 80 } + fadeIn()) togetherWith
                        (slideOutHorizontally { -dir * 80 } + fadeOut())
                },
                label = "onboarding-step",
            ) { current ->
                Box(
                    Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = Space.section, vertical = Space.section),
                ) {
                    Column(
                        Modifier
                            .widthIn(max = 620.dp)
                            .align(Alignment.TopCenter),
                    ) {
                        when (current) {
                            0 -> Welcome()
                            1 -> AppearanceSection()
                            2 -> ScheduleSection()
                            3 -> MessagesSection()
                            else -> Finish()
                        }
                    }
                }
            }
        }

        // Footer
        Row(
            Modifier
                .fillMaxWidth()
                .background(ink.containerLow)
                .padding(horizontal = Space.section, vertical = Space.xl),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (step > 0) {
                GhostTextButton("Back", { forward = false; step -= 1 }, color = ink.mute)
            }
            Spacer(Modifier.weight(1f))
            Text(
                "${step + 1} / ${lastStep + 1}",
                style = AppType.captionMD,
                color = ink.mute,
            )
            Spacer(Modifier.weight(1f))
            if (step < lastStep) {
                PrimaryButton("Continue", { forward = true; step += 1 })
            } else {
                PrimaryButton("Get Started", { deps.settings.setHasOnboarded(true) })
            }
        }
    }
}

@Composable
private fun Welcome() {
    val ink = LocalInk.current
    Column(verticalArrangement = Arrangement.spacedBy(Space.md)) {
        Text("WELCOME TO", style = AppType.captionSM, color = ink.mute)
        Box(Modifier.size(width = 40.dp, height = 2.dp).background(ink.ink, RoundedCornerShape(1.dp)))
        Text(
            "ACKNOWLEDGEMENT\nFORCE",
            style = AppType.display(44),
            color = ink.ink,
        )
        Text(
            "A daily contract you must read and commit to before this phone is yours. Let's set it up — appearance, how often it locks in, and the messages that keep you honest.",
            style = AppType.bodyMD,
            color = ink.ash,
            modifier = Modifier.padding(top = Space.sm),
        )
    }
}

@Composable
private fun Finish() {
    val ink = LocalInk.current
    Column(verticalArrangement = Arrangement.spacedBy(Space.md)) {
        Text("ALL SET", style = AppType.captionSM, color = ink.mute)
        Box(Modifier.size(width = 40.dp, height = 2.dp).background(ink.ink, RoundedCornerShape(1.dp)))
        Text("YOU'RE READY.", style = AppType.display(44), color = ink.ink)
        Text(
            "You can change appearance, schedule, and messages any time from Settings. Take a deep breath — then sign today's contract.",
            style = AppType.bodyMD,
            color = ink.ash,
            modifier = Modifier.padding(top = Space.sm),
        )
    }
}
