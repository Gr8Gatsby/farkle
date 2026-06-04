package com.feltandbone.farkle.ui.screens

import android.os.Handler
import android.os.Looper
import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Casino
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.model.ActionKind
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.model.Player
import com.feltandbone.farkle.net.DiscoveredHost
import com.feltandbone.farkle.net.FarkleClient
import com.feltandbone.farkle.net.PlayerClaim
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.CountingNumber
import com.feltandbone.farkle.ui.components.DisplayTitle
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.firstName
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.components.timeAgo
import com.feltandbone.farkle.ui.theme.Crimson
import com.feltandbone.farkle.ui.theme.Felt
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.Gold2
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.InstrumentSerif
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut

@Composable
fun ScoreboardJoinScreen(onClose: () -> Unit) {
    val context = LocalContext.current
    val handler = remember { Handler(Looper.getMainLooper()) }

    var hosts by remember { mutableStateOf<List<DiscoveredHost>>(emptyList()) }
    var game by remember { mutableStateOf<Game?>(null) }
    var roomCode by remember { mutableStateOf<String?>(null) }
    var connected by remember { mutableStateOf(false) }
    var myId by remember { mutableStateOf<String?>(null) }

    val client = remember {
        FarkleClient(
            context = context,
            onHostsChanged = { list -> handler.post { hosts = list } },
            onSnapshot = { g, code -> handler.post { game = g; roomCode = code } },
            onConnectionChanged = { c -> handler.post { connected = c } },
            onHostEnded = { handler.post { } },
        )
    }
    DisposableEffect(Unit) {
        client.startDiscovery()
        onDispose { client.stop() }
    }

    val g = game
    if (g == null) {
        DiscoveryList(hosts, onClose) { code -> client.connect(code) }
    } else {
        val hostQuit = !connected && g.endedAt == null
        ScoreboardView(
            game = g,
            roomCode = roomCode,
            myId = myId,
            hostQuit = hostQuit,
            onPick = { id -> myId = id; client.sendClaim(PlayerClaim(id)) },
            onClose = onClose,
        )
    }
}

@Composable
private fun DiscoveryList(hosts: List<DiscoveredHost>, onClose: () -> Unit, onConnect: (String) -> Unit) {
    Column(Modifier.fillMaxSize().background(Paper).statusBarsPadding().padding(24.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            DisplayTitle("Join a game", size = 30, modifier = Modifier.weight(1f))
            Text("Close", color = com.feltandbone.farkle.ui.theme.Ink3, fontFamily = PlexSans, modifier = Modifier.clickable(onClick = onClose).padding(8.dp))
        }
        Spacer(Modifier.height(16.dp))
        Eyebrow("Nearby games")
        Spacer(Modifier.height(8.dp))
        if (hosts.isEmpty()) {
            Caption("Looking for nearby games on this network…")
        } else {
            hosts.forEach { h ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(PaperSurface)
                        .clickable { onConnect(h.roomCode) }
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.Casino, null, tint = Felt, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(12.dp))
                    Text("Room ${h.roomCode}", color = Ink, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                    Text("Join →", color = Felt, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold)
                }
                Spacer(Modifier.height(8.dp))
            }
        }
    }
}

@Composable
private fun ScoreboardView(
    game: Game,
    roomCode: String?,
    myId: String?,
    hostQuit: Boolean,
    onPick: (String) -> Unit,
    onClose: () -> Unit,
) {
    Box(Modifier.fillMaxSize().background(Felt)) {
        Box(
            Modifier.fillMaxSize().background(
                Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.06f), Color.Transparent, Color.Black.copy(alpha = 0.30f))),
            ),
        )

        if (game.endedAt != null) {
            WinCelebration(game, onClose)
        } else {
            Column(Modifier.fillMaxSize().statusBarsPadding()) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp).padding(top = 10.dp, bottom = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(Modifier.weight(1f)) {
                        Text(game.name, color = Paper, fontFamily = InstrumentSerif, fontStyle = FontStyle.Italic, fontSize = 22.sp)
                        Text(
                            (roomCode?.let { "room $it · " } ?: "") + "target ${game.targetScore.grouped()}",
                            color = Paper.copy(alpha = 0.6f), fontFamily = PlexSans, fontSize = 10.sp,
                        )
                    }
                    Box(Modifier.size(8.dp).clip(RoundedCornerShape(50)).background(Gold))
                    Spacer(Modifier.width(6.dp))
                    Text("LIVE", color = Gold, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 10.sp, letterSpacing = 1.4.sp)
                }

                Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 14.dp).padding(top = 6.dp)) {
                    if (game.isInFinalRound) {
                        FinalRoundBanner(game)
                        Spacer(Modifier.height(14.dp))
                    }
                    StandingsList(game, myId, onPick)
                    Spacer(Modifier.height(14.dp))
                    LiveFeed(game)
                    Spacer(Modifier.height(12.dp))
                }

                Text(
                    "Leave scoreboard",
                    color = Paper.copy(alpha = 0.7f),
                    fontFamily = PlexSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().clickable(onClick = onClose).padding(vertical = 16.dp),
                )
            }
        }

        if (hostQuit) {
            Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.6f)), contentAlignment = Alignment.Center) {
                Column(
                    Modifier.clip(RoundedCornerShape(18.dp)).background(Felt).padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text("Host ended the game.", color = Paper, fontFamily = InstrumentSerif, fontStyle = FontStyle.Italic, fontSize = 24.sp)
                    Spacer(Modifier.height(12.dp))
                    Text("Done", color = Gold, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, modifier = Modifier.clickable(onClick = onClose).padding(8.dp))
                }
            }
        }
    }
}

@Composable
private fun FinalRoundBanner(game: Game) {
    val active = game.activePlayer
    val bar = game.scoreToBeat ?: game.targetScore
    val needs = active?.let { bar - it.bankedScore + 50 }
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Color.Black.copy(alpha = 0.30f))
            .border(BorderStroke(1.dp, Gold.copy(alpha = 0.45f)), RoundedCornerShape(16.dp)).padding(16.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(48.dp).clip(RoundedCornerShape(12.dp)).background(Gold), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Flag, null, tint = Walnut, modifier = Modifier.size(24.dp))
            }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text("FINAL ROUND", color = Gold, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 11.sp, letterSpacing = 1.6.sp)
                if (active != null && needs != null && needs > 0) {
                    Text("${active.name} needs ${needs.grouped()} to win", color = Paper, fontFamily = PlexSans, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                }
            }
        }
        if (active != null && needs != null && needs > 0) {
            Spacer(Modifier.height(8.dp))
            Text(comboSuggestion(needs, active.id), color = Paper.copy(alpha = 0.6f), fontFamily = InstrumentSerif, fontStyle = FontStyle.Italic, fontSize = 16.sp)
        }
    }
}

@Composable
private fun StandingsList(game: Game, myId: String?, onPick: (String) -> Unit) {
    val ranked = game.orderedPlayers.sortedByDescending { it.bankedScore }
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Color.Black.copy(alpha = 0.22f))
            .border(BorderStroke(0.5.dp, Paper.copy(alpha = 0.06f)), RoundedCornerShape(16.dp)),
    ) {
        ranked.forEachIndexed { idx, p ->
            StandingsRow(game, p, idx + 1, myId, onPick)
            if (idx < ranked.size - 1) Box(Modifier.fillMaxWidth().height(0.5.dp).background(Paper.copy(alpha = 0.06f)))
        }
    }
}

@Composable
private fun StandingsRow(game: Game, player: Player, rank: Int, myId: String?, onPick: (String) -> Unit) {
    val isActive = player.id == game.activePlayer?.id
    val isMe = player.id == myId
    val pending = if (isActive) game.pendingTurnScore else 0
    val avatarSize = if (isActive) 40.dp else 28.dp
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (isActive) Modifier.border(BorderStroke(1.5.dp, Gold.copy(alpha = 0.6f)), RoundedCornerShape(12.dp)) else Modifier)
            .background(if (isActive) Color.Black.copy(alpha = 0.15f) else Color.Transparent)
            .then(if (myId == null) Modifier.clickable { onPick(player.id) } else Modifier)
            .padding(horizontal = 14.dp, vertical = if (isActive) 14.dp else 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(avatarSize), contentAlignment = Alignment.Center) {
            if (isActive) Icon(Icons.Filled.Casino, null, tint = Gold, modifier = Modifier.size(avatarSize * 0.55f))
            else Avatar(player, size = avatarSize)
        }
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(player.name, color = Paper, fontFamily = PlexSans, fontWeight = if (isActive) FontWeight.Bold else FontWeight.Medium, fontSize = if (isActive) 16.sp else 14.sp)
                if (isMe) {
                    Spacer(Modifier.width(6.dp))
                    Box(Modifier.clip(RoundedCornerShape(3.dp)).background(Paper).padding(horizontal = 5.dp, vertical = 2.dp)) {
                        Text("YOU", color = Felt, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 8.sp, letterSpacing = 0.6.sp)
                    }
                }
            }
            if (isActive && pending > 0) {
                Text("+${pending.grouped()}", color = Gold, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 11.sp)
            }
        }
        CountingNumber(value = player.bankedScore, fontSize = if (isActive) 28.sp else 18.sp, color = Paper)
        Spacer(Modifier.width(8.dp))
        Box(Modifier.clip(RoundedCornerShape(5.dp)).background(if (rank == 1) Gold.copy(alpha = 0.8f) else Paper.copy(alpha = 0.08f)).padding(horizontal = 6.dp, vertical = 3.dp)) {
            Text(ordinal(rank), color = if (rank == 1) Walnut else Paper.copy(alpha = 0.6f), fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 10.sp)
        }
    }
}

@Composable
private fun LiveFeed(game: Game) {
    val feed = game.orderedActions.reversed().take(8)
    Column {
        Text("LIVE FEED", color = Paper.copy(alpha = 0.55f), fontFamily = PlexSans, fontWeight = FontWeight.Bold, fontSize = 10.sp, letterSpacing = 1.6.sp)
        Spacer(Modifier.height(6.dp))
        if (feed.isEmpty()) {
            Text("Watching for the first roll…", color = Paper.copy(alpha = 0.55f), fontFamily = PlexSans, fontSize = 12.sp, modifier = Modifier.padding(vertical = 8.dp))
        } else {
            feed.forEach { e ->
                val name = firstName(game.player(e.playerId)?.name ?: "?")
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp).clip(RoundedCornerShape(8.dp)).background(Color.Black.copy(alpha = 0.20f)).padding(horizontal = 10.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    when (e.kind) {
                        ActionKind.BANK -> {
                            Icon(Icons.Filled.CheckCircle, null, tint = Gold2, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(8.dp))
                            Text("$name banked", color = Paper, fontFamily = PlexSans, fontSize = 12.sp)
                            Spacer(Modifier.width(6.dp))
                            Text("+${e.amount.grouped()}", color = Gold2, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                            if (e.hotDice) {
                                Spacer(Modifier.width(4.dp))
                                Icon(Icons.Filled.LocalFireDepartment, null, tint = Gold, modifier = Modifier.size(11.dp))
                            }
                        }
                        ActionKind.BUST -> {
                            Icon(Icons.Filled.Cancel, null, tint = Crimson, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(8.dp))
                            Text("$name farkled", color = Paper, fontFamily = PlexSans, fontSize = 12.sp)
                        }
                        ActionKind.START_FINAL_ROUND -> {
                            Icon(Icons.Filled.Flag, null, tint = Gold, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(8.dp))
                            Text("$name triggered the final round", color = Paper, fontFamily = PlexSans, fontSize = 12.sp)
                        }
                        ActionKind.END_GAME -> {
                            Icon(Icons.Filled.WorkspacePremium, null, tint = Gold, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(8.dp))
                            Text("$name won the game", color = Paper, fontFamily = PlexSans, fontSize = 12.sp)
                        }
                    }
                    Spacer(Modifier.weight(1f))
                    Text(timeAgo(e.timestamp), color = Paper.copy(alpha = 0.5f), fontFamily = JetBrainsMono, fontSize = 10.sp)
                }
            }
        }
    }
}

@Composable
private fun WinCelebration(game: Game, onClose: () -> Unit) {
    val winner = game.winner
    Column(
        Modifier.fillMaxSize().statusBarsPadding().padding(horizontal = 20.dp).padding(bottom = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(40.dp))
        Text("FARKLE", color = Gold, fontFamily = PlexSans, fontWeight = FontWeight.Bold, fontSize = 14.sp, letterSpacing = 4.sp)
        Spacer(Modifier.height(24.dp))
        if (winner != null) {
            Box(contentAlignment = Alignment.Center) {
                Box(Modifier.size(200.dp).clip(RoundedCornerShape(50)).background(Gold.copy(alpha = 0.18f)))
                Avatar(winner, size = 140.dp, highlighted = true)
                Box(
                    Modifier.align(Alignment.BottomEnd).clip(RoundedCornerShape(50)).background(Gold).padding(10.dp),
                ) { Icon(Icons.Filled.EmojiEvents, null, tint = Walnut, modifier = Modifier.size(22.dp)) }
            }
            Spacer(Modifier.height(16.dp))
            Text("${firstName(winner.name)} wins.", color = Paper, fontFamily = InstrumentSerif, fontStyle = FontStyle.Italic, fontSize = 48.sp, textAlign = TextAlign.Center)
            Text(winner.bankedScore.grouped(), color = Gold2, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 32.sp)
        }
        Spacer(Modifier.weight(1f))
        Text(
            "Done",
            color = Paper, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Color.White.copy(alpha = 0.10f)).clickable(onClick = onClose).padding(vertical = 14.dp),
        )
    }
}

// MARK: - Combo suggestion (parity with iOS ScoreboardView.comboSuggestion)

private data class Hand(val name: String, val plural: String, val value: Int)

private val comboHands = listOf(
    Hand("six-of-a-kind", "six-of-a-kinds", 3000),
    Hand("two triplets", "double triplets", 2500),
    Hand("five-of-a-kind", "five-of-a-kinds", 2000),
    Hand("a straight", "straights", 1500),
    Hand("three pairs", "three-pair rolls", 1500),
    Hand("four-of-a-kind", "four-of-a-kinds", 1000),
    Hand("three 6s", "triple 6s", 600),
    Hand("three 5s", "triple 5s", 500),
    Hand("three 4s", "triple 4s", 400),
    Hand("three 3s", "triple 3s", 300),
    Hand("three 1s", "triple 1s", 300),
    Hand("three 2s", "triple 2s", 200),
)

/** Deterministic, tongue-in-cheek "just roll X" suggestion seeded by player id. */
private fun comboSuggestion(needed: Int, seed: String): String {
    val h = seed.hashCode()
    val shuffled = comboHands.shuffled(java.util.Random(h.toLong())).toMutableList()
    var remaining = needed
    val picks = LinkedHashMap<String, Int>()
    while (remaining > 0 && shuffled.isNotEmpty() && picks.size < 4) {
        val idx = shuffled.indexOfFirst { it.value <= remaining }
        if (idx >= 0) {
            val hand = shuffled[idx]
            picks[hand.name] = (picks[hand.name] ?: 0) + 1
            remaining -= hand.value
        } else {
            shuffled.removeAt(0)
        }
    }
    if (remaining > 0) {
        val ones = (remaining + 99) / 100
        picks[if (ones == 1) "a lucky 1" else "$ones lucky 1s"] = 1
    }
    val parts = picks.map { (name, count) ->
        if (count == 1) name else "$count ${comboHands.firstOrNull { it.name == name }?.plural ?: name}"
    }
    val combo = if (parts.size == 1) parts[0] else parts.dropLast(1).joinToString(", ") + ", and " + parts.last()
    val prefixes = listOf("Just roll ", "All you need is ", "Easy — just roll ", "No big deal, just ", "Simple — ")
    val suffixes = listOf(" Easy!", " No sweat.", " Simple.", " What could go wrong?", " Totally doable.", " You got this.")
    val prefix = prefixes[Math.floorMod(h, prefixes.size)]
    val suffix = suffixes[Math.floorMod(h / 7, suffixes.size)]
    return "$prefix$combo.$suffix"
}
