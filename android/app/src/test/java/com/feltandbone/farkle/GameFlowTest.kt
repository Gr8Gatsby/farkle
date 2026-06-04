package com.feltandbone.farkle

import com.feltandbone.farkle.engine.GameEngine
import com.feltandbone.farkle.model.ActionKind
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.model.HouseRules
import com.feltandbone.farkle.model.Player
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class GameFlowTest {

    private fun makeGame(target: Int = 10000, names: List<String> = listOf("Maya", "Jules")): Game {
        val players = names.mapIndexed { idx, n -> Player(name = n, avatarIndex = idx, orderIndex = idx) }
        return Game.create("Test", target, HouseRules.DEFAULT, players)
    }

    @Test fun bankAdvancesActivePlayer() {
        var g = makeGame()
        g = GameEngine.addToPending(g, 500)
        g = GameEngine.bank(g)
        assertEquals("Jules", g.activePlayer?.name)
        assertEquals(500, g.orderedPlayers[0].bankedScore)
        assertEquals(0, g.pendingTurnScore)
    }

    @Test fun bustAdvancesAndZeroesPending() {
        var g = makeGame()
        g = GameEngine.addToPending(g, 750)
        g = GameEngine.bust(g)
        assertEquals("Jules", g.activePlayer?.name)
        assertEquals(0, g.orderedPlayers[0].bankedScore)
        assertEquals(1, g.orderedPlayers[0].farkleCount)
    }

    @Test fun mustOpenWith500BlocksLowBank() {
        var g = makeGame()
        g = GameEngine.addToPending(g, 300)
        g = GameEngine.bank(g)
        assertEquals(0, g.orderedPlayers[0].bankedScore)
        assertEquals("Maya", g.activePlayer?.name)
    }

    @Test fun targetHit_doesNotGiveTriggerAnotherTurn() {
        var g = makeGame(target = 1000, names = listOf("Maya", "Jules", "Theo"))
        g = GameEngine.addToPending(g, 1000)
        g = GameEngine.bank(g)
        assertEquals("Jules", g.activePlayer?.name)
        assertEquals(2, g.finalRoundTurnsRemaining)
        assertFalse(g.finalRoundAnnouncementShown)
    }

    @Test fun finalRoundAnnouncement_canBeDismissed() {
        var g = makeGame(target = 1000)
        g = GameEngine.addToPending(g, 1000)
        g = GameEngine.bank(g)
        assertFalse(g.finalRoundAnnouncementShown)
        g = GameEngine.markFinalRoundAnnouncementShown(g)
        assertTrue(g.finalRoundAnnouncementShown)
    }

    @Test fun scoreToBeat_reflectsLeadingTotal() {
        var g = makeGame(target = 1000, names = listOf("Maya", "Jules"))
        g = GameEngine.addToPending(g, 1000)
        g = GameEngine.bank(g)
        assertEquals(1000, g.scoreToBeat)
        g = GameEngine.addToPending(g, 1200)
        g = GameEngine.bank(g)
        assertNotNull(g.endedAt)
        assertEquals(g.orderedPlayers[1].id, g.winnerPlayerId)
    }

    @Test fun setActionAmount_editsPastBank() {
        var g = makeGame()
        g = GameEngine.addToPending(g, 500); g = GameEngine.bank(g)
        g = GameEngine.addToPending(g, 600); g = GameEngine.bank(g)
        val mayaBankId = g.orderedActions.first { it.kind == ActionKind.BANK }.id
        g = GameEngine.setActionAmount(g, mayaBankId, 800)
        assertEquals(800, g.orderedPlayers[0].bankedScore)
        assertEquals(600, g.orderedPlayers[1].bankedScore)
    }

    @Test fun reorderPlayers_keepsActivePlayerActive() {
        var g = makeGame(names = listOf("Maya", "Jules", "Theo"))
        g = GameEngine.addToPending(g, 500); g = GameEngine.bank(g)
        assertEquals("Jules", g.activePlayer?.name)
        val theo = g.orderedPlayers[2].id
        val jules = g.orderedPlayers[1].id
        val maya = g.orderedPlayers[0].id
        g = GameEngine.reorderPlayers(g, listOf(theo, jules, maya))
        assertEquals("Jules", g.activePlayer?.name)
    }

    @Test fun addPlayer_allowedInFirstRound() {
        var g = makeGame(names = listOf("Maya", "Jules"))
        assertTrue(g.canAddPlayer)
        g = GameEngine.addPlayer(g, "Theo")
        assertEquals("Theo", g.orderedPlayers.last().name)
    }

    @Test fun addPlayer_blocked_afterFirstRound() {
        var g = makeGame(names = listOf("Maya", "Jules"))
        g = GameEngine.addToPending(g, 500); g = GameEngine.bank(g)
        g = GameEngine.addToPending(g, 500); g = GameEngine.bank(g)
        assertFalse(g.canAddPlayer)
        val before = g.players.size
        g = GameEngine.addPlayer(g, "Theo")
        assertEquals(before, g.players.size)
    }

    @Test fun addPlayer_allowedWhenLastSeatYetToRoll() {
        var g = makeGame(names = listOf("Maya", "Jules"))
        g = GameEngine.addToPending(g, 500); g = GameEngine.bank(g)
        assertTrue(g.canAddPlayer)
    }

    @Test fun setActionAmount_refusesBustEdit() {
        var g = makeGame()
        g = GameEngine.addToPending(g, 400)
        g = GameEngine.bust(g)
        val bustId = g.orderedActions.first { it.kind == ActionKind.BUST }.id
        val before = g.actions.first { it.id == bustId }.amount
        g = GameEngine.setActionAmount(g, bustId, 200)
        assertEquals(before, g.actions.first { it.id == bustId }.amount)
    }

    @Test fun targetHitTriggersFinalRound_andEndsAfterOthersPlay() {
        var g = makeGame(target = 1000)
        g = GameEngine.addToPending(g, 1000); g = GameEngine.bank(g)
        assertNotNull(g.finalRoundTriggeredByPlayerId)
        assertEquals(1, g.finalRoundTurnsRemaining)
        assertNull(g.endedAt)
        g = GameEngine.addToPending(g, 500); g = GameEngine.bank(g)
        assertNotNull(g.endedAt)
        assertEquals(g.orderedPlayers[0].id, g.winnerPlayerId)
    }

    @Test fun undoLast_reversesBank() {
        var g = makeGame()
        g = GameEngine.addToPending(g, 500); g = GameEngine.bank(g)
        g = GameEngine.undoLast(g)
        assertEquals(0, g.orderedPlayers[0].bankedScore)
        assertEquals("Maya", g.activePlayer?.name)
        assertTrue(g.actions.isEmpty())
    }

    @Test fun undoFromGameOver_restoresActiveGame() {
        var g = makeGame(target = 500)
        g = GameEngine.addToPending(g, 500); g = GameEngine.bank(g)
        g = GameEngine.bust(g)
        assertNotNull(g.endedAt)
        g = GameEngine.undoLast(g)
        assertNull(g.endedAt)
    }
}
