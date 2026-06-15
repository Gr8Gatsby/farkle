package com.feltandbone.farkle.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.feltandbone.farkle.ui.theme.Bone
import com.feltandbone.farkle.ui.theme.BonePip

/** A bone-white die showing [value] pips — parity with iOS DieView. */
@Composable
fun DieView(
    value: Int,
    size: Dp = 28.dp,
    faceColor: Color = Bone,
    pipColor: Color = BonePip,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier = modifier.size(size)) {
        val s = this.size.minDimension
        val corner = s * 0.22f
        drawRoundRect(
            color = faceColor,
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(corner, corner),
        )
        val r = s * 0.085f
        val a = s * 0.28f // near
        val b = s * 0.5f  // center
        val c = s * 0.72f // far
        fun pip(x: Float, y: Float) = drawCirclePip(x, y, r, pipColor)
        when (value.coerceIn(1, 6)) {
            1 -> { pip(b, b) }
            2 -> { pip(a, a); pip(c, c) }
            3 -> { pip(a, a); pip(b, b); pip(c, c) }
            4 -> { pip(a, a); pip(c, a); pip(a, c); pip(c, c) }
            5 -> { pip(a, a); pip(c, a); pip(b, b); pip(a, c); pip(c, c) }
            6 -> { pip(a, a); pip(c, a); pip(a, b); pip(c, b); pip(a, c); pip(c, c) }
        }
    }
}

private fun DrawScope.drawCirclePip(x: Float, y: Float, r: Float, color: Color) {
    drawCircle(color = color, radius = r, center = Offset(x, y))
}
