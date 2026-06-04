package com.feltandbone.farkle.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.ui.AppViewModel
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.PrimaryButton
import com.feltandbone.farkle.ui.components.SecondaryButton
import com.feltandbone.farkle.ui.components.ValueChip
import com.feltandbone.farkle.ui.components.firstName
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Bone
import com.feltandbone.farkle.ui.theme.Crimson
import com.feltandbone.farkle.ui.theme.Felt
import com.feltandbone.farkle.ui.theme.FeltDeep
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.InstrumentSerif
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut
import com.feltandbone.farkle.ui.theme.WalnutInk

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FinalRoundScreen(vm: AppViewModel) {
    val game = vm.activeGame ?: return
    var sheet by remember { mutableStateOf<ActiveSheet?>(null) }

    if (!game.finalRoundAnnouncementShown) {
        FinalRoundAnnouncement(game) { vm.markFinalRoundAnnouncementShown() }
        return
    }

    val active = game.activePlayer
    val scoreToBeat = game.scoreToBeat ?: game.targetScore
    val pending = game.pendingTurnScore
    val newTotal = (active?.bankedScore ?: 0) + pending
    val wins = newTotal > scoreToBeat
    val stillToRoll = game.remainingFinalRoundPlayers.filter { it.id != active?.id }
    val triggerName = game.player(game.finalRoundTriggeredByPlayerId)?.name ?: ""

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(FeltDeep)
            .statusBarsPadding(),
    ) {
        Column(
            modifier = Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text("FINAL ROUND", color = Gold, fontFamily = JetBrainsMono, letterSpacing = 4.sp, fontSize = 13.sp)
            Spacer(Modifier.height(6.dp))
            Text("Score to beat", color = Bone.copy(alpha = 0.7f), fontFamily = PlexSans, fontSize = 13.sp)
            Text(
                scoreToBeat.grouped(),
                color = Bone,
                fontFamily = JetBrainsMono,
                fontWeight = FontWeight.Bold,
                fontSize = 48.sp,
            )
            Text(
                "${firstName(triggerName)} set the bar",
                color = Bone.copy(alpha = 0.7f),
                fontFamily = PlexSans,
                fontSize = 13.sp,
            )

            Spacer(Modifier.height(20.dp))
            if (active != null) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(20.dp))
                        .background(Felt)
                        .padding(18.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Avatar(active, size = 56.dp, highlighted = true)
                    Spacer(Modifier.height(8.dp))
                    Text(
                        active.name,
                        color = Bone,
                        fontFamily = InstrumentSerif,
                        fontStyle = FontStyle.Italic,
                        fontSize = 28.sp,
                    )
                    val needToWin = (scoreToBeat - active.bankedScore + 1).coerceAtLeast(1)
                    Text(
                        if (newTotal > scoreToBeat) "Currently WINNING" else "Needs ${needToWin.grouped()} this turn to win",
                        color = Gold,
                        fontFamily = PlexSans,
                        fontSize = 13.sp,
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(10.dp))
                    Text(
                        "Turn: +${pending.grouped()}  →  ${newTotal.grouped()}",
                        color = Bone,
                        fontFamily = JetBrainsMono,
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                    )
                    Spacer(Modifier.height(12.dp))
                    val chips = listOf(50, 100, 150, 300, 500, 1000)
                    Column {
                        chips.chunked(3).forEach { row ->
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                row.forEach { v -> ValueChip(v.grouped(), modifier = Modifier.weight(1f)) { vm.addToPending(v) } }
                            }
                            Spacer(Modifier.height(8.dp))
                        }
                    }
                    Row {
                        SecondaryButton("+ Custom", modifier = Modifier.weight(1f), color = Walnut) { sheet = ActiveSheet.Keypad }
                        Spacer(Modifier.width(8.dp))
                        SecondaryButton("Helper", modifier = Modifier.weight(1f), color = Felt) { sheet = ActiveSheet.Helper }
                    }
                }
            }

            if (stillToRoll.isNotEmpty()) {
                Spacer(Modifier.height(20.dp))
                Text("Still to roll", color = Bone.copy(alpha = 0.7f), fontFamily = JetBrainsMono, fontSize = 12.sp, letterSpacing = 2.sp)
                Spacer(Modifier.height(8.dp))
                stillToRoll.forEach { p ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(Felt.copy(alpha = 0.5f))
                            .padding(10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Avatar(p, size = 30.dp)
                        Spacer(Modifier.width(10.dp))
                        Text(p.name, color = Bone, fontFamily = PlexSans, modifier = Modifier.weight(1f))
                        val need = (scoreToBeat - p.bankedScore).coerceAtLeast(0)
                        Text("beat ${scoreToBeat.grouped()}", color = Bone.copy(alpha = 0.7f), fontFamily = JetBrainsMono, fontSize = 12.sp)
                    }
                    Spacer(Modifier.height(6.dp))
                }
            }
        }

        // Bottom Bank / Farkle
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(FeltDeep)
                .padding(16.dp)
                .navigationBarsPadding(),
        ) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(16.dp))
                    .background(Crimson)
                    .clickable { vm.bust() }
                    .padding(vertical = 16.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text("✕ FARKLE", color = WalnutInk, fontFamily = PlexSans, fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.width(10.dp))
            Box(
                modifier = Modifier
                    .weight(2f)
                    .clip(RoundedCornerShape(16.dp))
                    .background(if (pending > 0) Gold else Felt)
                    .clickable(enabled = pending > 0) { vm.bank() }
                    .padding(vertical = 16.dp),
                contentAlignment = Alignment.Center,
            ) {
                val label = when {
                    pending <= 0 -> "Bank"
                    wins -> "Bank — WINS! 🎉"
                    else -> "Bank — SHORT BY ${(scoreToBeat - newTotal + 1).coerceAtLeast(1).grouped()}"
                }
                Text(label, color = Ink, fontFamily = PlexSans, fontWeight = FontWeight.Bold)
            }
        }
    }

    when (sheet) {
        ActiveSheet.Keypad -> Sheet(onDismiss = { sheet = null }) {
            NumberKeypad(title = "Add to turn", confirmLabel = "Add to turn") { vm.addToPending(it); sheet = null }
        }
        ActiveSheet.Helper -> Sheet(onDismiss = { sheet = null }) {
            ScoreHelperSheet(rules = game.rules) { total, hot ->
                vm.addToPending(total); if (hot) vm.markPendingHotDice(); sheet = null
            }
        }
        else -> Unit
    }
}

@Composable
private fun FinalRoundAnnouncement(game: Game, onDismiss: () -> Unit) {
    val trigger = game.player(game.finalRoundTriggeredByPlayerId)
    val scoreToBeat = game.scoreToBeat ?: game.targetScore
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(FeltDeep)
            .statusBarsPadding()
            .padding(28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text("🎲", fontSize = 56.sp)
        Spacer(Modifier.height(8.dp))
        Text("FINAL ROUND", color = Gold, fontFamily = JetBrainsMono, letterSpacing = 5.sp, fontSize = 18.sp)
        Spacer(Modifier.height(14.dp))
        Text(
            "${firstName(trigger?.name ?: "")} hit the target.",
            color = Bone,
            fontFamily = InstrumentSerif,
            fontStyle = FontStyle.Italic,
            fontSize = 34.sp,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            "Everyone else gets one last turn. Beat ${scoreToBeat.grouped()} to win.",
            color = Bone.copy(alpha = 0.85f),
            fontFamily = PlexSans,
            fontSize = 16.sp,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(24.dp))
        game.remainingFinalRoundPlayers.forEach { p ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Felt.copy(alpha = 0.5f))
                    .padding(10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Avatar(p, size = 30.dp)
                Spacer(Modifier.width(10.dp))
                Text(p.name, color = Bone, fontFamily = PlexSans, modifier = Modifier.weight(1f))
                val need = (scoreToBeat - p.bankedScore).coerceAtLeast(0)
                Text("needs ${need.grouped()}+", color = Gold, fontFamily = JetBrainsMono, fontSize = 12.sp)
            }
            Spacer(Modifier.height(6.dp))
        }
        Spacer(Modifier.height(24.dp))
        PrimaryButton("Got it — let's play", color = Gold, foreground = Ink, onClick = onDismiss)
    }
}
