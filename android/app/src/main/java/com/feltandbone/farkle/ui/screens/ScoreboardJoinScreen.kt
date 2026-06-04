package com.feltandbone.farkle.ui.screens

import android.os.Handler
import android.os.Looper
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.net.DiscoveredHost
import com.feltandbone.farkle.net.FarkleClient
import com.feltandbone.farkle.net.PlayerClaim
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.DisplayTitle
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.Pill
import com.feltandbone.farkle.ui.components.firstName
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Felt
import com.feltandbone.farkle.ui.theme.FeltDeep
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.Bone
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.InstrumentSerif
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans

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
    Column(
        Modifier.fillMaxSize().background(Paper).statusBarsPadding().padding(24.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            DisplayTitle("Join a game", size = 30, modifier = Modifier.weight(1f))
            Text("Close", color = Ink3, fontFamily = PlexSans, modifier = Modifier.clickable(onClick = onClose).padding(8.dp))
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
                    Text("📡", fontSize = 20.sp)
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
    Box(Modifier.fillMaxSize().background(FeltDeep)) {
        Column(
            Modifier.fillMaxSize().statusBarsPadding().verticalScroll(rememberScrollState()).padding(20.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Eyebrow(game.name, color = Gold)
                    roomCode?.let { Caption("Room $it", color = Bone.copy(alpha = 0.7f)) }
                }
                Text("Leave", color = Bone.copy(alpha = 0.8f), fontFamily = PlexSans, modifier = Modifier.clickable(onClick = onClose).padding(8.dp))
            }
            Spacer(Modifier.height(16.dp))

            // Identity pick
            if (myId == null) {
                Text("Who are you?", color = Bone, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(8.dp))
            }

            val ranked = game.orderedPlayers.sortedByDescending { it.bankedScore }
            ranked.forEach { p ->
                val isActive = p.id == game.activePlayer?.id
                val isMe = p.id == myId
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(if (isActive) Felt else Felt.copy(alpha = 0.4f))
                        .clickable(enabled = myId == null) { onPick(p.id) }
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Avatar(p, size = 38.dp, highlighted = isActive)
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(p.name, color = Bone, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold)
                            if (isMe) { Spacer(Modifier.width(6.dp)); Pill("YOU", background = Gold, foreground = Ink) }
                            if (isActive) { Spacer(Modifier.width(6.dp)); Pill("ROLLING", background = Gold, foreground = Ink) }
                        }
                    }
                    Text(p.bankedScore.grouped(), color = Bone, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold, fontSize = 20.sp)
                }
                Spacer(Modifier.height(8.dp))
            }

            if (myId != null && game.activePlayer?.id == myId && game.endedAt == null) {
                Spacer(Modifier.height(8.dp))
                Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Gold).padding(14.dp)) {
                    Text("IT'S YOUR TURN — roll, then tell the scorekeeper", color = Ink, fontFamily = PlexSans, fontWeight = FontWeight.Bold)
                }
            }

            if (game.endedAt != null) {
                Spacer(Modifier.height(20.dp))
                Text("🏆", fontSize = 48.sp, modifier = Modifier.fillMaxWidth(), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
                Text(
                    "${firstName(game.winner?.name ?: "")} wins.",
                    color = Bone,
                    fontFamily = InstrumentSerif,
                    fontStyle = FontStyle.Italic,
                    fontSize = 32.sp,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                )
            }
        }

        if (hostQuit) {
            Box(Modifier.fillMaxSize().background(FeltDeep.copy(alpha = 0.95f)), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("Host ended the game", color = Bone, fontFamily = InstrumentSerif, fontStyle = FontStyle.Italic, fontSize = 28.sp)
                    Spacer(Modifier.height(12.dp))
                    Text("Back to Home", color = Gold, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, modifier = Modifier.clickable(onClick = onClose).padding(8.dp))
                }
            }
        }
    }
}
