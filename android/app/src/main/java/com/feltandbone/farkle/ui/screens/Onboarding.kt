package com.feltandbone.farkle.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.ui.components.PrimaryButton
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink2
import com.feltandbone.farkle.ui.theme.InstrumentSerif
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut

@Composable
fun OnboardingScreen(onStart: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .systemBarsPadding()
            .padding(28.dp),
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.Start,
        ) {
            Text(
                "Roll, hold,",
                color = Ink,
                fontFamily = InstrumentSerif,
                fontSize = 52.sp,
            )
            Text(
                "repeat.",
                color = Walnut,
                fontFamily = InstrumentSerif,
                fontStyle = FontStyle.Italic,
                fontSize = 52.sp,
            )
            Text(
                "A warm, ad-free way to keep score in your physical Farkle games. The phone tracks the numbers — the dice stay on the table.",
                color = Ink2,
                fontFamily = PlexSans,
                fontSize = 17.sp,
                textAlign = TextAlign.Start,
                modifier = Modifier.padding(top = 20.dp),
            )
        }
        PrimaryButton(
            label = "Start a game",
            modifier = Modifier.align(Alignment.BottomCenter),
            onClick = onStart,
        )
    }
}
