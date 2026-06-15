package com.feltandbone.farkle.model

import kotlinx.serialization.Serializable
import java.util.UUID

/** House rules — parity with iOS HouseRules. */
@Serializable
data class HouseRules(
    val threePair: Boolean = true,
    val straight: Boolean = true,
    val twoTriples: Boolean = true,
    val fourOfAKindWithPair: Boolean = true,
    val mustOpenWith: Int? = 500,
) {
    companion object {
        val DEFAULT = HouseRules()
    }
}

@Serializable
data class Player(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val avatarIndex: Int,
    val orderIndex: Int,
    val bankedScore: Int = 0,
    val hotDiceCount: Int = 0,
    val farkleCount: Int = 0,
    /** Optional photo claimed by a remote viewer for this seat (base64 JPEG). */
    val photoBase64: String? = null,
)

@Serializable
enum class ActionKind { BANK, BUST, START_FINAL_ROUND, END_GAME }

@Serializable
data class ActionLogEntry(
    val id: String = UUID.randomUUID().toString(),
    val playerId: String,
    val kind: ActionKind,
    val amount: Int,
    val timestamp: Long,
    val orderIndex: Int,
    val roundNumber: Int,
    val hotDice: Boolean = false,
    val pendingTurnAtAction: Int = 0,
)
