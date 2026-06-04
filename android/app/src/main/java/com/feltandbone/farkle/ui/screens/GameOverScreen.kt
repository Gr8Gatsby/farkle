package com.feltandbone.farkle.ui.screens

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.widget.Toast
import com.feltandbone.farkle.ui.AppViewModel
import com.feltandbone.farkle.ui.WinCard
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.Pill
import com.feltandbone.farkle.ui.components.PrimaryButton
import com.feltandbone.farkle.ui.components.SecondaryButton
import com.feltandbone.farkle.ui.components.firstName
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Felt
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.Gold2
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.InstrumentSerif
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.Paper2
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut
import com.feltandbone.farkle.ui.theme.Crimson
import kotlin.math.abs

@Composable
fun GameOverScreen(vm: AppViewModel) {
    val game = vm.activeGame ?: return
    val winner = game.winner
    val context = LocalContext.current

    // Count-up score animation.
    var shown by remember { mutableFloatStateOf(0f) }
    LaunchedEffect(game.id) {
        val target = (winner?.bankedScore ?: 0).toFloat()
        val steps = 40
        repeat(steps) { i ->
            shown = target * ((i + 1f) / steps)
            kotlinx.coroutines.delay(35)
        }
        shown = target
    }

    Box(Modifier.fillMaxSize().background(Paper)) {
        Confetti(Modifier.fillMaxSize())

        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                val synced = false
                Pill(
                    if (synced) "SYNCED" else "SAVED LOCALLY",
                    background = if (synced) Felt else Paper2,
                    foreground = if (synced) Paper else Walnut,
                )
                Spacer(Modifier.weight(1f))
                Icon(
                    Icons.Filled.Close,
                    contentDescription = "Close",
                    tint = Ink3,
                    modifier = Modifier.size(40.dp).clip(CircleShape).clickableNoRipple { vm.finishGameOver() }.padding(8.dp),
                )
            }

            Spacer(Modifier.height(20.dp))
            // Trophy crest
            Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxWidth()) {
                Box(Modifier.size(170.dp).clip(CircleShape).background(Gold.copy(alpha = 0.18f)))
                if (winner != null) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("🏆", fontSize = 64.sp)
                        Avatar(winner, size = 72.dp, highlighted = true)
                    }
                }
            }

            Spacer(Modifier.height(18.dp))
            Eyebrow(game.name, modifier = Modifier.fillMaxWidth(), color = Walnut)
            Spacer(Modifier.height(6.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement_Center) {
                Text(
                    firstName(winner?.name ?: ""),
                    color = Walnut,
                    fontFamily = InstrumentSerif,
                    fontStyle = FontStyle.Italic,
                    fontSize = 44.sp,
                )
                Text(
                    " wins.",
                    color = Ink,
                    fontFamily = InstrumentSerif,
                    fontSize = 44.sp,
                )
            }
            Text(
                shown.toInt().grouped(),
                color = Ink,
                fontFamily = JetBrainsMono,
                fontWeight = FontWeight.Bold,
                fontSize = 56.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )

            Spacer(Modifier.height(20.dp))
            // standings card
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(18.dp))
                    .background(PaperSurface)
                    .padding(16.dp),
            ) {
                val ranked = game.orderedPlayers.sortedByDescending { it.bankedScore }
                ranked.forEachIndexed { idx, p ->
                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(vertical = 6.dp)) {
                        if (idx == 0) {
                            Pill("1ST PLACE", background = Gold, foreground = Ink)
                        } else {
                            Text("${idx + 1}", color = Ink3, fontFamily = JetBrainsMono, modifier = Modifier.width(40.dp))
                        }
                        Spacer(Modifier.width(10.dp))
                        Avatar(p, size = 32.dp)
                        Spacer(Modifier.width(10.dp))
                        Text(p.name, color = Ink, fontFamily = PlexSans, fontWeight = if (idx == 0) FontWeight.SemiBold else FontWeight.Normal, modifier = Modifier.weight(1f))
                        Text(p.bankedScore.grouped(), color = Ink, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold)
                    }
                    if (idx == 0) Spacer(Modifier.height(4.dp))
                }
            }

            Spacer(Modifier.height(12.dp))
            Text(
                "Wait — that's wrong",
                color = Crimson,
                fontFamily = PlexSans,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().clickableNoRipple { vm.undoLast() }.padding(8.dp),
            )

            Spacer(Modifier.height(12.dp))
            PrimaryButton("Share the win") { WinCard.share(context, game) }
            Spacer(Modifier.height(8.dp))
            SecondaryButton("Save image") {
                val ok = WinCard.save(context, game)
                Toast.makeText(context, if (ok) "Saved to Photos" else "Couldn't save", Toast.LENGTH_SHORT).show()
            }
            Spacer(Modifier.height(8.dp))
            SecondaryButton("Rematch", color = Felt) { vm.rematch() }
            Spacer(Modifier.height(8.dp))
            SecondaryButton("Done") { vm.finishGameOver() }
            Spacer(Modifier.height(24.dp))
        }
    }
}

private val Arrangement_Center = androidx.compose.foundation.layout.Arrangement.Center

private fun Modifier.clickableNoRipple(onClick: () -> Unit): Modifier =
    this.clickable(onClick = onClick)

@Composable
private fun Confetti(modifier: Modifier = Modifier) {
    val colors = listOf(Gold, Gold2, Crimson, Felt, Walnut)
    val transition = rememberInfiniteTransition(label = "confetti")
    val t by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(4000, easing = LinearEasing), RepeatMode.Restart),
        label = "fall",
    )
    val seeds = remember { (0 until 40).map { Triple(it * 0.137f % 1f, (it * 0.31f) % 1f, it % 5) } }
    Canvas(modifier) {
        val w = size.width
        val h = size.height
        seeds.forEach { (x, phase, ci) ->
            val prog = (t + phase) % 1f
            val px = (x + 0.06f * kotlin.math.sin((prog * 8f + x * 10f).toDouble()).toFloat()) * w
            val py = prog * (h + 60f) - 30f
            drawRect(
                color = colors[ci],
                topLeft = Offset(px, py),
                size = androidx.compose.ui.geometry.Size(10f, 16f),
            )
        }
    }
}
