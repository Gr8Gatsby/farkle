package com.feltandbone.farkle.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.model.HouseRules
import com.feltandbone.farkle.ui.components.DieView
import com.feltandbone.farkle.ui.components.DisplayTitle
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink2
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut

@Composable
fun RulesScreen(rules: HouseRules = HouseRules.DEFAULT, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Paper)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        DisplayTitle(text = "How it works")

        PaperCard {
            NumberedStep(1, "Roll the dice on the table. The app never rolls for you.")
            NumberedStep(2, "Set aside scoring dice and keep rolling, or bank what you've got.")
            NumberedStep(
                3,
                "Farkle (no scoring dice) loses the turn. First past the target triggers the final round.",
            )
        }

        PaperCard {
            Eyebrow("Score chart")
            Spacer(Modifier.size(4.dp))
            ScoreRow(face = 1, name = "Single 1", value = "100")
            ScoreRow(face = 5, name = "Single 5", value = "50")
            ScoreRow(face = 1, name = "Three 1s", value = "300")
            ScoreRow(face = 2, name = "Three 2s", value = "200")
            ScoreRow(face = 6, name = "Three 6s", value = "600")
            ScoreRow(face = 3, name = "Three of a kind (N≥2)", value = "N × 100")
            ScoreRow(face = 4, name = "Four of a kind", value = "1,000")
            ScoreRow(face = 4, name = "Five of a kind", value = "2,000")
            ScoreRow(face = 4, name = "Six of a kind", value = "3,000")
        }

        val hasSpecials = rules.straight || rules.threePair || rules.twoTriples ||
            rules.fourOfAKindWithPair || rules.mustOpenWith != null
        if (hasSpecials) {
            PaperCard {
                Eyebrow("Special combos (house rules)")
                Spacer(Modifier.size(4.dp))
                if (rules.straight) ScoreRow(face = 6, name = "Straight 1–6", value = "1,500")
                if (rules.threePair) ScoreRow(face = 2, name = "Three pairs", value = "1,500")
                if (rules.twoTriples) ScoreRow(face = 3, name = "Two triplets", value = "2,500")
                if (rules.fourOfAKindWithPair) {
                    ScoreRow(face = 4, name = "4 of a kind w/ pair", value = "1,500")
                }
                rules.mustOpenWith?.let {
                    ScoreRow(face = 5, name = "Must open with $it", value = "")
                }
            }
        }
    }
}

@Composable
private fun PaperCard(content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(PaperSurface)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        content()
    }
}

@Composable
private fun NumberedStep(index: Int, text: String) {
    Row(verticalAlignment = Alignment.Top) {
        Text(
            text = "$index.",
            color = Walnut,
            fontFamily = JetBrainsMono,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            modifier = Modifier.width(24.dp),
        )
        Text(
            text = text,
            color = Ink2,
            fontFamily = PlexSans,
            fontSize = 15.sp,
        )
    }
}

@Composable
private fun ScoreRow(face: Int, name: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        DieView(value = face, size = 24.dp)
        Spacer(Modifier.width(12.dp))
        Text(
            text = name,
            color = Ink,
            fontFamily = PlexSans,
            fontSize = 15.sp,
            modifier = Modifier.weight(1f),
        )
        if (value.isNotEmpty()) {
            Spacer(Modifier.width(8.dp))
            Text(
                text = value,
                color = Ink3,
                fontFamily = JetBrainsMono,
                fontWeight = FontWeight.Medium,
                fontSize = 15.sp,
            )
        }
    }
}
