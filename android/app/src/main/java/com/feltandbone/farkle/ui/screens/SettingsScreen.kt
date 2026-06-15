package com.feltandbone.farkle.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.feltandbone.farkle.data.AppSettings
import com.feltandbone.farkle.ui.components.DisplayTitle
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.SecondaryButton
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.theme.Bone
import com.feltandbone.farkle.ui.theme.Crimson
import com.feltandbone.farkle.ui.theme.Felt
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink2
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.JetBrainsMono
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.Paper2
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut
import com.feltandbone.farkle.ui.theme.WalnutInk

@Composable
fun SettingsScreen(
    settings: AppSettings,
    onUpdate: ((AppSettings) -> AppSettings) -> Unit,
    onExport: () -> Unit,
    onReset: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var showResetDialog by remember { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Paper)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        DisplayTitle(text = "Settings")

        PaperCard {
            Eyebrow("Game feel")
            Spacer(Modifier.size(4.dp))
            SettingRow(
                label = "Dice sound",
                checked = settings.soundEnabled,
                onToggle = { onUpdate { it.copy(soundEnabled = !it.soundEnabled) } },
            )
            HorizontalDivider(color = Paper2)
            SettingRow(
                label = "Haptics",
                checked = settings.hapticsEnabled,
                onToggle = { onUpdate { it.copy(hapticsEnabled = !it.hapticsEnabled) } },
            )
        }

        PaperCard {
            Eyebrow("Default rules")
            Spacer(Modifier.size(4.dp))

            Text(
                text = "Target score",
                color = Ink,
                fontFamily = PlexSans,
                fontWeight = FontWeight.Medium,
                fontSize = 16.sp,
            )
            Text(
                text = settings.defaultTargetScore.grouped(),
                color = Ink3,
                fontFamily = JetBrainsMono,
                fontSize = 14.sp,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(5000, 10000, 15000).forEach { value ->
                    TargetChip(
                        label = value.grouped(),
                        selected = settings.defaultTargetScore == value,
                        modifier = Modifier.weight(1f),
                        onClick = { onUpdate { it.copy(defaultTargetScore = value) } },
                    )
                }
            }

            HorizontalDivider(color = Paper2)

            SettingRow(
                label = "Three pairs = 1,500",
                checked = settings.defaultRules.threePair,
                onToggle = {
                    onUpdate {
                        it.copy(defaultRules = it.defaultRules.copy(threePair = !it.defaultRules.threePair))
                    }
                },
            )
            SettingRow(
                label = "Straight 1–6 = 1,500",
                checked = settings.defaultRules.straight,
                onToggle = {
                    onUpdate {
                        it.copy(defaultRules = it.defaultRules.copy(straight = !it.defaultRules.straight))
                    }
                },
            )
            SettingRow(
                label = "Two triplets = 2,500",
                checked = settings.defaultRules.twoTriples,
                onToggle = {
                    onUpdate {
                        it.copy(defaultRules = it.defaultRules.copy(twoTriples = !it.defaultRules.twoTriples))
                    }
                },
            )
            SettingRow(
                label = "4 of a kind w/ pair = 1,500",
                checked = settings.defaultRules.fourOfAKindWithPair,
                onToggle = {
                    onUpdate {
                        it.copy(
                            defaultRules = it.defaultRules.copy(
                                fourOfAKindWithPair = !it.defaultRules.fourOfAKindWithPair,
                            ),
                        )
                    }
                },
            )
            SettingRow(
                label = "Must open with 500",
                checked = settings.defaultRules.mustOpenWith != null,
                onToggle = {
                    onUpdate {
                        it.copy(
                            defaultRules = it.defaultRules.copy(
                                mustOpenWith = if (it.defaultRules.mustOpenWith == null) 500 else null,
                            ),
                        )
                    }
                },
            )
        }

        PaperCard {
            Eyebrow("Data")
            Spacer(Modifier.size(4.dp))
            SecondaryButton(label = "Export game history", onClick = onExport)
            SecondaryButton(
                label = "Reset all data",
                color = Crimson,
                onClick = { showResetDialog = true },
            )
        }

        Text(
            text = "FARKLE · made with care · No ads. Not now, not ever.",
            color = Ink3,
            fontFamily = JetBrainsMono,
            fontSize = 11.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
        )
    }

    if (showResetDialog) {
        AlertDialog(
            onDismissRequest = { showResetDialog = false },
            title = { Text("Reset all data?", fontFamily = PlexSans, color = Ink) },
            text = {
                Text(
                    "This permanently deletes your game history and settings. This cannot be undone.",
                    fontFamily = PlexSans,
                    color = Ink2,
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    showResetDialog = false
                    onReset()
                }) {
                    Text("Reset", color = Crimson, fontFamily = PlexSans, fontWeight = FontWeight.SemiBold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetDialog = false }) {
                    Text("Cancel", color = Ink2, fontFamily = PlexSans)
                }
            },
            containerColor = PaperSurface,
        )
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
private fun SettingRow(label: String, checked: Boolean, onToggle: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            color = Ink,
            fontFamily = PlexSans,
            fontSize = 16.sp,
            modifier = Modifier.weight(1f),
        )
        Spacer(Modifier.width(8.dp))
        Switch(
            checked = checked,
            onCheckedChange = { onToggle() },
            colors = SwitchDefaults.colors(
                checkedThumbColor = Bone,
                checkedTrackColor = Felt,
                uncheckedThumbColor = Bone,
                uncheckedTrackColor = Paper2,
            ),
        )
    }
}

@Composable
private fun TargetChip(
    label: String,
    selected: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val bg = if (selected) Walnut else Paper2
    val fg = if (selected) WalnutInk else Ink
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(bg)
            .clickable { onClick() }
            .padding(vertical = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            color = fg,
            fontFamily = JetBrainsMono,
            fontWeight = FontWeight.Medium,
            fontSize = 14.sp,
        )
    }
}
