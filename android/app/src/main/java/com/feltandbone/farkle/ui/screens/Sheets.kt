package com.feltandbone.farkle.ui.screens

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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.model.ActionKind
import com.feltandbone.farkle.model.ActionLogEntry
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.DisplayTitle
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.PrimaryButton
import com.feltandbone.farkle.ui.components.SecondaryButton
import com.feltandbone.farkle.ui.components.firstName
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Crimson
import com.feltandbone.farkle.ui.theme.Felt
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper2
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut

@Composable
fun BankConfirmSheet(game: Game, onCancel: () -> Unit, onConfirm: () -> Unit) {
    val player = game.activePlayer ?: return
    val pending = game.pendingTurnScore
    val was = player.bankedScore
    val now = was + pending
    val willTrigger = !game.isInFinalRound && now >= game.targetScore
    val ordered = game.orderedPlayers
    val nextName = ordered.getOrNull((game.activePlayerIndex + 1) % ordered.size)?.name ?: ""

    Column(Modifier.fillMaxWidth().padding(20.dp)) {
        DisplayTitle(
            if (willTrigger) "${firstName(player.name)} hits the target." else "Bank +${pending.grouped()} for ${firstName(player.name)}?",
            size = 26,
        )
        Spacer(Modifier.height(14.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("was ${was.grouped()}", color = Ink3, fontFamily = JetBrainsMono)
            Text("  →  ", color = Ink3)
            Text(now.grouped(), color = Ink, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 20.sp)
        }
        Spacer(Modifier.height(10.dp))
        LinearProgressIndicator(
            progress = { (now.toFloat() / game.targetScore).coerceIn(0f, 1f) },
            modifier = Modifier.fillMaxWidth().height(6.dp),
            color = Felt,
            trackColor = Paper2,
        )
        Spacer(Modifier.height(12.dp))
        Caption("You can undo this from the Recent actions list.")
        Spacer(Modifier.height(16.dp))
        PrimaryButton(
            label = if (willTrigger) "Bank & start final round →" else "Bank & pass to ${firstName(nextName)} →",
            onClick = onConfirm,
        )
        Spacer(Modifier.height(8.dp))
        SecondaryButton("Keep rolling", onClick = onCancel)
        Spacer(Modifier.height(12.dp))
    }
}

@Composable
fun FarkleConfirmSheet(game: Game, onCancel: () -> Unit, onConfirm: () -> Unit) {
    val player = game.activePlayer ?: return
    Column(Modifier.fillMaxWidth().padding(20.dp)) {
        DisplayTitle("Farkle on ${game.pendingTurnScore.grouped()}?", size = 26, color = Crimson)
        Spacer(Modifier.height(8.dp))
        Caption("${firstName(player.name)} loses this turn's ${game.pendingTurnScore.grouped()} points and play passes on.")
        Spacer(Modifier.height(16.dp))
        PrimaryButton(label = "Farkle", color = Crimson, onClick = onConfirm)
        Spacer(Modifier.height(8.dp))
        SecondaryButton("Keep rolling", onClick = onCancel)
        Spacer(Modifier.height(12.dp))
    }
}

@Composable
fun EditActionSheet(
    game: Game,
    entry: ActionLogEntry,
    onEditAmount: (Int) -> Unit,
    onUndo: () -> Unit,
    onCancel: () -> Unit,
) {
    val player = game.player(entry.playerId)
    Column(Modifier.fillMaxWidth().padding(20.dp)) {
        Eyebrow(if (entry.kind == ActionKind.BANK) "Edit bank" else "Edit Farkle")
        Spacer(Modifier.height(4.dp))
        DisplayTitle("${player?.name ?: "?"} · ${if (entry.kind == ActionKind.BANK) "+${entry.amount.grouped()}" else "Farkle"}", size = 24)
        Spacer(Modifier.height(12.dp))
        if (entry.kind == ActionKind.BANK) {
            NumberKeypad(title = "Correct the amount", confirmLabel = "Save amount", initial = entry.amount) {
                onEditAmount(it)
            }
            Spacer(Modifier.height(8.dp))
        }
        SecondaryButton("Undo this (and everything after)", color = Crimson, onClick = onUndo)
        Spacer(Modifier.height(8.dp))
        SecondaryButton("Cancel", onClick = onCancel)
        Spacer(Modifier.height(12.dp))
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
