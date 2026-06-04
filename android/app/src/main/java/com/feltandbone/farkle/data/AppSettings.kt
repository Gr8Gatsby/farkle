package com.feltandbone.farkle.data

import com.feltandbone.farkle.model.HouseRules
import kotlinx.serialization.Serializable

/** Persisted app-wide preferences — parity with iOS Settings + DefaultsMigrator. */
@Serializable
data class AppSettings(
    val seenOnboarding: Boolean = false,
    val defaultTargetScore: Int = 10000,
    val defaultRules: HouseRules = HouseRules.DEFAULT,
    val primaryPlayerName: String? = null,
    val soundEnabled: Boolean = true,
    val hapticsEnabled: Boolean = true,
)
