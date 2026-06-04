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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.DisplayTitle
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.PrimaryButton
import com.feltandbone.farkle.ui.components.SecondaryButton
import com.feltandbone.farkle.ui.components.firstName
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Felt
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink2
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.WalnutInk
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun HomeScreen(
    activeGame: Game?,
    recentGames: List<Game>,
    onResume: () -> Unit,
    onNewGame: () -> Unit,
    onJoin: () -> Unit,
    onOpenRecap: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp, vertical = 16.dp),
    ) {
        DisplayTitle("Hey, fancy a roll?", italic = true, size = 34)
        Spacer(Modifier.height(20.dp))

        if (activeGame != null && activeGame.isInProgress) {
            ResumeCard(activeGame, onResume)
            Spacer(Modifier.height(16.dp))
        }

        PrimaryButton(label = "Start a new game", onClick = onNewGame)
        Spacer(Modifier.height(10.dp))
        SecondaryButton(label = "Join a game", color = Felt, onClick = onJoin)

        Spacer(Modifier.height(24.dp))
        Eyebrow("Recent games")
        Spacer(Modifier.height(8.dp))
        val completed = recentGames.filter { it.endedAt != null }.take(5)
        if (completed.isEmpty()) {
            Caption("No finished games yet.")
        } else {
            completed.forEach { g ->
                RecentRow(g) { onOpenRecap(g.id) }
                Spacer(Modifier.height(8.dp))
            }
        }
    }
}

@Composable
private fun ResumeCard(game: Game, onResume: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Felt)
            .clickable { onResume() }
            .padding(18.dp),
    ) {
        Eyebrow("Game in progress", color = Gold)
        Spacer(Modifier.height(6.dp))
        Text(game.name, color = WalnutInk, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.height(10.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            game.orderedPlayers.take(8).forEach { p ->
                Avatar(p, size = 30.dp)
                Spacer(Modifier.width(4.dp))
            }
        }
        Spacer(Modifier.height(10.dp))
        val active = game.activePlayer
        Text(
            "Round ${game.currentRound} · ${active?.name ?: ""} is rolling",
            color = WalnutInk.copy(alpha = 0.85f),
            fontFamily = PlexSans,
        )
        Spacer(Modifier.height(12.dp))
        PrimaryButton(label = "Resume", color = Gold, foreground = Ink, onClick = onResume)
    }
}

@Composable
private fun RecentRow(game: Game, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(PaperSurface)
            .clickable { onClick() }
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(game.name, color = Ink, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(2.dp))
            val date = game.endedAt?.let { SimpleDateFormat("MMM d", Locale.US).format(Date(it)) } ?: ""
            Caption("$date · ${game.orderedPlayers.size} players")
        }
        Column(horizontalAlignment = Alignment.End) {
            val w = game.winner
            Text(
                "🏆 ${w?.let { firstName(it.name) } ?: "—"}",
                color = Ink,
                fontFamily = PlexSans,
                fontWeight = FontWeight.Medium,
            )
            Caption("${(w?.bankedScore ?: 0).grouped()}", color = Ink2)
        }
    }
}
