package com.feltandbone.farkle.data

import android.content.Context
import com.feltandbone.farkle.model.Game
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File

/**
 * File-based persistence. The active game is auto-saved after every action; completed
 * games live in history indefinitely until the user clears data. All data stays on-device.
 */
class GameStore(context: Context) {

    private val dir: File = context.filesDir
    private val activeFile = File(dir, "active_game.json")
    private val historyFile = File(dir, "history.json")
    private val settingsFile = File(dir, "settings.json")

    private val json = Json {
        ignoreUnknownKeys = true
        prettyPrint = true
        encodeDefaults = true
    }

    // --- Active game ---

    fun loadActiveGame(): Game? = runCatching {
        if (!activeFile.exists()) return null
        json.decodeFromString<Game>(activeFile.readText())
    }.getOrNull()

    fun saveActiveGame(game: Game) {
        runCatching { activeFile.writeText(json.encodeToString(game)) }
    }

    fun clearActiveGame() {
        runCatching { if (activeFile.exists()) activeFile.delete() }
    }

    // --- History ---

    fun loadHistory(): List<Game> = runCatching {
        if (!historyFile.exists()) return emptyList()
        json.decodeFromString<List<Game>>(historyFile.readText())
    }.getOrDefault(emptyList())

    fun saveHistory(games: List<Game>) {
        runCatching { historyFile.writeText(json.encodeToString(games)) }
    }

    /** Insert/replace a completed game (most-recent first). */
    fun upsertHistory(game: Game) {
        val list = loadHistory().filterNot { it.id == game.id }
        saveHistory((listOf(game) + list).sortedByDescending { it.endedAt ?: it.createdAt })
    }

    fun exportHistoryJson(): String = json.encodeToString(loadHistory())

    // --- Settings ---

    fun loadSettings(): AppSettings = runCatching {
        if (!settingsFile.exists()) return AppSettings()
        json.decodeFromString<AppSettings>(settingsFile.readText())
    }.getOrDefault(AppSettings())

    fun saveSettings(settings: AppSettings) {
        runCatching { settingsFile.writeText(json.encodeToString(settings)) }
    }

    // --- Reset ---

    fun resetAll() {
        clearActiveGame()
        runCatching { if (historyFile.exists()) historyFile.delete() }
        runCatching { if (settingsFile.exists()) settingsFile.delete() }
    }
}
