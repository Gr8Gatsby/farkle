package com.feltandbone.farkle.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.ui.theme.Crimson
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink2
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.InstrumentSerif
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut
import com.feltandbone.farkle.ui.theme.WalnutInk
import com.feltandbone.farkle.ui.theme.WalnutShadow

/** Chunky tactile primary CTA — walnut fill, deep drop shadow. Parity with iOS primary buttons. */
@Composable
fun PrimaryButton(
    label: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    color: Color = Walnut,
    foreground: Color = WalnutInk,
    subtext: String? = null,
    onClick: () -> Unit,
) {
    val shape = RoundedCornerShape(16.dp)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .alpha(if (enabled) 1f else 0.45f)
            .shadow(if (enabled) 8.dp else 0.dp, shape, ambientColor = WalnutShadow, spotColor = WalnutShadow)
            .clip(shape)
            .background(color)
            .clickable(enabled = enabled) { onClick() }
            .heightIn(min = 58.dp)
            .padding(horizontal = 20.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = label,
                color = foreground,
                fontFamily = PlexSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 18.sp,
                textAlign = TextAlign.Center,
            )
            if (subtext != null) {
                Text(
                    text = subtext,
                    color = foreground.copy(alpha = 0.8f),
                    fontFamily = PlexSans,
                    fontSize = 12.sp,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

/** Outlined secondary action on paper. */
@Composable
fun SecondaryButton(
    label: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    color: Color = Walnut,
    onClick: () -> Unit,
) {
    val shape = RoundedCornerShape(16.dp)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .alpha(if (enabled) 1f else 0.45f)
            .clip(shape)
            .background(PaperSurface)
            .border(BorderStroke(1.5.dp, color), shape)
            .clickable(enabled = enabled) { onClick() }
            .heightIn(min = 52.dp)
            .padding(horizontal = 20.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, color = color, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
    }
}

/** Quick-add value chip — mono number on paper surface with a hairline walnut border. Parity with iOS ChipButtonStyle. */
@Composable
fun ValueChip(
    label: String,
    modifier: Modifier = Modifier,
    selected: Boolean = false,
    crimsonStyle: Boolean = false,
    onClick: () -> Unit,
) {
    val shape = RoundedCornerShape(11.dp)
    val bg = when {
        crimsonStyle -> Crimson
        selected -> Walnut
        else -> PaperSurface
    }
    val fg = if (crimsonStyle || selected) WalnutInk else Ink
    val accent = crimsonStyle || selected
    Box(
        modifier = modifier
            .clip(shape)
            .background(bg)
            .then(if (accent) Modifier else Modifier.border(BorderStroke(1.dp, Walnut.copy(alpha = 0.20f)), shape))
            .clickable { onClick() }
            .heightIn(min = 48.dp)
            .padding(horizontal = 14.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, color = fg, fontFamily = JetBrainsMono, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
    }
}

/** Small eyebrow / pill label. */
@Composable
fun Pill(
    text: String,
    background: Color,
    foreground: Color,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(50))
            .background(background)
            .padding(horizontal = 10.dp, vertical = 4.dp),
    ) {
        Text(
            text = text,
            color = foreground,
            fontFamily = PlexSans,
            fontWeight = FontWeight.Bold,
            fontSize = 11.sp,
            letterSpacing = 1.sp,
        )
    }
}

@Composable
fun DisplayTitle(
    text: String,
    modifier: Modifier = Modifier,
    italic: Boolean = false,
    color: Color = Ink,
    size: Int = 34,
) {
    Text(
        text = text,
        modifier = modifier,
        color = color,
        fontFamily = InstrumentSerif,
        fontStyle = if (italic) FontStyle.Italic else FontStyle.Normal,
        fontSize = size.sp,
    )
}

@Composable
fun Caption(text: String, modifier: Modifier = Modifier, color: Color = Ink3) {
    Text(text, modifier = modifier, color = color, fontFamily = PlexSans, fontSize = 13.sp)
}

@Composable
fun Eyebrow(text: String, modifier: Modifier = Modifier, color: Color = Ink2) {
    Text(
        text = text.uppercase(),
        modifier = modifier,
        color = color,
        fontFamily = JetBrainsMono,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        letterSpacing = 2.sp,
    )
}
