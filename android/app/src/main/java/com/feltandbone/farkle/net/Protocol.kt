package com.feltandbone.farkle.net

import com.feltandbone.farkle.model.Game
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

const val FARKLE_SERVICE_TYPE = "_farkle._tcp."

/** A read-only mirror of the host's game state, plus the room code. Parity with iOS GameSnapshot. */
@Serializable
data class Snapshot(val roomCode: String, val game: Game)

/** Sent by a joiner to claim a seat and (optionally) attach a photo. Parity with iOS PlayerClaim. */
@Serializable
data class PlayerClaim(val playerId: String, val photoBase64: String? = null)

/** Wire envelope so host and joiner can multiplex snapshot/claim messages over one channel. */
@Serializable
data class Envelope(
    val type: String,
    val snapshot: Snapshot? = null,
    val claim: PlayerClaim? = null,
) {
    companion object {
        const val SNAPSHOT = "snapshot"
        const val CLAIM = "claim"
    }
}

val netJson = Json { ignoreUnknownKeys = true; encodeDefaults = true }

/** A host discovered on the local network. */
data class DiscoveredHost(val serviceName: String, val roomCode: String)
