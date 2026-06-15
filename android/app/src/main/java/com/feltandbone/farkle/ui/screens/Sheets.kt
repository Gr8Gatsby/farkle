package com.feltandbone.farkle.ui.screens

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.DisplayTitle
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.PrimaryButton
import com.feltandbone.farkle.ui.components.SecondaryButton
import com.feltandbone.farkle.ui.components.firstName
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Crimson
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink2
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.InstrumentSerif
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut
import com.feltandbone.farkle.ui.theme.WalnutInk
import kotlinx.coroutines.delay

@Composable
fun BankConfirmSheet(game: Game, onCancel: () -> Unit, onConfirm: () -> Unit) {
    val player = game.activePlayer ?: return
    val pending = game.pendingTurnScore
    val was = player.bankedScore
    val now = was + pending
    val scoreToBeat = game.scoreToBeat ?: game.targetScore
    val willTriggerFinal = !game.isInFinalRound && now >= game.targetScore
    val willEndGame = game.isInFinalRound && game.remainingFinalRoundPlayers.size <= 1
    val willWinNow = willEndGame && now > scoreToBeat
    val ordered = game.orderedPlayers
    val nextName = ordered.getOrNull((game.activePlayerIndex + 1) % ordered.size)?.name ?: "next"

    // 5-second auto-bank countdown.
    var secondsLeft by remember { mutableIntStateOf(5) }
    var started by remember { mutableStateOf(false) }
    val confirm by rememberUpdatedState(onConfirm)
    val progress by animateFloatAsState(
        if (started) 0f else 1f,
        tween(durationMillis = 5000, easing = androidx.compose.animation.core.LinearEasing),
        label = "autobank",
    )
    LaunchedEffect(Unit) {
        started = true
        repeat(5) {
            delay(1000)
            secondsLeft -= 1
        }
        confirm()
    }

    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp).padding(top = 4.dp, bottom = 16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Eyebrow("Confirm turn", color = Ink3)
        Spacer(Modifier.height(6.dp))
        Text(
            bankTitle(player.name, pending, willWinNow, willEndGame, willTriggerFinal),
            fontFamily = InstrumentSerif,
            fontSize = 24.sp,
            color = Ink,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(16.dp))

        // Delta card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(PaperSurface)
                .border(BorderStroke(0.5.dp, Walnut.copy(alpha = 0.10f)), RoundedCornerShape(14.dp))
                .padding(14.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Avatar(player, size = 36.dp, highlighted = true)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(player.name, color = Ink, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                    Text("was ${was.grouped()}", color = Ink3, fontFamily = JetBrainsMono, fontSize = 10.sp)
                }
                Text(was.grouped(), color = Ink3, fontFamily = JetBrainsMono, fontSize = 14.sp, textDecoration = TextDecoration.LineThrough)
                Icon(Icons.AutoMirrored.Filled.ArrowForward, null, tint = Ink3, modifier = Modifier.size(12.dp).padding(horizontal = 0.dp))
                Spacer(Modifier.width(6.dp))
                Text(now.grouped(), color = Walnut, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 18.sp)
            }
            Spacer(Modifier.height(12.dp))
            // was → now progress
            val wasPct = (was.toFloat() / game.targetScore).coerceIn(0f, 1f)
            val nowPct = (now.toFloat() / game.targetScore).coerceIn(0f, 1f)
            Box(Modifier.fillMaxWidth().height(6.dp).clip(RoundedCornerShape(50)).background(Walnut.copy(alpha = 0.1f))) {
                Box(Modifier.fillMaxWidth(nowPct).height(6.dp).clip(RoundedCornerShape(50)).background(Gold))
                Box(Modifier.fillMaxWidth(wasPct).height(6.dp).clip(RoundedCornerShape(50)).background(Walnut.copy(alpha = 0.4f)))
            }
            Spacer(Modifier.height(6.dp))
            Row(Modifier.fillMaxWidth()) {
                Text("0", color = Ink3, fontFamily = JetBrainsMono, fontSize = 10.sp)
                Spacer(Modifier.weight(1f))
                Text(game.targetScore.grouped(), color = Ink3, fontFamily = JetBrainsMono, fontSize = 10.sp)
            }
        }

        Spacer(Modifier.height(12.dp))
        Caption("You can undo this from the top bar.", color = Ink3)
        Spacer(Modifier.height(14.dp))

        Row(Modifier.fillMaxWidth()) {
            SecondaryButton("Keep rolling", modifier = Modifier.weight(1f), onClick = onCancel)
            Spacer(Modifier.width(8.dp))
            Box(Modifier.weight(1f)) {
                PrimaryButton(
                    label = bankCta(willWinNow, willEndGame, willTriggerFinal, firstName(nextName)),
                    onClick = onConfirm,
                )
                // auto-bank progress capsule pinned near the button's bottom
                Box(
                    Modifier
                        .align(Alignment.BottomStart)
                        .padding(horizontal = 8.dp)
                        .offset(y = (-6).dp)
                        .fillMaxWidth()
                        .height(3.dp)
                        .clip(RoundedCornerShape(50)),
                ) {
                    Box(Modifier.fillMaxWidth(progress).height(3.dp).clip(RoundedCornerShape(50)).background(WalnutInk.copy(alpha = 0.30f)))
                }
            }
        }
        Spacer(Modifier.height(10.dp))
        Text("Auto-banking in ${secondsLeft.coerceAtLeast(0)}s", color = Ink3, fontFamily = JetBrainsMono, fontSize = 10.sp)
    }
}

private fun bankTitle(name: String, pending: Int, willWinNow: Boolean, willEndGame: Boolean, willTriggerFinal: Boolean) =
    buildAnnotatedString {
        val amount = "+${pending.grouped()}"
        val emph = SpanStyle(fontStyle = FontStyle.Italic, color = Walnut)
        when {
            willWinNow -> { append("$name "); withStyle(emph) { append("wins") }; append(" with $amount?") }
            willEndGame -> { append("Bank "); withStyle(emph) { append(amount) }; append(" to end the game?") }
            willTriggerFinal -> { append("$name "); withStyle(emph) { append("hits the target") }; append(".") }
            else -> { append("Bank "); withStyle(emph) { append(amount) }; append(" for $name?") }
        }
    }

private fun bankCta(willWinNow: Boolean, willEndGame: Boolean, willTriggerFinal: Boolean, nextName: String) = when {
    willWinNow -> "Bank & win"
    willEndGame -> "Bank & end the game"
    willTriggerFinal -> "Bank & start final round →"
    else -> "Bank & pass to $nextName →"
}

@Composable
fun FarkleConfirmSheet(game: Game, onCancel: () -> Unit, onConfirm: () -> Unit) {
    val player = game.activePlayer ?: return
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp).padding(top = 4.dp, bottom = 16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Eyebrow("Farkle", color = Crimson)
        Spacer(Modifier.height(6.dp))
        DisplayTitle("Farkle on ${firstName(player.name)}?", size = 26, italic = true)
        Spacer(Modifier.height(8.dp))
        Text(
            "The pending ${game.pendingTurnScore.grouped()} will be discarded. You can undo this from the top bar.",
            color = Ink2,
            fontFamily = PlexSans,
            fontSize = 13.sp,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(16.dp))
        Row(Modifier.fillMaxWidth()) {
            SecondaryButton("Keep rolling", modifier = Modifier.weight(1f), onClick = onCancel)
            Spacer(Modifier.width(8.dp))
            PrimaryButton(label = "Farkle →", color = Crimson, foreground = PaperSurface, modifier = Modifier.weight(1f), onClick = onConfirm)
        }
        Spacer(Modifier.height(10.dp))
    }
}

@Composable
fun EditPlayersSheet(
    game: Game,
    onRename: (String, String) -> Unit,
    onAdd: (String) -> Unit,
    onReorder: (List<String>) -> Unit,
    onClose: () -> Unit,
) {
    var newName by remember { mutableStateOf("") }
    val ordered = game.orderedPlayers

    Column(Modifier.fillMaxWidth().padding(20.dp)) {
        Eyebrow("Edit players")
        Spacer(Modifier.height(10.dp))
        ordered.forEachIndexed { idx, p ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(PaperSurface)
                    .padding(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                var name by remember(p.id) { mutableStateOf(p.name) }
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it.take(20); onRename(p.id, name) },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                )
                Column {
                    Icon(
                        Icons.Filled.KeyboardArrowUp, "Move up", tint = if (idx == 0) Ink3.copy(alpha = 0.3f) else Walnut,
                        modifier = Modifier.size(28.dp).clickable(enabled = idx > 0) {
                            val ids = ordered.map { it.id }.toMutableList()
                            ids.add(idx - 1, ids.removeAt(idx)); onReorder(ids)
                        },
                    )
                    Icon(
                        Icons.Filled.KeyboardArrowDown, "Move down", tint = if (idx == ordered.size - 1) Ink3.copy(alpha = 0.3f) else Walnut,
                        modifier = Modifier.size(28.dp).clickable(enabled = idx < ordered.size - 1) {
                            val ids = ordered.map { it.id }.toMutableList()
                            ids.add(idx + 1, ids.removeAt(idx)); onReorder(ids)
                        },
                    )
                }
            }
            Spacer(Modifier.height(6.dp))
        }

        Spacer(Modifier.height(8.dp))
        if (game.canAddPlayer) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                OutlinedTextField(
                    value = newName,
                    onValueChange = { newName = it.take(20) },
                    placeholder = { Text("Add player") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                )
                Spacer(Modifier.width(8.dp))
                SecondaryButton("Add", modifier = Modifier.width(90.dp), enabled = newName.trim().isNotEmpty()) {
                    onAdd(newName.trim()); newName = ""
                }
            }
        } else {
            Caption("New players can only be added during the first round.")
        }

        Spacer(Modifier.height(14.dp))
        PrimaryButton("Done", onClick = onClose)
        Spacer(Modifier.height(12.dp))
    }
}
