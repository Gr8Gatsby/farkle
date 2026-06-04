package com.feltandbone.farkle.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.model.Player
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.DisplayTitle
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink2
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.Paper2
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans

@Composable
fun StatsScreen(
    history: List<Game>,
    primaryPlayerName: String?,
    onSetPrimary: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val completed = remember(history) { history.filter { it.endedAt != null } }
    val names = remember(completed) {
        completed.flatMap { it.orderedPlayers }.map { it.name }.distinct().sorted()
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Paper)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        DisplayTitle(text = "Stats")

        if (completed.isEmpty() || names.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 48.dp),
                contentAlignment = Alignment.Center,
            ) {
                Caption("Play a game to see stats.")
            }
            return@Column
        }

        val defaultName = if (primaryPlayerName != null && names.contains(primaryPlayerName)) {
            primaryPlayerName
        } else {
            names.first()
        }
        var selectedName by remember(defaultName) { mutableStateOf(defaultName) }

        // Player picker.
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            names.forEach { name ->
                NameChip(
                    name = name,
                    selected = name == selectedName,
                    onClick = {
                        selectedName = name
                        onSetPrimary(name)
                    },
                )
            }
        }

        // Header with avatar + name.
        val avatarIndex = ((selectedName.hashCode() % 8) + 8) % 8
        val headerPlayer = Player(
            id = "",
            name = selectedName,
            avatarIndex = avatarIndex,
            orderIndex = 0,
            bankedScore = 0,
            hotDiceCount = 0,
            farkleCount = 0,
            photoBase64 = null,
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Avatar(player = headerPlayer, size = 64.dp)
            DisplayTitle(text = selectedName, size = 28)
        }

        // Compute stats for selected player.
        val playerGames = completed.filter { game ->
            game.orderedPlayers.any { it.name == selectedName }
        }
        val gamesCount = playerGames.size
        val wins = playerGames.count { it.winner?.name == selectedName }
        val winRate = if (gamesCount == 0) 0 else (wins * 100) / gamesCount

        var totalBanked = 0
        var totalHotDice = 0
        var totalFarkles = 0
        playerGames.forEach { game ->
            game.orderedPlayers.firstOrNull { it.name == selectedName }?.let { p ->
                totalBanked += p.bankedScore
                totalHotDice += p.hotDiceCount
                totalFarkles += p.farkleCount
            }
        }
        val avgScore = if (gamesCount == 0) 0 else totalBanked / gamesCount

        // Stat grid (2 columns).
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            StatCard(value = gamesCount.toString(), label = "Games", modifier = Modifier.weight(1f))
            StatCard(value = wins.toString(), label = "Wins", modifier = Modifier.weight(1f))
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            StatCard(value = "$winRate%", label = "Win rate", modifier = Modifier.weight(1f))
            StatCard(value = avgScore.grouped(), label = "Avg score", modifier = Modifier.weight(1f))
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            StatCard(value = totalHotDice.toString(), label = "Hot dice", modifier = Modifier.weight(1f))
            StatCard(value = totalFarkles.toString(), label = "Farkles", modifier = Modifier.weight(1f))
        }

        Caption("Badges & achievements coming later.")
    }
}

@Composable
private fun NameChip(name: String, selected: Boolean, onClick: () -> Unit) {
    val shape = RoundedCornerShape(50)
    Box(
        modifier = Modifier
            .clip(shape)
            .background(if (selected) Ink else Paper2)
            .clickable { onClick() }
            .padding(horizontal = 14.dp, vertical = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = name,
            color = if (selected) Paper else Ink2,
            fontFamily = PlexSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 13.sp,
        )
    }
}

@Composable
private fun StatCard(value: String, label: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(PaperSurface)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(
            text = value,
            color = Ink,
            fontFamily = JetBrainsMono,
            fontWeight = FontWeight.Bold,
            fontSize = 28.sp,
        )
        Spacer(Modifier.height(2.dp))
        Caption(label)
    }
}
