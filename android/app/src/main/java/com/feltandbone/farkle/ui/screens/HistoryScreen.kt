package com.feltandbone.farkle.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material3.Icon
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
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
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.DisplayTitle
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.durationLabel
import com.feltandbone.farkle.ui.components.firstName
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Crimson
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink2
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.Paper2
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

private enum class HistoryFilter(val label: String) {
    ALL("All games"),
    MY_WINS("My wins"),
    FOUR_PLUS("4+ players"),
    THIS_MONTH("This month"),
}

@Composable
fun HistoryScreen(
    history: List<Game>,
    primaryPlayerName: String?,
    onOpenRecap: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val completed = remember(history) {
        history.filter { it.endedAt != null }.sortedByDescending { it.endedAt }
    }

    val totalGames = completed.size
    val totalWins = if (primaryPlayerName == null) {
        null
    } else {
        completed.count { it.winner?.name == primaryPlayerName }
    }
    val winRate = if (totalWins == null || totalGames == 0) {
        null
    } else {
        (totalWins * 100) / totalGames
    }

    var filter by remember { mutableStateOf(HistoryFilter.ALL) }

    val now = remember { Calendar.getInstance() }
    val nowYear = now.get(Calendar.YEAR)
    val nowMonth = now.get(Calendar.MONTH)

    val filtered = completed.filter { game ->
        when (filter) {
            HistoryFilter.ALL -> true
            HistoryFilter.MY_WINS -> game.winner?.name == primaryPlayerName
            HistoryFilter.FOUR_PLUS -> game.orderedPlayers.size >= 4
            HistoryFilter.THIS_MONTH -> {
                val cal = Calendar.getInstance().apply { timeInMillis = game.endedAt ?: 0L }
                cal.get(Calendar.YEAR) == nowYear && cal.get(Calendar.MONTH) == nowMonth
            }
        }
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
        DisplayTitle(text = "History")

        // Header stats card.
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(PaperSurface)
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
        ) {
            HeaderStat(value = totalGames.toString(), label = "Games")
            HeaderStat(value = totalWins?.toString() ?: "—", label = "Wins")
            HeaderStat(value = winRate?.let { "$it%" } ?: "—", label = "Win rate")
        }

        // Filter chips.
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            HistoryFilter.values().forEach { f ->
                FilterChip(
                    label = f.label,
                    selected = filter == f,
                    onClick = { filter = f },
                )
            }
        }

        if (completed.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 48.dp),
                contentAlignment = Alignment.Center,
            ) {
                Caption("No games yet — your finished games will show up here.")
            }
        } else {
            filtered.forEach { game ->
                GameRow(game = game, onClick = { onOpenRecap(game.id) })
            }
        }
    }
}

@Composable
private fun HeaderStat(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            color = Ink,
            fontFamily = JetBrainsMono,
            fontWeight = FontWeight.Bold,
            fontSize = 24.sp,
        )
        Spacer(Modifier.height(4.dp))
        Caption(label)
    }
}

@Composable
private fun FilterChip(label: String, selected: Boolean, onClick: () -> Unit) {
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
            text = label,
            color = if (selected) Paper else Ink2,
            fontFamily = PlexSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 13.sp,
        )
    }
}

@Composable
private fun GameRow(game: Game, onClick: () -> Unit) {
    val dateFmt = remember { SimpleDateFormat("MMM d", Locale.US) }
    val winner = game.winner
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(PaperSurface)
            .clickable { onClick() }
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = game.name,
                color = Ink,
                fontFamily = PlexSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 17.sp,
                modifier = Modifier.weight(1f),
            )
            game.endedAt?.let {
                Caption(dateFmt.format(Date(it)))
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            game.orderedPlayers.forEach { player ->
                Avatar(player = player, size = 26.dp)
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Eyebrow("${game.currentRound} rounds")
            game.endedAt?.let {
                Caption("· ${durationLabel(game.createdAt, it)}")
            }
        }

        if (winner != null) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.EmojiEvents, null, tint = Crimson, modifier = Modifier.size(14.dp))
                Spacer(Modifier.width(4.dp))
                Text(
                    text = "${firstName(winner.name)} · ${winner.bankedScore.grouped()}",
                    color = Crimson,
                    fontFamily = PlexSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp,
                )
            }
        }
    }
}
