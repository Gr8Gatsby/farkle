package com.feltandbone.farkle.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val FarkleColors = lightColorScheme(
    primary = Walnut,
    onPrimary = WalnutInk,
    secondary = Felt,
    onSecondary = WalnutInk,
    tertiary = Gold,
    background = Paper,
    onBackground = Ink,
    surface = PaperSurface,
    onSurface = Ink,
    error = Crimson,
    onError = WalnutInk,
)

@Composable
fun FarkleTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    // Paper theme is the v1 default on both platforms; ignore system dark mode.
    MaterialTheme(
        colorScheme = FarkleColors,
        typography = AppTypography,
        content = content,
    )
}
