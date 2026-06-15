package com.feltandbone.farkle.engine

import com.feltandbone.farkle.model.ActionKind
import com.feltandbone.farkle.model.ActionLogEntry
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.model.Player
import java.util.UUID
import kotlin.math.max

/**
 * Pure game-state transitions. Every function takes a [Game] and returns a new [Game];
 * derived totals are always rebuildable by replaying the action log. Parity with the
 * iOS `GameEngine`.
 */
object GameEngine {

    private fun now() = System.currentTimeMillis()

    fun bank(game: Game, hotDice: Boolean = false): Game {
        val player = game.activePlayer ?: return game
        val amount = game.pendingTurnScore
        if (amount <= 0) return game
        val mustOpen = game.rules.mustOpenWith
        if (mustOpen != null && player.bankedScore == 0 && amount < mustOpen) return game

        val roundForBank = game.currentRound
        val entry = ActionLogEntry(
            playerId = player.id,
            kind = ActionKind.BANK,
            amount = amount,
            timestamp = now(),
            orderIndex = game.actions.size,
            roundNumber = roundForBank,
            hotDice = hotDice,
            pendingTurnAtAction = amount,
        )
        val players = game.players.map {
            if (it.id == player.id) {
                it.copy(
                    bankedScore = it.bankedScore + amount,
                    hotDiceCount = it.hotDiceCount + if (hotDice) 1 else 0,
                )
            } else it
        }
        var g = game.copy(
            players = players,
            actions = game.actions + entry,
            pendingTurnScore = 0,
            pendingRollCount = 0,
        )

        val updated = players.first { it.id == player.id }
        if (g.finalRoundTriggeredByPlayerId == null && updated.bankedScore >= g.targetScore) {
            val trigger = ActionLogEntry(
                playerId = player.id,
                kind = ActionKind.START_FINAL_ROUND,
                amount = 0,
                timestamp = now(),
                orderIndex = g.actions.size,
                roundNumber = g.currentRound,
                pendingTurnAtAction = 0,
            )
            g = g.copy(
                finalRoundTriggeredByPlayerId = player.id,
                finalRoundTurnsRemaining = max(0, g.orderedPlayers.size - 1),
                finalRoundAnnouncementShown = false,
                actions = g.actions + trigger,
            )
        } else if (g.finalRoundTriggeredByPlayerId != null) {
            g = g.copy(finalRoundTurnsRemaining = max(0, g.finalRoundTurnsRemaining - 1))
        }

        return advancePlayerOrEndGame(g)
    }

    fun bust(game: Game): Game {
        val player = game.activePlayer ?: return game
        val snapshot = game.pendingTurnScore
        val entry = ActionLogEntry(
            playerId = player.id,
            kind = ActionKind.BUST,
            amount = 0,
            timestamp = now(),
            orderIndex = game.actions.size,
            roundNumber = game.currentRound,
            pendingTurnAtAction = snapshot,
        )
        val players = game.players.map {
            if (it.id == player.id) it.copy(farkleCount = it.farkleCount + 1) else it
        }
        var g = game.copy(
            players = players,
            actions = game.actions + entry,
            pendingTurnScore = 0,
            pendingRollCount = 0,
        )
        if (g.finalRoundTriggeredByPlayerId != null) {
            g = g.copy(finalRoundTurnsRemaining = max(0, g.finalRoundTurnsRemaining - 1))
        }
        return advancePlayerOrEndGame(g)
    }

    fun addToPending(game: Game, amount: Int): Game {
        if (amount <= 0) return game
        return game.copy(
            pendingTurnScore = game.pendingTurnScore + amount,
            pendingRollCount = game.pendingRollCount + 1,
        )
    }

    fun setPending(game: Game, amount: Int): Game = game.copy(pendingTurnScore = max(0, amount))

    fun clearPending(game: Game): Game = game.copy(pendingTurnScore = 0, pendingRollCount = 0)

    fun undoLast(game: Game): Game {
        val last = game.orderedActions.lastOrNull() ?: return game
        return undoThrough(game, last.orderIndex)
    }

    fun undo(game: Game, actionId: String): Game {
        val target = game.actions.firstOrNull { it.id == actionId } ?: return game
        return undoThrough(game, target.orderIndex)
    }

    private fun undoThrough(game: Game, orderIndex: Int): Game {
        val remaining = game.actions.filter { it.orderIndex < orderIndex }
        if (remaining.size == game.actions.size) return game
        return rebuildDerivedState(game.copy(actions = remaining))
    }

    /** Replace the amount on a past bank action. The action keeps its slot; totals are replayed. */
    fun setActionAmount(game: Game, actionId: String, newAmount: Int): Game {
        val target = game.actions.firstOrNull { it.id == actionId } ?: return game
        if (target.kind != ActionKind.BANK || newAmount <= 0) return game
        val newActions = game.actions.map {
            if (it.id == actionId) it.copy(amount = newAmount, pendingTurnAtAction = newAmount) else it
        }
        return rebuildDerivedState(game.copy(actions = newActions))
    }

    /** Re-assign orderIndex so players sort in the given order; the same physical player stays active. */
    fun reorderPlayers(game: Game, ids: List<String>): Game {
        val activeId = game.activePlayer?.id
        val players = game.players.map { p ->
            val idx = ids.indexOf(p.id)
            if (idx >= 0) p.copy(orderIndex = idx) else p
        }
        var g = game.copy(players = players)
        if (activeId != null) {
            val newIdx = g.orderedPlayers.indexOfFirst { it.id == activeId }
            if (newIdx >= 0) g = g.copy(activePlayerIndex = newIdx)
        }
        return g
    }

    /** Append a new player. Only allowed during the first round (see [Game.canAddPlayer]). */
    fun addPlayer(game: Game, name: String): Game {
        if (!game.canAddPlayer) return game
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return game
        val activeId = game.activePlayer?.id
        val nextIndex = game.orderedPlayers.size
        val player = Player(
            name = trimmed.take(20),
            avatarIndex = nextIndex,
            orderIndex = nextIndex,
        )
        var g = game.copy(players = game.players + player)
        if (activeId != null) {
            val newIdx = g.orderedPlayers.indexOfFirst { it.id == activeId }
            if (newIdx >= 0) g = g.copy(activePlayerIndex = newIdx)
        }
        return g
    }

    fun renamePlayer(game: Game, playerId: String, newName: String): Game {
        val trimmed = newName.trim()
        if (trimmed.isEmpty()) return game
        val players = game.players.map {
            if (it.id == playerId) it.copy(name = trimmed.take(20)) else it
        }
        return game.copy(players = players)
    }

    fun markFinalRoundAnnouncementShown(game: Game): Game =
        game.copy(finalRoundAnnouncementShown = true)

    private fun advancePlayerOrEndGame(game: Game): Game {
        val players = game.orderedPlayers
        if (players.isEmpty()) return game
        return if (game.finalRoundTriggeredByPlayerId != null && game.finalRoundTurnsRemaining <= 0) {
            val leader = players.maxByOrNull { it.bankedScore }
            val endEntry = ActionLogEntry(
                playerId = leader?.id ?: UUID.randomUUID().toString(),
                kind = ActionKind.END_GAME,
                amount = leader?.bankedScore ?: 0,
                timestamp = now(),
                orderIndex = game.actions.size,
                roundNumber = game.currentRound,
            )
            game.copy(
                winnerPlayerId = leader?.id,
                endedAt = now(),
                actions = game.actions + endEntry,
            )
        } else {
            game.copy(activePlayerIndex = (game.activePlayerIndex + 1) % players.size)
        }
    }

    private fun rebuildDerivedState(game: Game): Game {
        var players = game.players.map { it.copy(bankedScore = 0, hotDiceCount = 0, farkleCount = 0) }
        val playerCount = game.orderedPlayers.size
        var activeIdx = 0
        var finalTrigger: String? = null
        var finalRemaining = 0
        var finalAnnouncementShown = true
        var endedAt: Long? = null
        var winnerId: String? = null

        for (entry in game.orderedActions) {
            val idx = players.indexOfFirst { it.id == entry.playerId }
            when (entry.kind) {
                ActionKind.BANK -> {
                    if (idx >= 0) {
                        players = players.toMutableList().also {
                            it[idx] = it[idx].copy(
                                bankedScore = it[idx].bankedScore + entry.amount,
                                hotDiceCount = it[idx].hotDiceCount + if (entry.hotDice) 1 else 0,
                            )
                        }
                    }
                    if (finalTrigger != null) finalRemaining = max(0, finalRemaining - 1)
                    activeIdx = (activeIdx + 1) % max(1, playerCount)
                }
                ActionKind.BUST -> {
                    if (idx >= 0) {
                        players = players.toMutableList().also {
                            it[idx] = it[idx].copy(farkleCount = it[idx].farkleCount + 1)
                        }
                    }
                    if (finalTrigger != null) finalRemaining = max(0, finalRemaining - 1)
                    activeIdx = (activeIdx + 1) % max(1, playerCount)
                }
                ActionKind.START_FINAL_ROUND -> {
                    finalTrigger = entry.playerId
                    finalRemaining = max(0, playerCount - 1)
                    finalAnnouncementShown = false
                }
                ActionKind.END_GAME -> {
                    endedAt = entry.timestamp
                    winnerId = entry.playerId
                }
            }
        }

        return game.copy(
            players = players,
            activePlayerIndex = activeIdx,
            pendingTurnScore = 0,
            pendingRollCount = 0,
            finalRoundTriggeredByPlayerId = finalTrigger,
            finalRoundTurnsRemaining = finalRemaining,
            finalRoundAnnouncementShown = finalAnnouncementShown,
            winnerPlayerId = winnerId,
            endedAt = endedAt,
        )
    }
}
