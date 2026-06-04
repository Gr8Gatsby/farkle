package com.feltandbone.farkle.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.toMutableStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.model.HouseRules
import com.feltandbone.farkle.model.Player
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.DisplayTitle
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.PrimaryButton
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.AvatarPalette
import com.feltandbone.farkle.ui.theme.Felt
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.Paper2
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut
import com.feltandbone.farkle.ui.theme.WalnutInk

private data class Seat(val name: String, val avatarIndex: Int)

@Composable
fun NewGameScreen(
    initialPlayers: List<Player>,
    defaultTarget: Int,
    defaultRules: HouseRules,
    onCancel: () -> Unit,
    onStart: (names: List<String>, target: Int, rules: HouseRules) -> Unit,
    modifier: Modifier = Modifier,
) {
    val seats = remember {
        initialPlayers.map { Seat(it.name, it.avatarIndex) }
            .ifEmpty { listOf(Seat("", 0), Seat("", 1)) }
            .toMutableStateList()
    }
    var target by remember { mutableIntStateOf(defaultTarget) }
    var rules by remember { mutableStateOf(defaultRules) }
    var customTarget by remember { mutableStateOf("") }

    val validNames = seats.map { it.name.trim() }.filter { it.isNotEmpty() }
    val canStart = validNames.size >= 2

    Column(
        modifier = modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            DisplayTitle("New game", size = 32, modifier = Modifier.weight(1f))
            Text(
                "Cancel",
                color = Ink3,
                fontFamily = PlexSans,
                modifier = Modifier.clickable { onCancel() }.padding(8.dp),
            )
        }
        Spacer(Modifier.height(16.dp))

        Eyebrow("Players")
        Spacer(Modifier.height(8.dp))
        seats.forEachIndexed { idx, seat ->
            PlayerRow(
                seat = seat,
                showDelete = seats.size > 1,
                onName = { seats[idx] = seat.copy(name = it.take(20)) },
                onDelete = { if (seats.size > 1) seats.removeAt(idx) },
            )
            Spacer(Modifier.height(8.dp))
        }
        if (seats.size < 8) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(Paper2)
                    .clickable { seats.add(Seat("", seats.size)) }
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.Add, contentDescription = "Add player", tint = Walnut)
                Spacer(Modifier.width(8.dp))
                Text("Add player", color = Walnut, fontFamily = PlexSans, fontWeight = FontWeight.Medium)
            }
        }

        Spacer(Modifier.height(24.dp))
        Eyebrow("Target score")
        Spacer(Modifier.height(8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf(5000, 10000, 15000).forEach { v ->
                TargetChip(v.grouped(), selected = target == v, modifier = Modifier.weight(1f)) {
                    target = v; customTarget = ""
                }
            }
        }
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = customTarget,
            onValueChange = { s ->
                customTarget = s.filter { it.isDigit() }.take(5)
                customTarget.toIntOrNull()?.let { if (it in 1000..50000) target = it }
            },
            label = { Text("Custom (1,000–50,000)") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
            modifier = Modifier.fillMaxWidth(),
        )

        Spacer(Modifier.height(24.dp))
        Eyebrow("House rules")
        Spacer(Modifier.height(8.dp))
        RuleSwitch("Three pairs = 1,500", rules.threePair) { rules = rules.copy(threePair = it) }
        RuleSwitch("Straight 1–6 = 1,500", rules.straight) { rules = rules.copy(straight = it) }
        RuleSwitch("Two triplets = 2,500", rules.twoTriples) { rules = rules.copy(twoTriples = it) }
        RuleSwitch("4 of a kind w/ pair = 1,500", rules.fourOfAKindWithPair) {
            rules = rules.copy(fourOfAKindWithPair = it)
        }
        RuleSwitch("Must open with 500", rules.mustOpenWith != null) {
            rules = rules.copy(mustOpenWith = if (it) 500 else null)
        }

        Spacer(Modifier.height(24.dp))
        PrimaryButton(
            label = "Pass the dice →",
            enabled = canStart,
            subtext = if (canStart) null else "Add at least 2 player names",
        ) {
            onStart(validNames, target, rules)
        }
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun PlayerRow(seat: Seat, showDelete: Boolean, onName: (String) -> Unit, onDelete: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        val (bg, fg) = AvatarPalette.colors(seat.avatarIndex)
        Box(
            modifier = Modifier.size(40.dp).clip(CircleShape).background(bg),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                seat.name.trim().firstOrNull()?.uppercaseChar()?.toString() ?: "?",
                color = fg, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold,
            )
        }
        Spacer(Modifier.width(10.dp))
        OutlinedTextField(
            value = seat.name,
            onValueChange = onName,
            placeholder = { Text("Player name") },
            singleLine = true,
            modifier = Modifier.weight(1f),
        )
        if (showDelete) {
            Spacer(Modifier.width(6.dp))
            Icon(
                Icons.Filled.Close,
                contentDescription = "Remove player",
                tint = Ink3,
                modifier = Modifier.clickable { onDelete() }.padding(6.dp),
            )
        }
    }
}

@Composable
private fun TargetChip(label: String, selected: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(if (selected) Walnut else Paper2)
            .clickable { onClick() }
            .padding(vertical = 14.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            color = if (selected) WalnutInk else Ink,
            fontFamily = PlexSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 15.sp,
        )
    }
}

@Composable
private fun RuleSwitch(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(PaperSurface)
            .padding(horizontal = 14.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, color = Ink, fontFamily = PlexSans, modifier = Modifier.weight(1f))
        Switch(
            checked = checked,
            onCheckedChange = onChange,
            colors = SwitchDefaults.colors(checkedThumbColor = WalnutInk, checkedTrackColor = Felt),
        )
    }
    Spacer(Modifier.height(6.dp))
}
