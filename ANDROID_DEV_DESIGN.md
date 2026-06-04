# Farkle for Android — Dev Design

Implementation design for the Android counterpart to the iOS Farkle app. Functional
requirements live in `ANDROID_FUNCTIONAL_SPEC.md`; this document covers tech choices
and structure only.

## Toolchain
- **Language/UI:** Kotlin + Jetpack Compose (Material 3), the closest analog to SwiftUI.
- **Build:** Gradle 8.13, Android Gradle Plugin 8.9.1, Kotlin 2.1.0, Compose BOM 2024.12.01.
- **SDK:** `compileSdk`/`targetSdk` 35, `minSdk` 26 (Android 8.0). Phone-first.
- **Project root:** `android/` (the iOS app remains at the repo root).
- **Serialization:** kotlinx.serialization (JSON).
- **Networking:** `org.java-websocket` (server + client) for the live scoreboard transport;
  Android `NsdManager` for Bonjour/NSD discovery.

## Module layout (`android/app/src/main/java/com/feltandbone/farkle/`)
- `model/` — `Player`, `HouseRules`, `ActionLogEntry`/`ActionKind`, `Game` (immutable
  `@Serializable` data classes with computed properties; direct port of the Swift models).
- `engine/` — `GameEngine` (pure functions: `bank`/`bust`/`undo`/`reorder`/`addPlayer`/
  `setActionAmount`, plus log-replay `rebuildDerivedState`) and `ScoreHelperEngine`
  (house-rule-aware combo scoring). Engine functions take a `Game` and return a new `Game`,
  which suits Compose's snapshot state model and makes the logic trivially unit-testable.
- `data/` — `GameStore` (JSON file persistence in `filesDir`: active game, history,
  settings) and `AppSettings`. Chosen over Room to avoid KSP annotation processing for a
  small, document-shaped dataset; the whole game serializes cleanly.
- `net/` — `Protocol` (`Snapshot`/`PlayerClaim`/`Envelope`), `FarkleHost` (WebSocket server +
  NSD registration, broadcasts on every state change, merges photo claims), `FarkleClient`
  (NSD discovery + WebSocket client). The transport is platform-neutral so non-Apple
  joiners (Android, future web viewer) can connect.
- `ui/` — `AppViewModel` (single source of truth: state, navigation, engine/persistence/host
  wiring), `FarkleApp` (root nav + bottom tab scaffold + system-back handling), `WinCard`
  (1080×1920 share image via `android.graphics`, shared/saved via FileProvider/MediaStore),
  `ui/theme/` (colors, the three font families, Material theme), `ui/components/` (DieView,
  Avatar, buttons/chips, formatting), `ui/screens/` (all screens + sheets).

## State & navigation
- `AppViewModel : AndroidViewModel` holds Compose `mutableStateOf` for `settings`, `history`,
  `activeGame`, `screen`, `tab`. Every engine mutation runs through `apply { ... }`, which
  updates state, auto-saves, broadcasts to viewers, and archives to history on game end
  (and de-archives on undo-from-game-over).
- Navigation is a small sealed `Screen` (Tabs / NewGame / ActiveGame / Recap / Join) plus a
  `Tab` enum, switched in `FarkleApp`. A `BackHandler` keeps the Android system-back gesture
  inside the app (parity with iOS in-app back).
- `ActiveGameScreen` dispatches to the normal game, the felt `FinalRoundScreen`, or the
  `GameOverScreen` based on `Game` state.

## Live scoreboard
- Hosting auto-starts when the Active Game appears (`startHostingIfNeeded`), advertises
  `_farkle._tcp` via NSD with service name `Farkle-<roomCode>`, and shows the room code in the
  top-bar chip. WebSocket callbacks are marshalled back to the main thread via a `Handler`.
- The joiner discovers hosts, connects read-only, mirrors snapshots with an active-player
  highlight, picks a seat ("YOU" badge + "IT'S YOUR TURN" banner), and can send a photo claim.

## Testing
- 32 JUnit tests (`ScoringTest`, `GameFlowTest`) port the iOS XCTest suites 1:1 and pass.
- Manually verified on a Pixel 7 (API 35) emulator: onboarding, new game, active game
  (chips/keypad/score helper/bank confirm with preview math/must-open enforcement/standings/
  recent actions), turn advancement, final round (announcement + felt play screen), game over
  (winner archived to history), persistence + resume, and in-app back. The host side of the
  live scoreboard was confirmed to bind a WebSocket and register over NSD on-device; full
  two-device join testing requires a second device on the same LAN (a single NAT'd emulator
  can't exercise cross-device mDNS).

## Change log
- 2026-06-03 — Initial Android implementation on `feature/android-app`. Full game model +
  engine ported with 32 passing unit tests; all screens built to parity; JSON persistence;
  WinCard share/save; live-scoreboard host (WebSocket + NSD) verified on-device; joiner +
  read-only scoreboard implemented.
