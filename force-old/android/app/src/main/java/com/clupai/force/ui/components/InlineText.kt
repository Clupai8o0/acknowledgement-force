package com.clupai.force.ui.components

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import com.clupai.force.data.Inline
import com.clupai.force.ui.theme.AppType
import com.clupai.force.ui.theme.LocalInk

@Composable
fun InlineText(
    runs: List<Inline>,
    style: TextStyle = AppType.bodyMD,
    color: Color? = null,
    modifier: Modifier = Modifier,
    lineHeightExtra: Float = 5f,
) {
    val ink = LocalInk.current
    val resolved = color ?: ink.ink
    val annotated: AnnotatedString = buildAnnotatedString {
        for (run in runs) when (run) {
            is Inline.Plain -> append(run.text)
            is Inline.Bold -> withStyle(SpanStyle(fontWeight = FontWeight.SemiBold)) { append(run.text) }
        }
    }
    Text(
        annotated,
        modifier = modifier,
        color = resolved,
        style = style,
    )
}
