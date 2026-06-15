package com.feltandbone.farkle.ui.theme

import androidx.compose.ui.graphics.Color

// Paper / ink
val Paper = Color(0xFFF3EDE0)
val Paper2 = Color(0xFFEBE3D2)
val PaperSurface = Color(0xFFFBF7EB)
val Ink = Color(0xFF2A2520)
val Ink2 = Color(0xFF5A4F42)
val Ink3 = Color(0xFF8A8071)

// Walnut
val Walnut = Color(0xFF5B3A1F)
val WalnutInk = Color(0xFFF7EFDE)
val WalnutShadow = Color(0xFF2C1808)

// Felt
val Felt = Color(0xFF2D5A47)
val FeltDeep = Color(0xFF1F4332)

// Accents
val Crimson = Color(0xFFA8341A)
val Gold = Color(0xFFB88A3E)
val Gold2 = Color(0xFFD4A85A)

// Bone (dice)
val Bone = Color(0xFFFAF6EE)
val BonePip = Color(0xFF1A120A)

/** Deterministic avatar (background, foreground) pairs — parity with iOS AvatarPalette. */
object AvatarPalette {
    val pairs: List<Pair<Color, Color>> = listOf(
        Color(0xFFA8341A) to Color(0xFFFBE5DD),
        Color(0xFF2D5A47) to Color(0xFFDDE8E2),
        Color(0xFF5B3A1F) to Color(0xFFEBD9C0),
        Color(0xFFB88A3E) to Color(0xFFF3E6C9),
        Color(0xFF4A5B8A) to Color(0xFFDEE2EE),
        Color(0xFF6E3D6B) to Color(0xFFE9DDE7),
        Color(0xFF3A6B5B) to Color(0xFFDCEAE4),
        Color(0xFF8B4A3A) to Color(0xFFECD9D2),
    )

    fun colors(index: Int): Pair<Color, Color> {
        val n = pairs.size
        return pairs[((index % n) + n) % n]
    }
}
