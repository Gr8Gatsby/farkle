package com.feltandbone.farkle.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.ui.AppViewModel
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Bone
import com.feltandbone.farkle.ui.theme.Felt
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.Gold2
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.InstrumentSerif
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Walnut

@Composable
fun FinalRoundScreen(vm: AppViewModel) {
    val game = vm.activeGame ?: return
    var sheet by remember { mutableStateOf<ActiveSheet?>(null) }
    var confirmLeave by remember { mutableStateOf(false) }

    // The final-round screen IS the announcement now; mark it acknowledged.
    LaunchedEffect(game.id) {
        if (!game.finalRoundAnnouncementShown) vm.markFinalRoundAnnouncementShown()
    }

    val active = game.activePlayer
    val scoreToBeat = game.scoreToBeat ?: game.targetScore
    val pending = game.pendingTurnScore
    val trigger = game.player(game.finalRoundTriggeredByPlayerId)

    Box(Modifier.fillMaxSize().background(Felt)) {
        Box(
            Modifier.fillMaxSize().background(
                Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.06f), Color.Transparent, Color.Black.copy(alpha = 0.25f))),
            ),
        )
        Column(Modifier.fillMaxSize().statusBarsPadding()) {
            TopBar(
                centerLabel = "FINAL ROUND · ${game.remainingFinalRoundPlayers.size} LEFT",
                roomCode = vm.roomCode,
                viewerCount = vm.viewerCount,
                undoEnabled = game.actions.isNotEmpty(),
                dark = true,
                centerColor = Gold,
                onBack = { confirmLeave = true },
                onUndo = { vm.undoLast() },
            )

            Column(
                modifier = Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 14.dp).padding(top = 8.dp),
            ) {
                // Hero
                Column(Modifier.fillMaxWidth().padding(vertical = 8.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("FINAL ROUND", color = Gold, fontFamily = PlexSans, fontWeight = FontWeight.Bold, fontSize = 11.sp, letterSpacing = 2.4.sp)
                    Spacer(Modifier.height(6.dp))
                    if (active != null) {
                        val needs = scoreToBeat - active.bankedScore + 50
                        if (needs > 0) {
                            Row(verticalAlignment = Alignment.Bottom) {
                                Text("${active.name} needs ", color = Paper, fontFamily = InstrumentSerif, fontSize = 22.sp)
                                Text(needs.grouped(), color = Gold2, fontFamily = InstrumentSerif, fontStyle = FontStyle.Italic, fontSize = 36.sp)
                                Text(" to win", color = Paper, fontFamily = InstrumentSerif, fontSize = 22.sp)
                            }
                        } else {
                            Text("Banking wins!", color = Gold, fontFamily = InstrumentSerif, fontSize = 28.sp)
                        }
                    }
                    if (trigger != null) {
                        Spacer(Modifier.height(2.dp))
                        Text("${trigger.name} set the bar at ${scoreToBeat.grouped()}.", color = Paper.copy(alpha = 0.7f), fontFamily = PlexSans, fontSize = 12.sp)
                    }
                }
                Spacer(Modifier.height(14.dp))

                // Current player card
                if (active != null) {
                    val projected = active.bankedScore + pending
                    val needs = scoreToBeat - active.bankedScore + 50
                    val banksWin = projected > scoreToBeat && pending > 0
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(18.dp))
                            .background(Color.Black.copy(alpha = 0.28f))
                            .border(androidx.compose.foundation.BorderStroke(1.dp, Gold.copy(alpha = 0.45f)), RoundedCornerShape(18.dp))
                            .padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Avatar(active, size = 56.dp, highlighted = true)
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(active.name, color = Paper, fontFamily = InstrumentSerif, fontStyle = FontStyle.Italic, fontSize = 28.sp)
                            if (banksWin) {
                                Text("banking this wins!", color = Gold, fontFamily = PlexSans, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                            } else {
                                Text("needs ${needs.grouped()} to win", color = Paper.copy(alpha = 0.75f), fontFamily = PlexSans, fontSize = 12.sp)
                            }
                        }
                        if (banksWin) {
                            Box(Modifier.clip(RoundedCornerShape(50)).background(Gold).padding(horizontal = 8.dp, vertical = 4.dp)) {
                                Text("WIN", color = Walnut, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 11.sp, letterSpacing = 1.4.sp)
                            }
                        }
                    }
                    Spacer(Modifier.height(14.dp))
                }

                // Still to roll
                val queue = game.remainingFinalRoundPlayers.filter { it.id != active?.id }
                if (queue.isNotEmpty()) {
                    Text("STILL TO ROLL", color = Paper.copy(alpha = 0.55f), fontFamily = PlexSans, fontWeight = FontWeight.Bold, fontSize = 10.sp, letterSpacing = 1.6.sp, modifier = Modifier.padding(horizontal = 4.dp))
                    Spacer(Modifier.height(8.dp))
                    Column(
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Color.Black.copy(alpha = 0.22f))
                            .border(androidx.compose.foundation.BorderStroke(0.5.dp, Paper.copy(alpha = 0.06f)), RoundedCornerShape(14.dp)).padding(8.dp),
                    ) {
                        queue.forEachIndexed { idx, p ->
                            Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 6.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                                Avatar(p, size = 24.dp, highlighted = idx == 0)
                                Spacer(Modifier.width(10.dp))
                                Column(Modifier.weight(1f)) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(p.name, color = Paper, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                                        if (idx == 0) {
                                            Spacer(Modifier.width(6.dp))
                                            Box(Modifier.clip(RoundedCornerShape(3.dp)).background(Gold).padding(horizontal = 5.dp, vertical = 2.dp)) {
                                                Text("UP NEXT", color = Walnut, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 8.sp, letterSpacing = 0.6.sp)
                                            }
                                        }
                                    }
                                    val needs = scoreToBeat - p.bankedScore + 50
                                    Text("needs ${needs.grouped()} to win", color = Paper.copy(alpha = 0.65f), fontFamily = PlexSans, fontSize = 10.sp)
                                }
                            }
                            if (idx < queue.size - 1) Box(Modifier.fillMaxWidth().height(0.5.dp).background(Paper.copy(alpha = 0.08f)))
                        }
                    }
                }
                Spacer(Modifier.height(8.dp))
            }

            PendingTurnCard(
                game = game,
                onQuickAdd = { vm.addToPending(it) },
                onClear = { vm.clearPending() },
                onFarkle = { sheet = ActiveSheet.Farkle },
                modifier = Modifier.padding(horizontal = 14.dp).padding(top = 8.dp),
            )

            ReviewAndBankBar(
                label = "BANK",
                enabled = pending > 0,
                active = active,
                pending = pending,
                scoreToBeat = scoreToBeat,
                mustOpen = null,
                finalRoundHint = { newTotal, bar ->
                    when {
                        newTotal > bar -> "WINS!"
                        newTotal == bar -> "TIE — TRIGGER WINS"
                        else -> "SHORT BY ${(bar - newTotal).grouped()}"
                    }
                },
            ) { sheet = ActiveSheet.BankConfirm }

            ScoreHelperLink(color = Bone.copy(alpha = 0.85f)) { sheet = ActiveSheet.Helper }
        }
    }

    when (sheet) {
        ActiveSheet.Helper -> Sheet(onDismiss = { sheet = null }) {
            ScoreHelperSheet(rules = game.rules) { total, hot ->
                vm.addToPending(total); if (hot) vm.markPendingHotDice(); sheet = null
            }
        }
        ActiveSheet.BankConfirm -> Sheet(onDismiss = { sheet = null }) {
            BankConfirmSheet(game, onCancel = { sheet = null }) { vm.bank(); sheet = null }
        }
        ActiveSheet.Farkle -> Sheet(onDismiss = { sheet = null }) {
            FarkleConfirmSheet(game, onCancel = { sheet = null }) { vm.bust(); sheet = null }
        }
        else -> Unit
    }

    if (confirmLeave) {
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { confirmLeave = false },
            title = { Text("Leave this game?") },
            text = { Text("Your game is saved — you can resume it from Home.") },
            confirmButton = { androidx.compose.material3.TextButton(onClick = { confirmLeave = false; vm.leaveGame() }) { Text("Leave") } },
            dismissButton = { androidx.compose.material3.TextButton(onClick = { confirmLeave = false }) { Text("Keep playing") } },
        )
    }
}
