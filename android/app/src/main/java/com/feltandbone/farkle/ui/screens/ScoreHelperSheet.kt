package com.feltandbone.farkle.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.model.HouseRules
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.DieView
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.PrimaryButton
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper2
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.Walnut

private data class HelperRow(val label: String, val points: Int, val dice: Int, val face: Int)

@Composable
fun ScoreHelperSheet(
    rules: HouseRules,
    onClear: () -> Unit = {},
    modifier: Modifier = Modifier,
    onAdd: (total: Int, usesAllDice: Boolean) -> Unit,
) {
    var total by remember { mutableIntStateOf(0) }
    var diceUsed by remember { mutableIntStateOf(0) }

    fun tally(r: HelperRow) {
        total += r.points
        diceUsed += r.dice
    }

    val singles = listOf(
        HelperRow("Single 1", 100, 1, 1),
        HelperRow("Single 5", 50, 1, 5),
    )
    val threes = (1..6).map { f ->
        HelperRow("Three ${f}s", if (f == 1) 300 else f * 100, 3, f)
    }
    val multis = listOf(
        HelperRow("Four of a kind", 1000, 4, 4),
        HelperRow("Five of a kind", 2000, 5, 5),
        HelperRow("Six of a kind", 3000, 6, 6),
    )
    val specials = buildList {
        if (rules.straight) add(HelperRow("Straight 1–6", 1500, 6, 3))
        if (rules.threePair) add(HelperRow("Three pairs", 1500, 6, 2))
        if (rules.twoTriples) add(HelperRow("Two triplets", 2500, 6, 3))
        if (rules.fourOfAKindWithPair) add(HelperRow("4 of a kind w/ pair", 1500, 6, 4))
    }

    Column(modifier = modifier.fillMaxWidth().padding(horizontal = 20.dp)) {
        Eyebrow("Score helper")
        Spacer(Modifier.height(4.dp))
        Caption("Tap each combo you rolled. The phone won't read the dice for you.")
        Spacer(Modifier.height(12.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(max = 360.dp)
                .verticalScroll(rememberScrollState()),
        ) {
            Section("Singles", singles, ::tally)
            Section("Three of a kind", threes, ::tally)
            Section("Four / five / six", multis, ::tally)
            if (specials.isNotEmpty()) Section("Special combos", specials, ::tally)
        }

        Spacer(Modifier.height(12.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (diceUsed >= 6) {
                Row(
                    modifier = Modifier.clip(CircleShape).background(Gold).padding(horizontal = 8.dp, vertical = 3.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.LocalFireDepartment, null, tint = Ink, modifier = Modifier.size(12.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("HOT DICE", color = Ink, fontFamily = JetBrainsMono, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                }
                Spacer(Modifier.width(8.dp))
            }
            Text(
                "Running total: ${total.grouped()}",
                color = Ink,
                fontFamily = JetBrainsMono,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f),
            )
            Text(
                "Clear",
                color = Ink3,
                modifier = Modifier
                    .clickable { total = 0; diceUsed = 0; onClear() }
                    .padding(8.dp),
            )
        }
        Spacer(Modifier.height(8.dp))
        PrimaryButton(label = "Add +${total.grouped()} to turn", enabled = total > 0) {
            onAdd(total, diceUsed >= 6)
        }
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun Section(title: String, rows: List<HelperRow>, onAdd: (HelperRow) -> Unit) {
    Eyebrow(title, modifier = Modifier.padding(top = 10.dp, bottom = 4.dp))
    rows.forEach { r ->
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(PaperSurface)
                .clickable { onAdd(r) }
                .padding(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            DieView(r.face, size = 24.dp)
            Spacer(Modifier.width(10.dp))
            Text(r.label, color = Ink, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
            Text(r.points.grouped(), color = Walnut, fontFamily = JetBrainsMono, fontWeight = FontWeight.Bold)
            Spacer(Modifier.width(10.dp))
            Box(Modifier.clip(CircleShape).background(Paper2).padding(4.dp)) {
                Icon(Icons.Filled.Add, contentDescription = "Add", tint = Walnut, modifier = Modifier.width(18.dp))
            }
        }
        Spacer(Modifier.height(6.dp))
    }
}
