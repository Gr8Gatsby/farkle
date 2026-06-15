package com.feltandbone.farkle.ui

import android.app.Application
import android.os.Handler
import android.os.Looper
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import com.feltandbone.farkle.data.AppSettings
import com.feltandbone.farkle.data.GameStore
import com.feltandbone.farkle.engine.GameEngine
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.model.HouseRules
import com.feltandbone.farkle.model.Player
import com.feltandbone.farkle.net.FarkleHost
import com.feltandbone.farkle.net.PlayerClaim

enum class Tab { HOME, HISTORY, STATS, RULES, SETTINGS }

sealed interface Screen {
    data object Tabs : Screen
    data object NewGame : Screen
    data object ActiveGame : Screen
    data class Recap(val gameId: String) : Screen
    data object Join : Screen
}

class AppViewModel(app: Application) : AndroidViewModel(app) {
    private val store = GameStore(app)

    var settings by mutableStateOf(store.loadSettings())
        private set
    var history by mutableStateOf(store.loadHistory())
        private set
    var activeGame by mutableStateOf(store.loadActiveGame())
        private set

    /** Carries a "this turn used all six dice" flag from the Score Helper to the next bank. */
    var pendingHotDice by mutableStateOf(false)
        private set

    fun markPendingHotDice() { pendingHotDice = true }

    // --- Live scoreboard hosting ---
    private val mainHandler = Handler(Looper.getMainLooper())
    private var host: FarkleHost? = null
    var roomCode by mutableStateOf<String?>(null)
        private set
    var viewerCount by mutableStateOf(0)
        private set

    fun startHostingIfNeeded() {
        if (host != null || activeGame == null) return
        val code = FarkleHost.randomRoomCode()
        roomCode = code
        val h = FarkleHost(
            getApplication(),
            roomCode = code,
            onClaim = { claim -> mainHandler.post { applyClaim(claim) } },
            onViewerCountChanged = { count -> mainHandler.post { viewerCount = count } },
        )
        host = h
        h.start()
        activeGame?.let { h.broadcast(it) }
    }

    fun stopHosting() {
        host?.stop()
        host = null
        roomCode = null
        viewerCount = 0
    }

    private fun applyClaim(claim: PlayerClaim) {
        val g = activeGame ?: return
        val players = g.players.map {
            if (it.id == claim.playerId) it.copy(photoBase64 = claim.photoBase64) else it
        }
        val next = g.copy(players = players)
        activeGame = next
        store.saveActiveGame(next)
        host?.broadcast(next)
    }

    var screen by mutableStateOf<Screen>(
        if (!store.loadSettings().seenOnboarding) Screen.Tabs else Screen.Tabs,
    )
        private set
    var tab by mutableStateOf(Tab.HOME)
        private set

    /** True until onboarding has been dismissed. */
    var showOnboarding by mutableStateOf(!settings.seenOnboarding)
        private set

    init {
        // If a game is in progress, land directly on it (parity with iOS restore behavior).
        if (activeGame?.isInProgress == true && !showOnboarding) {
            screen = Screen.ActiveGame
        }
    }

    // --- Navigation ---
    fun goTab(t: Tab) { tab = t; screen = Screen.Tabs }
    fun navigate(s: Screen) { screen = s }
    fun back() { screen = Screen.Tabs }

    fun dismissOnboarding() {
        showOnboarding = false
        settings = settings.copy(seenOnboarding = true)
        store.saveSettings(settings)
    }

    // --- Settings ---
    fun updateSettings(transform: (AppSettings) -> AppSettings) {
        settings = transform(settings)
        store.saveSettings(settings)
    }

    fun resetAllData() {
        store.resetAll()
        settings = AppSettings()
        history = emptyList()
        activeGame = null
        showOnboarding = true
        screen = Screen.Tabs
        tab = Tab.HOME
    }

    fun exportHistoryJson(): String = store.exportHistoryJson()

    // --- New game prefill (names + avatar colors of the most recent game) ---
    fun prefillPlayers(): List<Player> {
        val recent = (history.maxByOrNull { it.endedAt ?: it.createdAt })
        return recent?.orderedPlayers?.mapIndexed { idx, p ->
            Player(name = p.name, avatarIndex = p.avatarIndex, orderIndex = idx)
        } ?: listOf(
            Player(name = "", avatarIndex = 0, orderIndex = 0),
            Player(name = "", avatarIndex = 1, orderIndex = 1),
        )
    }

    fun startNewGame(names: List<String>, targetScore: Int, rules: HouseRules) {
        val players = names.mapIndexed { idx, n ->
            Player(name = n.trim().take(20), avatarIndex = idx, orderIndex = idx)
        }
        val game = Game.create(Game.generateName(), targetScore, rules, players)
        activeGame = game
        store.saveActiveGame(game)
        // Persist these as the new defaults for next time.
        settings = settings.copy(defaultTargetScore = targetScore, defaultRules = rules)
        store.saveSettings(settings)
        screen = Screen.ActiveGame
    }

    fun resume() {
        if (activeGame?.isInProgress == true) screen = Screen.ActiveGame
    }

    /** Leave the in-progress game (kept for resume) and return to Home. */
    fun leaveGame() {
        stopHosting()
        screen = Screen.Tabs
        tab = Tab.HOME
    }

    fun rematch() {
        val g = activeGame ?: return
        val players = g.orderedPlayers.mapIndexed { idx, p ->
            Player(name = p.name, avatarIndex = p.avatarIndex, orderIndex = idx)
        }
        val game = Game.create(Game.generateName(), g.targetScore, g.rules, players)
        activeGame = game
        store.saveActiveGame(game)
        screen = Screen.ActiveGame
    }

    fun finishGameOver() {
        // Game already archived to history when it ended; clear active and go home.
        stopHosting()
        activeGame = null
        store.clearActiveGame()
        screen = Screen.Tabs
        tab = Tab.HOME
    }

    // --- Engine mutations (auto-save + archive on end) ---
    private fun apply(transform: (Game) -> Game) {
        val current = activeGame ?: return
        val wasEnded = current.endedAt != null
        val next = transform(current)
        activeGame = next
        store.saveActiveGame(next)
        host?.broadcast(next)
        if (next.endedAt != null && !wasEnded) {
            store.upsertHistory(next)
            history = store.loadHistory()
        } else if (wasEnded && next.endedAt == null) {
            // Undo from game over — pull it back out of history.
            store.saveHistory(store.loadHistory().filterNot { it.id == next.id })
            history = store.loadHistory()
        } else if (next.endedAt != null) {
            store.upsertHistory(next)
            history = store.loadHistory()
        }
    }

    fun addToPending(amount: Int) = apply { GameEngine.addToPending(it, amount) }
    fun setPending(amount: Int) = apply { GameEngine.setPending(it, amount) }
    fun clearPending() { pendingHotDice = false; apply { GameEngine.clearPending(it) } }
    fun bank(hotDice: Boolean = pendingHotDice) {
        apply { GameEngine.bank(it, hotDice) }
        pendingHotDice = false
    }
    fun bust() { pendingHotDice = false; apply { GameEngine.bust(it) } }
    fun undoLast() = apply { GameEngine.undoLast(it) }
    fun undo(actionId: String) = apply { GameEngine.undo(it, actionId) }
    fun setActionAmount(actionId: String, amount: Int) = apply { GameEngine.setActionAmount(it, actionId, amount) }
    fun reorderPlayers(ids: List<String>) = apply { GameEngine.reorderPlayers(it, ids) }
    fun addPlayer(name: String) = apply { GameEngine.addPlayer(it, name) }
    fun renamePlayer(playerId: String, name: String) = apply { GameEngine.renamePlayer(it, playerId, name) }
    fun markFinalRoundAnnouncementShown() = apply { GameEngine.markFinalRoundAnnouncementShown(it) }
}
