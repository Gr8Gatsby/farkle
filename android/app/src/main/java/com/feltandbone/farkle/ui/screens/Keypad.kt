package com.feltandbone.farkle.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.PrimaryButton
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper2
import com.feltandbone.farkle.ui.theme.PaperSurface

/** Numeric keypad for entering an arbitrary turn value. */
@Composable
fun NumberKeypad(
    title: String,
    confirmLabel: String,
    initial: Int = 0,
    modifier: Modifier = Modifier,
    onConfirm: (Int) -> Unit,
) {
    var entry by remember { mutableStateOf(if (initial > 0) initial.toString() else "") }
    val value = entry.toIntOrNull() ?: 0

    Column(modifier = modifier.fillMaxWidth().padding(20.dp)) {
        Caption(title)
        Spacer(Modifier.height(8.dp))
        Text(
            value.grouped(),
            color = Ink,
            fontFamily = JetBrainsMono,
            fontWeight = FontWeight.Bold,
            fontSize = 44.sp,
        )
        Spacer(Modifier.height(16.dp))
        val rows = listOf(
            listOf("1", "2", "3"),
            listOf("4", "5", "6"),
            listOf("7", "8", "9"),
            listOf("00", "0", "⌫"),
        )
        rows.forEach { row ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                row.forEach { key ->
                    Key(key, Modifier.weight(1f)) {
                        entry = when (key) {
                            "⌫" -> entry.dropLast(1)
                            else -> (entry + key).take(6)
                        }
                    }
                }
            }
            Spacer(Modifier.height(10.dp))
        }
        Spacer(Modifier.height(8.dp))
        PrimaryButton(label = confirmLabel, enabled = value > 0) { onConfirm(value) }
    }
}

@Composable
private fun Key(label: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Box(
        modifier = modifier
            .aspectRatio(1.6f)
            .clip(RoundedCornerShape(12.dp))
            .background(if (label == "⌫") Paper2 else PaperSurface)
            .clickable { onClick() },
        contentAlignment = Alignment.Center,
    ) {
        Text(label, color = Ink, fontFamily = JetBrainsMono, fontWeight = FontWeight.Medium, fontSize = 22.sp)
    }
}
