package com.feltandbone.farkle.ui.screens

import androidx.compose.animation.core.tween
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.ui.components.ValueChip
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Crimson
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans

private val pendingChips = listOf(50, 100, 200, 300, 350, 500, 1000, 1500)

/** The "this turn / not banked yet" card with the quick-add grid, live pending total
 *  and the Farkle button. Shared by the regular game and the final round. */
@Composable
fun PendingTurnCard(
    game: Game,
    onQuickAdd: (Int) -> Unit,
    onClear: () -> Unit,
    onFarkle: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val pending = game.pendingTurnScore
    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(12.dp, RoundedCornerShape(18.dp), ambientColor = Ink.copy(alpha = 0.10f), spotColor = Ink.copy(alpha = 0.10f))
            .clip(RoundedCornerShape(18.dp))
            .background(PaperSurface)
            .padding(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "THIS TURN · NOT BANKED YET",
                color = Ink3,
                fontFamily = PlexSans,
                fontWeight = FontWeight.Bold,
                fontSize = 10.sp,
                letterSpacing = 1.4.sp,
                modifier = Modifier.weight(1f),
            )
            val rolls = game.pendingRollCount
            Text("$rolls roll${if (rolls == 1) "" else "s"}", color = Ink3, fontFamily = JetBrainsMono, fontSize = 10.sp)
            if (pending > 0) {
                Spacer(Modifier.width(8.dp))
                Text(
                    "Clear",
                    color = Ink3,
                    fontFamily = PlexSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 12.sp,
                    modifier = Modifier.clickable { onClear() },
                )
            }
        }
        Spacer(Modifier.height(12.dp))
        Column {
            pendingChips.chunked(4).forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    row.forEach { v ->
                        ValueChip(v.toString(), modifier = Modifier.weight(1f)) { onQuickAdd(v) }
                    }
                }
                Spacer(Modifier.height(8.dp))
            }
        }
        Spacer(Modifier.height(4.dp))
        Row(verticalAlignment = Alignment.Bottom) {
            AnimatedContent(
                targetState = pending,
                transitionSpec = { (fadeIn(tween(250)) togetherWith fadeOut(tween(250))) },
                label = "pending",
            ) { value ->
                Text(
                    value.grouped(),
                    color = Ink,
                    fontFamily = JetBrainsMono,
                    fontWeight = FontWeight.Bold,
                    fontSize = 48.sp,
                )
            }
            Spacer(Modifier.width(8.dp))
            Text("pending", color = Ink3, fontFamily = PlexSans, fontSize = 13.sp, modifier = Modifier.padding(bottom = 10.dp))
            Spacer(Modifier.weight(1f))
            FarkleButton(onFarkle)
        }
    }
}

@Composable
private fun FarkleButton(onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(Crimson)
            .clickable { onClick() }
            .height(52.dp)
            .padding(horizontal = 24.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            "FARKLE",
            color = Paper,
            fontFamily = PlexSans,
            fontWeight = FontWeight.Bold,
            fontSize = 16.sp,
            letterSpacing = 1.4.sp,
        )
    }
}
