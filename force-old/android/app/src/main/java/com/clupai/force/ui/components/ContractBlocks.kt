package com.clupai.force.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.clupai.force.data.ContractBlock
import com.clupai.force.ui.theme.AppType
import com.clupai.force.ui.theme.Hairline
import com.clupai.force.ui.theme.LocalInk
import com.clupai.force.ui.theme.Space

@Composable
fun ContractBlocks(blocks: List<ContractBlock>, compact: Boolean = false) {
    Column(verticalArrangement = Arrangement.spacedBy(if (compact) Space.sm else Space.lg)) {
        for (block in blocks) BlockView(block, compact)
    }
}

@Composable
private fun BlockView(block: ContractBlock, compact: Boolean) {
    val ink = LocalInk.current
    when (block) {
        is ContractBlock.H1 -> Text(
            block.text.uppercase(),
            style = if (compact) AppType.headingMD else AppType.headingXL,
            color = ink.ink,
            modifier = Modifier.padding(top = if (compact) Space.xs else Space.sm),
        )
        is ContractBlock.H2 -> Text(
            block.text.uppercase(),
            style = if (compact) AppType.bodyStrong else AppType.headingLG,
            color = ink.ink,
            modifier = Modifier.padding(top = if (compact) Space.xs else Space.md),
        )
        is ContractBlock.H3 -> Text(
            block.text,
            style = if (compact) AppType.bodyStrong else AppType.headingMD,
            color = if (compact) ink.charcoal else ink.ink,
        )
        is ContractBlock.Rule -> Hairline(modifier = Modifier.padding(vertical = if (compact) Space.xxs else Space.xs))
        is ContractBlock.Paragraph -> InlineText(block.runs)
        is ContractBlock.Numbered -> Row(
            verticalAlignment = Alignment.Top,
            horizontalArrangement = Arrangement.spacedBy(if (compact) Space.sm else Space.md),
        ) {
            Text(
                "${block.n}.",
                style = if (compact) AppType.bodyMD else AppType.bodyStrong,
                color = if (compact) ink.mute else ink.ink,
                modifier = Modifier.width(if (compact) 20.dp else 24.dp),
            )
            InlineText(block.runs)
        }
        is ContractBlock.Bullet -> Row(
            verticalAlignment = Alignment.Top,
            horizontalArrangement = Arrangement.spacedBy(if (compact) Space.sm else Space.md),
        ) {
            Box(
                Modifier
                    .padding(top = if (compact) 7.dp else 8.dp)
                    .size(if (compact) 4.dp else 5.dp)
                    .background(if (compact) ink.mute else ink.ink, CircleShape),
            )
            InlineText(block.runs)
        }
        is ContractBlock.Checkbox -> Row(
            verticalAlignment = Alignment.Top,
            horizontalArrangement = Arrangement.spacedBy(if (compact) Space.sm else Space.md),
        ) {
            Box(
                Modifier
                    .padding(top = if (compact) 4.dp else 3.dp)
                    .size(if (compact) 12.dp else 16.dp)
                    .border(if (compact) 1.dp else 1.5.dp, ink.outline, RoundedCornerShape(if (compact) 2.dp else 3.dp)),
            )
            InlineText(block.runs)
        }
        is ContractBlock.Blockquote -> Row(
            verticalAlignment = Alignment.Top,
            horizontalArrangement = Arrangement.spacedBy(if (compact) Space.sm else Space.md),
        ) {
            Box(
                Modifier
                    .width(if (compact) 2.dp else 3.dp)
                    .height(20.dp)
                    .background(ink.hairline, RoundedCornerShape(1.dp)),
            )
            InlineText(block.runs, color = ink.mute)
        }
    }
}
