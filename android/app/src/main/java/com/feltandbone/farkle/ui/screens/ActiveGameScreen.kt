package com.feltandbone.farkle.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
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
import com.feltandbone.farkle.model.ActionKind
import com.feltandbone.farkle.model.ActionLogEntry
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.model.Player
import com.feltandbone.farkle.ui.AppViewModel
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.Pill
import com.feltandbone.farkle.ui.components.PrimaryButton
import com.feltandbone.farkle.ui.components.SecondaryButton
import com.feltandbone.farkle.ui.components.ValueChip
import com.feltandbone.farkle.ui.components.firstName
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.components.timeAgo
import com.feltandbone.farkle.ui.theme.Crimson
import com.feltandbone.farkle.ui.theme.Felt
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink2
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.InstrumentSerif
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.Paper2
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
    var editAction by remember { mutableStateOf<ActionLogEntry?>(null) }

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
        // Top bar
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconBtn(Icons.AutoMirrored.Filled.ArrowBack, "Leave game") { confirmLeave = true }
            Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    "Round ${game.currentRound}",
                    color = Ink,
                    fontFamily = PlexSans,
                    fontWeight = FontWeight.SemiBold,
                )
                Caption("to ${game.targetScore.grouped()}")
                vm.roomCode?.let { code ->
                    Spacer(Modifier.height(2.dp))
                    Pill(
                        if (vm.viewerCount > 0) "📡 $code · 👤 ${vm.viewerCount}" else "📡 $code",
                        background = Paper2,
                        foreground = Walnut,
                    )
                }
            }
            IconBtn(Icons.AutoMirrored.Filled.Undo, "Undo", enabled = game.actions.isNotEmpty()) {
                vm.undoLast()
            }
        }

        Column(
            modifier = Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp),
        ) {
            NowRollingBanner(active, game)
            Spacer(Modifier.height(14.dp))
            PendingCard(
                game = game,
                onChip = { vm.addToPending(it) },
                onCustom = { sheet = ActiveSheet.Keypad },
                onHelper = { sheet = ActiveSheet.Helper },
                onClear = { vm.clearPending() },
                onFarkle = { sheet = ActiveSheet.Farkle },
            )
            Spacer(Modifier.height(18.dp))
            StandingsLadder(game, onEdit = { sheet = ActiveSheet.EditPlayers })
            Spacer(Modifier.height(18.dp))
            RecentActions(game, onTap = { editAction = it })
            Spacer(Modifier.height(18.dp))
        }

        // Bottom Bank bar
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(Paper)
                .padding(horizontal = 16.dp, vertical = 10.dp)
                .navigationBarsPadding(),
        ) {
            val preview = if (active != null && pending > 0)
                "+${pending.grouped()} → ${(active.bankedScore + pending).grouped()}" else "Bank"
            PrimaryButton(
                label = preview,
                enabled = canBank,
                subtext = if (blockedByMustOpen) "Must open with ${mustOpen}" else null,
            ) { sheet = ActiveSheet.BankConfirm }
        }
    }

    // --- Sheets ---
    when (sheet) {
        ActiveSheet.Keypad -> Sheet(onDismiss = { sheet = null }) {
            NumberKeypad(title = "Add to turn", confirmLabel = "Add to turn") {
                vm.addToPending(it); sheet = null
            }
        }
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

    editAction?.let { entry ->
        Sheet(onDismiss = { editAction = null }) {
            EditActionSheet(
                game = game,
                entry = entry,
                onEditAmount = { amt -> vm.setActionAmount(entry.id, amt); editAction = null },
                onUndo = { vm.undo(entry.id); editAction = null },
                onCancel = { editAction = null },
            )
        }
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

enum class ActiveSheet { Keypad, Helper, BankConfirm, Farkle, EditPlayers }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun Sheet(onDismiss: () -> Unit, content: @Composable () -> Unit) {
    val state = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = state, containerColor = Paper) {
        Column(Modifier.imePadding()) { content() }
    }
}

@Composable
private fun IconBtn(icon: androidx.compose.ui.graphics.vector.ImageVector, desc: String, enabled: Boolean = true, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(44.dp)
            .clip(CircleShape)
            .clickable(enabled = enabled) { onClick() },
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = desc, tint = if (enabled) Walnut else Ink3)
    }
}

@Composable
private fun NowRollingBanner(active: Player?, game: Game) {
    AnimatedContent(
        targetState = active?.id,
        transitionSpec = { fadeIn() togetherWith fadeOut() },
        label = "nowrolling",
    ) { _ ->
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(18.dp))
                .background(Walnut)
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (active != null) {
                Avatar(active, size = 48.dp, highlighted = true)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(8.dp).clip(CircleShape).background(Gold))
                        Spacer(Modifier.width(6.dp))
                        Text("ROLLING", color = Gold, fontFamily = JetBrainsMono, fontSize = 11.sp, letterSpacing = 2.sp)
                    }
                    Text(
                        active.name,
                        color = WalnutInk,
                        fontFamily = InstrumentSerif,
                        fontStyle = FontStyle.Italic,
                        fontSize = 28.sp,
                    )
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text("BANKED", color = WalnutInk.copy(alpha = 0.7f), fontFamily = JetBrainsMono, fontSize = 10.sp)
                    Text(
                        active.bankedScore.grouped(),
                        color = WalnutInk,
                        fontFamily = JetBrainsMono,
                        fontWeight = FontWeight.Bold,
                        fontSize = 22.sp,
                    )
                }
            }
        }
    }
}

@Composable
private fun PendingCard(
    game: Game,
    onChip: (Int) -> Unit,
    onCustom: () -> Unit,
    onHelper: () -> Unit,
    onClear: () -> Unit,
    onFarkle: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(PaperSurface)
            .padding(16.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Eyebrow("Not banked yet", modifier = Modifier.weight(1f))
            Caption("${game.pendingRollCount} rolls")
        }
        Spacer(Modifier.height(4.dp))
        Text(
            game.pendingTurnScore.grouped(),
            color = Ink,
            fontFamily = JetBrainsMono,
            fontWeight = FontWeight.Bold,
            fontSize = 52.sp,
        )
        Spacer(Modifier.height(10.dp))
        // Quick-add chips
        val chips = listOf(50, 100, 150, 200, 300, 350, 500, 1000)
        Column {
            chips.chunked(4).forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    row.forEach { v ->
                        ValueChip(v.grouped(), modifier = Modifier.weight(1f)) { onChip(v) }
                    }
                }
                Spacer(Modifier.height(8.dp))
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            SecondaryButton("+ Custom", modifier = Modifier.weight(1f)) { onCustom() }
            Spacer(Modifier.width(8.dp))
            SecondaryButton("Score helper", modifier = Modifier.weight(1f), color = Felt) { onHelper() }
        }
        Spacer(Modifier.height(8.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "Clear",
                color = Ink3,
                fontFamily = PlexSans,
                modifier = Modifier.clickable { onClear() }.padding(8.dp).weight(1f),
            )
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(50))
                    .background(Crimson)
                    .clickable { onFarkle() }
                    .padding(horizontal = 20.dp, vertical = 10.dp),
            ) {
                Text("✕ FARKLE", color = WalnutInk, fontFamily = PlexSans, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun StandingsLadder(game: Game, onEdit: () -> Unit) {
    Column {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Eyebrow("Standings", modifier = Modifier.weight(1f))
            Icon(
                Icons.Filled.Edit,
                contentDescription = "Edit players",
                tint = Ink3,
                modifier = Modifier.size(28.dp).clip(CircleShape).clickable { onEdit() }.padding(4.dp),
            )
        }
        Spacer(Modifier.height(8.dp))
        val ranked = game.orderedPlayers.sortedByDescending { it.bankedScore }
        ranked.forEachIndexed { idx, p ->
            val isActive = p.id == game.activePlayer?.id
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(if (isActive) Paper2 else PaperSurface)
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("${idx + 1}", color = Ink3, fontFamily = JetBrainsMono, modifier = Modifier.width(22.dp))
                Avatar(p, size = 34.dp, highlighted = isActive)
                Spacer(Modifier.width(10.dp))
                Column(Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(p.name, color = Ink, fontFamily = PlexSans, fontWeight = FontWeight.Medium)
                        if (isActive) {
                            Spacer(Modifier.width(6.dp))
                            Pill("ROLLING", background = Gold, foreground = Ink)
                        }
                    }
                    Spacer(Modifier.height(4.dp))
                    LinearProgressIndicator(
                        progress = { (p.bankedScore.toFloat() / game.targetScore).coerceIn(0f, 1f) },
                        modifier = Modifier.fillMaxWidth().height(5.dp),
                        color = Felt,
                        trackColor = Paper2,
                    )
                }
                Spacer(Modifier.width(10.dp))
                Text(p.bankedScore.grouped(), color = Ink, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.height(6.dp))
        }
    }
}

@Composable
private fun RecentActions(game: Game, onTap: (ActionLogEntry) -> Unit) {
    val recent = game.orderedActions
        .filter { it.kind == ActionKind.BANK || it.kind == ActionKind.BUST }
        .takeLast(5).reversed()
    if (recent.isEmpty()) return
    Column {
        Eyebrow("Recent actions")
        Spacer(Modifier.height(8.dp))
        recent.forEach { e ->
            val p = game.player(e.playerId)
            val isBank = e.kind == ActionKind.BANK
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(PaperSurface)
                    .clickable { onTap(e) }
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    if (isBank) "🏦" else "✕",
                    color = if (isBank) Felt else Crimson,
                    fontSize = 16.sp,
                )
                Spacer(Modifier.width(10.dp))
                Text(p?.name ?: "?", color = Ink, fontFamily = PlexSans, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
                Text(
                    if (isBank) "+${e.amount.grouped()}" else "Farkle",
                    color = if (isBank) Ink else Crimson,
                    fontFamily = JetBrainsMono,
                    fontWeight = FontWeight.Bold,
                )
                Spacer(Modifier.width(8.dp))
                Caption(timeAgo(e.timestamp))
            }
            Spacer(Modifier.height(6.dp))
        }
    }
}
