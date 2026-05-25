package com.clupai.force.ui.theme

import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.clupai.force.R

// Editorial, not pill.
object Radius {
    val none = 0.dp
    val xs = 4.dp
    val sm = 6.dp     // buttons
    val md = 8.dp     // inputs
    val lg = 14.dp    // cards / surfaces
    val xl = 20.dp
    val full = 9999.dp
}

// Generous, room to breathe.
object Space {
    val xxs = 2.dp
    val xs = 4.dp
    val sm = 8.dp
    val md = 12.dp
    val lg = 20.dp
    val xl = 28.dp
    val xxl = 40.dp
    val section = 56.dp
}

// Fraunces (editorial serif) for display gravitas; Inter for body/metadata.
object Fonts {
    val Fraunces = FontFamily(Font(R.font.fraunces))
    val Inter = FontFamily(Font(R.font.inter))
}

object AppType {
    fun display(size: Int) = TextStyle(
        fontFamily = Fonts.Fraunces, fontWeight = FontWeight.Normal, fontSize = size.sp
    )

    val headingXL = TextStyle(fontFamily = Fonts.Fraunces, fontWeight = FontWeight.Medium, fontSize = 28.sp)
    val headingLG = TextStyle(fontFamily = Fonts.Fraunces, fontWeight = FontWeight.Medium, fontSize = 22.sp)
    val headingMD = TextStyle(fontFamily = Fonts.Fraunces, fontWeight = FontWeight.Medium, fontSize = 17.sp)

    val bodyMD = TextStyle(fontFamily = Fonts.Inter, fontWeight = FontWeight.Normal, fontSize = 16.sp)
    val bodyStrong = TextStyle(fontFamily = Fonts.Inter, fontWeight = FontWeight.Medium, fontSize = 16.sp)

    val buttonLG = TextStyle(fontFamily = Fonts.Inter, fontWeight = FontWeight.SemiBold, fontSize = 22.sp)
    val buttonMD = TextStyle(fontFamily = Fonts.Inter, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
    val buttonSM = TextStyle(fontFamily = Fonts.Inter, fontWeight = FontWeight.Medium, fontSize = 13.sp)

    val captionMD = TextStyle(fontFamily = Fonts.Inter, fontWeight = FontWeight.Normal, fontSize = 13.sp)
    val captionSM = TextStyle(
        fontFamily = Fonts.Inter, fontWeight = FontWeight.Medium, fontSize = 11.sp, letterSpacing = 1.5.sp
    )
    val utilityXS = TextStyle(fontFamily = Fonts.Inter, fontWeight = FontWeight.Medium, fontSize = 9.sp)
}
