package com.feltandbone.farkle.ui

import android.content.Intent
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.feltandbone.farkle.model.Game
import com.feltandbone.farkle.ui.components.Avatar
import com.feltandbone.farkle.ui.components.Caption
import com.feltandbone.farkle.ui.components.DisplayTitle
import com.feltandbone.farkle.ui.components.Eyebrow
import com.feltandbone.farkle.ui.components.Pill
import com.feltandbone.farkle.ui.components.SecondaryButton
import com.feltandbone.farkle.ui.components.grouped
import com.feltandbone.farkle.ui.screens.HistoryScreen
import com.feltandbone.farkle.ui.screens.HomeScreen
import com.feltandbone.farkle.ui.screens.NewGameScreen
import com.feltandbone.farkle.ui.screens.OnboardingScreen
import com.feltandbone.farkle.ui.screens.RulesScreen
import com.feltandbone.farkle.ui.screens.SettingsScreen
import com.feltandbone.farkle.ui.screens.StatsScreen
import com.feltandbone.farkle.ui.screens.ActiveGameScreen
import com.feltandbone.farkle.ui.screens.ScoreboardJoinScreen
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.Ink
import com.feltandbone.farkle.ui.theme.Ink3
import com.feltandbone.farkle.ui.theme.Paper
import com.feltandbone.farkle.ui.theme.PaperSurface
import com.feltandbone.farkle.ui.theme.PlexSans
import com.feltandbone.farkle.ui.theme.Walnut

@Composable
fun FarkleApp() {
    val vm: AppViewModel = viewModel()
    val context = LocalContext.current

    if (vm.showOnboarding) {
        OnboardingScreen(onStart = { vm.dismissOnboarding(); vm.navigate(Screen.NewGame) })
        return
    }

    // In-app back navigation (parity: Android back stays in the app).
    val backEnabled = vm.screen != Screen.Tabs || vm.tab != Tab.HOME
    BackHandler(enabled = backEnabled) {
        when (vm.screen) {
            Screen.Tabs -> vm.goTab(Tab.HOME)
            Screen.ActiveGame -> vm.leaveGame()
            else -> vm.back()
        }
    }

    when (val screen = vm.screen) {
        Screen.Tabs -> TabsScaffold(vm, context)
        Screen.NewGame -> NewGameScreen(
            initialPlayers = vm.prefillPlayers(),
            defaultTarget = vm.settings.defaultTargetScore,
            defaultRules = vm.settings.defaultRules,
            onCancel = { vm.back() },
            onStart = { names, target, rules -> vm.startNewGame(names, target, rules) },
            modifier = Modifier.fillMaxSize().background(Paper).statusBarsPadding(),
        )
        Screen.ActiveGame -> ActiveGameScreen(vm)
        is Screen.Recap -> RecapScreen(
            game = vm.history.firstOrNull { it.id == screen.gameId },
            onClose = { vm.back() },
        )
        Screen.Join -> ScoreboardJoinScreen(onClose = { vm.back() })
    }
}

@Composable
private fun TabsScaffold(vm: AppViewModel, context: android.content.Context) {
    Scaffold(
        containerColor = Paper,
        bottomBar = {
            NavigationBar(containerColor = PaperSurface) {
                tabItem(vm, Tab.HOME, "Home", Icons.Filled.Home)
                tabItem(vm, Tab.HISTORY, "History", Icons.Filled.History)
                tabItem(vm, Tab.STATS, "Stats", Icons.Filled.BarChart)
                tabItem(vm, Tab.RULES, "Rules", Icons.AutoMirrored.Filled.MenuBook)
                tabItem(vm, Tab.SETTINGS, "Settings", Icons.Filled.Settings)
            }
        },
    ) { padding ->
        Box(Modifier.padding(padding).fillMaxSize().background(Paper).statusBarsPadding()) {
            when (vm.tab) {
                Tab.HOME -> HomeScreen(
                    activeGame = vm.activeGame,
                    recentGames = vm.history,
                    onResume = { vm.resume() },
                    onNewGame = { vm.navigate(Screen.NewGame) },
                    onJoin = { vm.navigate(Screen.Join) },
                    onOpenRecap = { vm.navigate(Screen.Recap(it)) },
                )
                Tab.HISTORY -> HistoryScreen(
                    history = vm.history,
                    primaryPlayerName = vm.settings.primaryPlayerName,
                    onOpenRecap = { vm.navigate(Screen.Recap(it)) },
                )
                Tab.STATS -> StatsScreen(
                    history = vm.history,
                    primaryPlayerName = vm.settings.primaryPlayerName,
                    onSetPrimary = { name -> vm.updateSettings { it.copy(primaryPlayerName = name) } },
                )
                Tab.RULES -> RulesScreen(rules = vm.settings.defaultRules)
                Tab.SETTINGS -> SettingsScreen(
                    settings = vm.settings,
                    onUpdate = { transform -> vm.updateSettings(transform) },
                    onExport = {
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "application/json"
                            putExtra(Intent.EXTRA_TEXT, vm.exportHistoryJson())
                        }
                        context.startActivity(Intent.createChooser(intent, "Export game history"))
                    },
                    onReset = { vm.resetAllData() },
                )
            }
        }
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.tabItem(vm: AppViewModel, tab: Tab, label: String, icon: ImageVector) {
    NavigationBarItem(
        selected = vm.tab == tab,
        onClick = { vm.goTab(tab) },
        icon = { Icon(icon, contentDescription = label) },
        label = { Text(label, fontFamily = PlexSans, fontSize = 11.sp) },
        colors = NavigationBarItemDefaults.colors(
            selectedIconColor = Walnut,
            selectedTextColor = Walnut,
            indicatorColor = Gold.copy(alpha = 0.3f),
            unselectedIconColor = Ink3,
            unselectedTextColor = Ink3,
        ),
    )
}

@Composable
private fun RecapScreen(game: Game?, onClose: () -> Unit) {
    Column(
        Modifier.fillMaxSize().background(Paper).statusBarsPadding().verticalScroll(rememberScrollState()).padding(20.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            DisplayTitle("Recap", size = 30, modifier = Modifier.weight(1f))
            Text("Close", color = Ink3, fontFamily = PlexSans, modifier = Modifier.clickable(onClick = onClose).padding(8.dp))
        }
        if (game == null) {
            Spacer(Modifier.height(20.dp))
            Caption("Game not found.")
            return
        }
        Spacer(Modifier.height(8.dp))
        Eyebrow(game.name)
        Spacer(Modifier.height(12.dp))
        val ranked = game.orderedPlayers.sortedByDescending { it.bankedScore }
        ranked.forEachIndexed { idx, p ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(PaperSurface)
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (idx == 0) Pill("WINNER", background = Gold, foreground = Ink)
                else Text("${idx + 1}", color = Ink3, fontFamily = com.feltandbone.farkle.ui.theme.JetBrainsMono, modifier = Modifier.width(34.dp))
                Spacer(Modifier.width(10.dp))
                Avatar(p, size = 32.dp)
                Spacer(Modifier.width(10.dp))
                Text(p.name, color = Ink, fontFamily = PlexSans, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
                Text(p.bankedScore.grouped(), color = Ink, fontFamily = com.feltandbone.farkle.ui.theme.JetBrainsMono, fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.height(8.dp))
        }
    }
}
