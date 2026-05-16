# Farkle — Dev Design

Implementation companion to [FUNCTIONAL_SPEC.md](FUNCTIONAL_SPEC.md). This document is implementation-only; functional rules live in the spec.

## 1. Stack

- **Language:** Swift 5.10+
- **UI:** SwiftUI, iOS 17+ minimum deployment target
- **Persistence:** SwiftData (Game, Turn, ActionLogEntry, Settings models)
- **Observation:** `@Observable` macro (iOS 17 Observation framework)
- **Animation:** SwiftUI implicit + `withAnimation`; Lottie not used
- **Testing:** XCTest for game-logic units; Swift Testing if available
- **Lint:** SwiftLint with a minimal config checked into repo

## 2. Repository layout

```
farkle/
  Farkle.xcodeproj
  Farkle/
    App/
      FarkleApp.swift                 // @main + scene + ModelContainer wiring
      RootView.swift                  // routes onboarding / home
    DesignSystem/
      Theme.swift                     // colors, typography
      Fonts.swift                     // font registration
      PaperBackground.swift           // paper-grain modifier
      FeltBackground.swift            // felt-table modifier (future)
      Buttons.swift                   // WalnutButton, ChipButton
      DieView.swift                   // bone die with pips
      AvatarView.swift                // initial-circle avatar
      BigScoreText.swift              // tabular display number
      Confetti.swift                  // particle overlay
    Models/
      Player.swift
      HouseRules.swift
      Game.swift
      Turn.swift
      ActionLog.swift                 // ActionLogEntry + Undo
      ScoreHelperEngine.swift         // combo detection
      Persistence.swift               // SwiftData ModelContainer factory
    Features/
      Onboarding/OnboardingView.swift
      Home/HomeView.swift
      NewGame/NewGameView.swift
      ActiveGame/
        ActiveGameView.swift
        NowRollingBanner.swift
        PendingTurnCard.swift
        StandingsLadder.swift
        RecentActionsLog.swift
        BankConfirmSheet.swift
        ScoreHelperSheet.swift
        KeypadSheet.swift
      GameOver/GameOverView.swift
      History/HistoryView.swift
      Stats/StatsView.swift
      Settings/SettingsView.swift
      Rules/RulesView.swift
    Resources/
      Fonts/                          // .ttf files bundled
      Assets.xcassets                 // colors, app icon
  FarkleTests/
    ScoringTests.swift
    GameFlowTests.swift
    UndoTests.swift
  README.md
  FUNCTIONAL_SPEC.md
  DEV_DESIGN.md
```

## 3. Data model

### 3.1 SwiftData entities

```swift
@Model final class Game {
    @Attribute(.unique) var id: UUID
    var name: String                // auto-generated "Tuesday Night Roll"
    var createdAt: Date
    var endedAt: Date?
    var targetScore: Int
    var rules: HouseRules           // value-type, codable, stored as JSON
    @Relationship(deleteRule: .cascade) var players: [Player]
    @Relationship(deleteRule: .cascade) var actions: [ActionLogEntry]  // ordered
    var activePlayerIndex: Int
    var pendingTurnScore: Int       // dice-not-banked-yet
    var pendingRollCount: Int
    var finalRoundTriggeredBy: UUID?  // player id; nil until target hit
    var finalRoundTurnsRemaining: Int
}

@Model final class Player {
    @Attribute(.unique) var id: UUID
    var name: String
    var avatarIndex: Int            // 0..7 maps to AVATAR_COLORS
    var orderIndex: Int             // turn order in this game
    var bankedScore: Int            // derived but cached for perf
}

@Model final class ActionLogEntry {
    @Attribute(.unique) var id: UUID
    var game: Game?
    var playerId: UUID
    var kind: ActionKind            // .bank, .bust, .startFinalRound, .endGame
    var amount: Int                 // 0 for bust
    var timestamp: Date
    var orderIndex: Int             // monotonic per game
    var roundNumber: Int
    var hotDice: Bool               // marked at bank time
}

enum ActionKind: String, Codable {
    case bank, bust, startFinalRound, endGame
}

struct HouseRules: Codable, Equatable {
    var threePair: Bool = true
    var straight: Bool = true
    var twoTriples: Bool = false
    var mustOpenWith: Int? = 500    // nil = no minimum
}
```

### 3.2 In-memory state vs. persisted state
- All authoritative state lives in SwiftData. `ActiveGameViewModel` reads/writes via `ModelContext`.
- Auto-save: SwiftData persists on every mutation; we explicitly call `try context.save()` after each action to make persistence visible across launches.

### 3.3 Banked score recomputation
- `Player.bankedScore` is derived (sum of action amounts for kind == .bank for that player). We cache it on the Player for fast standings render, recomputed any time the action log mutates. Undo recomputes by reversing.

## 4. Undo system

### 4.1 Mechanism
- Single source of truth: the ordered `ActionLogEntry` array on `Game`.
- "Apply action": appends to log, mutates derived state (banked totals, active-player index, pending turn).
- "Undo last action": pops latest log entry, reverses derived state.
- Specific-action undo (from Recent Actions row): pops the log back to before that entry; everything after it is replayed onto a fresh derived state in O(n). Cheaper than per-action inverse because we get correctness for free.

### 4.2 Edge cases
- Undoing a `.bust` restores the turn's `pendingTurnScore` to what it was at bust-time. We snapshot pending state inside the log entry's metadata when busting.
- Undoing a `.bank` rewinds `activePlayerIndex` and restores `pendingTurnScore` similarly.
- Undoing `.startFinalRound` clears the trigger and resets `finalRoundTurnsRemaining`.
- Undoing `.endGame` from the "Wait — that's wrong" button on Game Over is equivalent to undoing the most recent bank that triggered it; the game returns to active state, ready for the same player to roll again.

### 4.3 Logging cost
- Active games rarely exceed ~100 log entries (avg game ≈ 4 players × 15 turns). Full replay is trivial and avoids inverse-action bugs.

## 5. Score helper engine

Pure value-type engine, fully unit-tested.

```swift
struct ScoreHelperEngine {
    let rules: HouseRules
    func score(dice: [Int]) -> ScoreBreakdown
}

struct ScoreBreakdown {
    let combos: [Combo]   // [(name: "Three 5s", points: 500)]
    let total: Int
    let usesAllDice: Bool // for Hot Dice marking
}
```

Rules implemented:
- Single 1 = 100, single 5 = 50.
- Three of a kind = face × 100 (three 1s = 1,000).
- Four-of-a-kind = 2× the three-of-a-kind value; five = 4×; six = 8×.
- Straight 1–6 = 1,500 (off if rule disabled).
- Three pairs = 1,500 (off if rule disabled).
- Two triples = 2,500 (off if rule disabled).
- Greedy partition: prefer highest-scoring combo first (six > five > four > three > pairs > singles).

## 6. Design system implementation

### 6.1 Colors (`Theme.swift`)
Hard-coded `Color` extensions mapped to the Felt & Bone palette. Defined for both light only (v1 has no dark mode — paper is the brand).

### 6.2 Typography
- Bundle Instrument Serif, IBM Plex Sans, JetBrains Mono `.ttf` files in `Resources/Fonts/`. Register via `Info.plist` `UIAppFonts`.
- `Font.display(_:)`, `Font.ui(_:)`, `Font.mono(_:)` helpers; sizes pass through to Dynamic Type by scaling against `UIFontMetrics.default`.

### 6.3 Backgrounds
- `PaperBackground` view modifier: cream fill + 4-radial-gradient overlay of paper grain dots, matching the CSS spec.
- `FeltBackground`: ellipse highlight + bottom shadow + speckle (deferred to v1.1).

### 6.4 Components
- `DieView(value:size:held:scoring:)` draws the bone face + pip layout from the same pip arrangement table the prototype uses.
- `AvatarView(name:colorIndex:size:active:)` renders an initial in a colored circle with the active "ring" outline.
- `WalnutButton` wraps a primary CTA with chunky drop shadow + walnut grain background.
- `ChipButton` for quick-add scores.

### 6.5 Animation
- Now-Rolling banner: `withAnimation(.spring(...))` on `activePlayerIndex` change.
- Pulse dot: looped `phase` animation via `TimelineView`.
- Confetti: `Canvas` + particle array driven by `TimelineView(.animation)` for game-over.
- Die "scoring" outline: animated outline color change.

## 7. Navigation

- Root: `NavigationStack` rooted on Home (after Onboarding).
- Active game is pushed onto the stack with `.navigationBarBackButtonHidden`; "back" requires explicit confirm to leave the in-progress game (we save state, but want user intent).
- Bottom sheets (`.sheet(isPresented:)`):
  - Bank Confirm
  - Score Helper
  - Keypad
- Tab bar (per design) is rendered when in Home/History/Stats/Settings; hidden during Active Game and over Onboarding.

## 8. Persistence and migration

- `ModelContainer` initialized at app launch with schema = [Game, Player, ActionLogEntry].
- v1 schema does not have migrations to worry about.
- Resume logic: on launch, query for `Game` where `endedAt == nil`; if found, route to Active Game; else Home.

## 9. Accessibility

- All text uses `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` upper bound.
- "Now Rolling" banner: `accessibilityElement(children: .combine)` + label "Now rolling: Maya. Banked 4,250 of 10,000."
- Recent Actions rows expose an `accessibilityAction(named: "Undo this action")` for assistive tech to surface the undo without tap.
- Min tap target 44pt enforced via `.frame(minWidth: 44, minHeight: 44)` on icon-only buttons.

## 10. Testing strategy

- **ScoringTests:** combo detection across rule variants, including edge cases (six 1s, two-triples on/off, straight on/off).
- **GameFlowTests:** turn order, bank, bust, final round trigger, final round completion, target-hit-while-final-round.
- **UndoTests:** undo each action type; undo across final round; undo on game-over screen.
- **Snapshot tests:** deferred to v1.1 (use Xcode Previews instead).

## 11. Out-of-scope reminders

Anything in [FUNCTIONAL_SPEC.md §2.1](FUNCTIONAL_SPEC.md). When in doubt, ship the spec, not the design canvas. The canvas has 14 screens; we ship 11.

---

## Change log
- 2026-05-15 — Initial dev design, paired with FUNCTIONAL_SPEC v1.
