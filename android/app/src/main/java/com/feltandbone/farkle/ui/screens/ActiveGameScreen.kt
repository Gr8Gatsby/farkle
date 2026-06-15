package com.feltandbone.farkle.ui.screens

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.Casino
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Sensors
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.model.Player
import com.feltandbone.farkle.ui.AppViewModel
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.CountingNumber
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.InstrumentSerif
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut
import com.feltandbone.farkle.ui.theme.WalnutInk

@Composable
fun ActiveGameScreen(vm: AppViewModel) {
    val game = vm.activeGame ?: return
    androidx.compose.runtime.LaunchedEffect(game.id) { vm.startHostingIfNeeded() }
    when {
        game.endedAt != null -> GameOverScreen(vm)
        game.isInFinalRound -> FinalRoundScreen(vm)
        else -> NormalActiveGame(vm, game)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun NormalActiveGame(vm: AppViewModel, game: Game) {
    var sheet by remember { mutableStateOf<ActiveSheet?>(null) }
    var confirmLeave by remember { mutableStateOf(false) }

    val active = game.activePlayer
    val pending = game.pendingTurnScore
    val mustOpen = game.rules.mustOpenWith
    val blockedByMustOpen = active != null && active.bankedScore == 0 && mustOpen != null && pending < mustOpen
    val canBank = pending > 0 && !blockedByMustOpen

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Paper)
            .statusBarsPadding(),
    ) {
        TopBar(
            centerLabel = "R${game.currentRound} · TO ${game.targetScore.grouped()}",
            roomCode = vm.roomCode,
            viewerCount = vm.viewerCount,
            undoEnabled = game.actions.isNotEmpty(),
            dark = false,
            onBack = { confirmLeave = true },
            onUndo = { vm.undoLast() },
        )

        Column(
            modifier = Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 14.dp).padding(top = 8.dp),
        ) {
            StandingsLadder(game, onEdit = { sheet = ActiveSheet.EditPlayers })
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
            label = "REVIEW & BANK",
            enabled = canBank,
            active = active,
            pending = pending,
            scoreToBeat = game.scoreToBeat,
            mustOpen = if (blockedByMustOpen) mustOpen else null,
        ) { sheet = ActiveSheet.BankConfirm }

        ScoreHelperLink(color = Walnut) { sheet = ActiveSheet.Helper }
    }

    // --- Sheets ---
    when (sheet) {
        ActiveSheet.Helper -> Sheet(onDismiss = { sheet = null }) {
            ScoreHelperSheet(rules = game.rules) { total, hot ->
                vm.addToPending(total)
                if (hot) vm.markPendingHotDice()
                sheet = null
            }
        }
        ActiveSheet.BankConfirm -> Sheet(onDismiss = { sheet = null }) {
            BankConfirmSheet(game, onCancel = { sheet = null }) {
                vm.bank(); sheet = null
            }
        }
        ActiveSheet.Farkle -> Sheet(onDismiss = { sheet = null }) {
            FarkleConfirmSheet(game, onCancel = { sheet = null }) { vm.bust(); sheet = null }
        }
        ActiveSheet.EditPlayers -> Sheet(onDismiss = { sheet = null }) {
            EditPlayersSheet(
                game = game,
                onRename = { id, name -> vm.renamePlayer(id, name) },
                onAdd = { vm.addPlayer(it) },
                onReorder = { vm.reorderPlayers(it) },
                onClose = { sheet = null },
            )
        }
        null -> Unit
    }

    if (confirmLeave) {
        AlertDialog(
            onDismissRequest = { confirmLeave = false },
            title = { Text("Leave this game?") },
            text = { Text("Your game is saved — you can resume it from Home.") },
            confirmButton = {
                TextButton(onClick = { confirmLeave = false; vm.leaveGame() }) { Text("Leave") }
            },
            dismissButton = { TextButton(onClick = { confirmLeave = false }) { Text("Keep playing") } },
        )
    }
}

enum class ActiveSheet { Helper, BankConfirm, Farkle, EditPlayers }

// MARK: - Shared chrome

/** Top bar used by both the regular and final-round screens. `dark` flips colors for the felt theme. */
@Composable
fun TopBar(
    centerLabel: String,
    roomCode: String?,
    viewerCount: Int,
    undoEnabled: Boolean,
    dark: Boolean,
    centerColor: Color = if (dark) WalnutInk else Ink3,
    onBack: () -> Unit,
    onUndo: () -> Unit,
) {
    val chipBg = if (dark) Color.White.copy(alpha = 0.10f) else Walnut.copy(alpha = 0.08f)
    val chipFg = if (dark) Paper else Ink
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp).padding(top = 8.dp, bottom = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier.size(36.dp).clip(RoundedCornerShape(10.dp)).background(chipBg).clickable { onBack() },
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, "Leave game", tint = chipFg, modifier = Modifier.size(16.dp))
        }
        if (roomCode != null) {
            Spacer(Modifier.width(8.dp))
            Row(
                modifier = Modifier.height(36.dp).clip(RoundedCornerShape(10.dp)).background(chipBg).padding(horizontal = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (viewerCount > 0) {
                    Icon(Icons.Filled.Group, "Viewers", tint = chipFg, modifier = Modifier.size(13.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("$viewerCount", color = chipFg, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                } else {
                    Icon(Icons.Filled.Sensors, "Room", tint = chipFg, modifier = Modifier.size(14.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(roomCode, color = chipFg, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 12.sp, letterSpacing = 0.6.sp)
                }
            }
        }
        Spacer(Modifier.weight(1f))
        Text(centerLabel, color = centerColor, fontFamily = JetBrainsMono, fontWeight = FontWeight.SemiBold, fontSize = 10.sp, letterSpacing = 1.4.sp)
        Spacer(Modifier.weight(1f))
        Row(
            modifier = Modifier
                .height(36.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(chipBg)
                .then(if (undoEnabled) Modifier.clickable { onUndo() } else Modifier)
                .padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            val undoColor = chipFg.copy(alpha = if (undoEnabled) 1f else 0.4f)
            Icon(Icons.AutoMirrored.Filled.Undo, "Undo", tint = undoColor, modifier = Modifier.size(13.dp))
            Spacer(Modifier.width(6.dp))
            Text("Undo", color = undoColor, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
        }
    }
}

/** Full-width walnut bottom CTA showing the projected total + a contextual hint. */
@Composable
fun ReviewAndBankBar(
    label: String,
    enabled: Boolean,
    active: Player?,
    pending: Int,
    scoreToBeat: Int?,
    mustOpen: Int?,
    finalRoundHint: ((newTotal: Int, bar: Int) -> String)? = null,
    onClick: () -> Unit,
) {
    Box(Modifier.padding(horizontal = 14.dp).padding(top = 12.dp, bottom = 8.dp)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(60.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(Walnut.copy(alpha = if (enabled) 1f else 0.55f))
                .then(if (enabled) Modifier.clickable { onClick() } else Modifier)
                .padding(horizontal = 18.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text(label, color = WalnutInk.copy(alpha = 0.75f), fontFamily = PlexSans, fontWeight = FontWeight.Bold, fontSize = 9.sp, letterSpacing = 1.4.sp)
                if (enabled && active != null) {
                    val newTotal = active.bankedScore + pending
                    Text(
                        "+${pending.grouped()} → ${newTotal.grouped()}",
                        color = WalnutInk,
                        fontFamily = InstrumentSerif,
                        fontStyle = FontStyle.Italic,
                        fontSize = 20.sp,
                    )
                    val bar = scoreToBeat
                    if (bar != null && finalRoundHint != null) {
                        Text(finalRoundHint(newTotal, bar), color = WalnutInk.copy(alpha = 0.85f), fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 10.sp, letterSpacing = 0.6.sp)
                    }
                } else if (mustOpen != null) {
                    Text("Must open with ${mustOpen.grouped()}", color = WalnutInk, fontFamily = InstrumentSerif, fontStyle = FontStyle.Italic, fontSize = 15.sp)
                } else {
                    Text("Add some points first", color = WalnutInk, fontFamily = InstrumentSerif, fontStyle = FontStyle.Italic, fontSize = 15.sp)
                }
            }
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = WalnutInk, modifier = Modifier.size(20.dp))
        }
    }
}

@Composable
fun ScoreHelperLink(color: Color, onClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().clickable { onClick() }.navigationBarsPadding().padding(bottom = 14.dp, top = 2.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.Casino, null, tint = color, modifier = Modifier.size(15.dp))
        Spacer(Modifier.width(6.dp))
        Text("Score helper", color = color, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun Sheet(onDismiss: () -> Unit, content: @Composable () -> Unit) {
    val state = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = state, containerColor = Paper) {
        Column(Modifier.imePadding()) { content() }
    }
}

// MARK: - Unified standings

@Composable
private fun StandingsLadder(game: Game, onEdit: () -> Unit) {
    Column {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(horizontal = 4.dp)) {
            Text("STANDINGS", color = Ink3, fontFamily = JetBrainsMono, fontWeight = FontWeight.Medium, fontSize = 12.sp, letterSpacing = 2.sp, modifier = Modifier.weight(1f))
            Row(
                modifier = Modifier.clickable { onEdit() }.padding(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.Group, "Edit players", tint = Ink3, modifier = Modifier.size(13.dp))
                Spacer(Modifier.width(4.dp))
                Text("Edit", color = Ink3, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 11.sp, letterSpacing = 0.6.sp)
            }
        }
        Spacer(Modifier.height(8.dp))

        val ordered = game.orderedPlayers
        val ranks = scoreRanks(ordered)
        Column(
            modifier = Modifier
                .clip(RoundedCornerShape(18.dp))
                .background(PaperSurface)
                .border(androidx.compose.foundation.BorderStroke(0.5.dp, Walnut.copy(alpha = 0.10f)), RoundedCornerShape(18.dp)),
        ) {
            ordered.forEachIndexed { idx, p ->
                PlayerRow(game, p, ranks[p.id] ?: (idx + 1))
                if (idx < ordered.size - 1) {
                    Box(Modifier.fillMaxWidth().height(0.5.dp).background(Walnut.copy(alpha = 0.08f)))
                }
            }
        }
    }
}

@Composable
private fun PlayerRow(game: Game, player: Player, rank: Int) {
    val isActive = player.id == game.activePlayer?.id
    val pct = (player.bankedScore.toFloat() / maxOf(1, game.targetScore)).coerceIn(0f, 1f)

    val avatarSize by animateDpAsState(if (isActive) 44.dp else 28.dp, tween(450), label = "avatar")
    val vPad by animateDpAsState(if (isActive) 14.dp else 10.dp, tween(450), label = "vpad")
    val bg by animateColorAsState(if (isActive) Walnut else Color.Transparent, tween(450), label = "bg")
    val nameColor = if (isActive) WalnutInk else Ink
    val scoreColor = if (isActive) WalnutInk else Ink

    Column(Modifier.background(bg)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = vPad),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.size(avatarSize), contentAlignment = Alignment.Center) {
                if (isActive) {
                    Icon(Icons.Filled.Casino, null, tint = Gold, modifier = Modifier.size(avatarSize * 0.62f))
                } else {
                    Avatar(player, size = avatarSize)
                }
            }
            Spacer(Modifier.width(12.dp))
            Text(
                player.name,
                color = nameColor,
                fontFamily = if (isActive) InstrumentSerif else PlexSans,
                fontStyle = if (isActive) FontStyle.Italic else FontStyle.Normal,
                fontWeight = if (isActive) FontWeight.Normal else FontWeight.Medium,
                fontSize = if (isActive) 26.sp else 15.sp,
                maxLines = 1,
            )
            Spacer(Modifier.weight(1f))
            // mini progress capsule
            Box(Modifier.width(50.dp).height(3.dp).clip(RoundedCornerShape(50)).background(Walnut.copy(alpha = 0.12f))) {
                Box(Modifier.fillMaxWidth(pct).height(3.dp).clip(RoundedCornerShape(50)).background(if (isActive) Gold else Walnut))
            }
            Spacer(Modifier.width(10.dp))
            CountingNumber(
                value = player.bankedScore,
                fontSize = if (isActive) 24.sp else 15.sp,
                color = scoreColor,
                modifier = Modifier.widthIn(min = 40.dp),
            )
            Spacer(Modifier.width(8.dp))
            RankBadge(rank, isActive)
        }
        if (isActive) {
            val barPct by animateFloatAsState(pct, tween(450), label = "bar")
            Box(Modifier.fillMaxWidth().height(3.dp).background(Walnut.copy(alpha = 0.15f))) {
                Box(Modifier.fillMaxWidth(barPct).height(3.dp).background(Gold))
            }
        }
    }
}

@Composable
private fun RankBadge(rank: Int, active: Boolean) {
    val bg = if (active) WalnutInk.copy(alpha = 0.12f) else if (rank == 1) Gold.copy(alpha = 0.25f) else Walnut.copy(alpha = 0.08f)
    val fg = if (active) WalnutInk.copy(alpha = 0.8f) else if (rank == 1) Walnut else Ink3
    Box(Modifier.clip(RoundedCornerShape(5.dp)).background(bg).padding(horizontal = 6.dp, vertical = 3.dp)) {
        Text(ordinal(rank), color = fg, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 10.sp)
    }
}

private fun scoreRanks(players: List<Player>): Map<String, Int> {
    val sorted = players.sortedByDescending { it.bankedScore }
    val ranks = HashMap<String, Int>()
    sorted.forEachIndexed { i, p ->
        ranks[p.id] = if (i > 0 && sorted[i - 1].bankedScore == p.bankedScore) ranks[sorted[i - 1].id]!! else i + 1
    }
    return ranks
}

fun ordinal(n: Int): String {
    val suffix = if ((n / 10) % 10 == 1) "th" else when (n % 10) {
        1 -> "st"; 2 -> "nd"; 3 -> "rd"; else -> "th"
    }
    return "$n$suffix"
}
