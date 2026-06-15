package com.feltandbone.farkle.model

import kotlinx.serialization.Serializable
import java.util.Calendar
import java.util.UUID

/**
 * Immutable game state. Mutations are performed by [com.feltandbone.farkle.engine.GameEngine],
 * which returns new [Game] instances. Parity with the iOS `Game` model.
 */
@Serializable
data class Game(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val createdAt: Long,
    val endedAt: Long? = null,
    val targetScore: Int,
    val rules: HouseRules,
    val players: List<Player>,
    val actions: List<ActionLogEntry> = emptyList(),
    val activePlayerIndex: Int = 0,
    val pendingTurnScore: Int = 0,
    val pendingRollCount: Int = 0,
    val finalRoundTriggeredByPlayerId: String? = null,
    val finalRoundTurnsRemaining: Int = 0,
    /**
     * False from the moment a final-round trigger is logged until the player
     * dismisses the "X hits the target" announcement screen.
     */
    val finalRoundAnnouncementShown: Boolean = true,
    val winnerPlayerId: String? = null,
) {
    val orderedPlayers: List<Player> get() = players.sortedBy { it.orderIndex }
    val orderedActions: List<ActionLogEntry> get() = actions.sortedBy { it.orderIndex }
    val isInProgress: Boolean get() = endedAt == null
    val isInFinalRound: Boolean get() = finalRoundTriggeredByPlayerId != null && endedAt == null

    val activePlayer: Player?
        get() {
            val ordered = orderedPlayers
            if (ordered.isEmpty()) return null
            return ordered[activePlayerIndex % ordered.size]
        }

    /**
     * During the final round, the score the next bank has to exceed in order to win.
     * The highest banked total among all players (so if someone overtakes the trigger
     * player mid-final-round, the bar moves up).
     */
    val scoreToBeat: Int?
        get() = if (isInFinalRound) orderedPlayers.maxOfOrNull { it.bankedScore } else null

    /** Players who still have a turn in the final round, in turn order starting after the trigger. */
    val remainingFinalRoundPlayers: List<Player>
        get() {
            val trigger = finalRoundTriggeredByPlayerId ?: return emptyList()
            val ordered = orderedPlayers
            val triggerIdx = ordered.indexOfFirst { it.id == trigger }
            if (triggerIdx < 0) return emptyList()
            val count = ordered.size
            val rotated = (1 until count).map { ordered[(triggerIdx + it) % count] }
            return rotated.take(finalRoundTurnsRemaining)
        }

    val winner: Player? get() = winnerPlayerId?.let { id -> players.firstOrNull { it.id == id } }

    val currentRound: Int
        get() {
            val ordered = orderedPlayers
            if (ordered.isEmpty()) return 1
            val turns = orderedActions.count { it.kind == ActionKind.BANK || it.kind == ActionKind.BUST }
            return 1 + turns / ordered.size
        }

    /**
     * True while still in the first round of turn-taking — i.e. at least one player
     * hasn't rolled yet. Once everyone has banked or busted once, no more new players
     * can be added; reordering can still happen.
     */
    val isFirstRoundIncomplete: Boolean
        get() {
            if (players.isEmpty()) return true
            val turns = orderedActions.count { it.kind == ActionKind.BANK || it.kind == ActionKind.BUST }
            return turns < players.size
        }

    val canAddPlayer: Boolean
        get() = endedAt == null && players.size < 8 && isFirstRoundIncomplete

    fun player(id: String?): Player? = id?.let { pid -> players.firstOrNull { it.id == pid } }

    companion object {
        fun create(name: String, targetScore: Int, rules: HouseRules, players: List<Player>): Game =
            Game(
                name = name,
                createdAt = System.currentTimeMillis(),
                targetScore = targetScore,
                rules = rules,
                players = players,
            )

        /** Auto-generated game name like "Tuesday Night Roll" — parity with iOS. */
        fun generateName(calendar: Calendar = Calendar.getInstance()): String {
            val days = listOf(
                "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
            )
            val day = days[(calendar.get(Calendar.DAY_OF_WEEK) - 1).coerceIn(0, 6)]
            val hour = calendar.get(Calendar.HOUR_OF_DAY)
            val suffix = when (hour) {
                in 5..11 -> "Morning Roll"
                in 12..16 -> "Afternoon Roll"
                in 17..21 -> "Night Roll"
                else -> "Late Roll"
            }
            return "$day $suffix"
        }
    }
}
