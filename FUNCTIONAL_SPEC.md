# Farkle — Functional Spec

A warm, tactile, ad-free iOS app for keeping score in physical Farkle games.
Phone tracks scores; dice stay on the table.

## 1. Product principles

1. **Score tracker, not a game.** The app never rolls dice or decides outcomes. It records what humans rolled.
2. **Whose turn is unmissable.** A player must never wonder who is currently rolling or whether a score has been submitted.
3. **Everything is reversible.** Every score change can be undone, including after a "winner" is declared.
4. **Warm and unhurried.** Aesthetic: paper, walnut, bone — game-night vibes, no neon, no ads, ever.
5. **Free and ad-free.** No advertising, no paid tiers in v1.

## 2. In scope for v1

- Local-only, single-device pass-and-play (no accounts, no cloud sync).
- The 11 screens listed in §4.
- House-rule toggles per game (target score, three-pair, straight, must-open).
- Persistent game state across app launches and crashes.

## 2.1 Explicitly out of scope for v1

- Accounts, cloud sync, multi-device.
- Hot Dice / Farkle / Pass-and-play "moment" full-screen celebrations (still announced in-line, just no full-screen takeover).
- Sounds, haptics customization beyond OS defaults.
- Achievements / badges (stats screen ships without the badge row).
- iPad layout (phone-first; iPad gets default scaling).
- Localization (English only).
- Onboarding pages 2 & 3 (single hero screen only).

## 3. Players, games, and scoring

### 3.1 Players
- A game has 2–8 players.
- Each player has a display name (1–20 characters) and a deterministic avatar color/initial.
- Players are entered fresh per game in v1 (no persistent roster).

### 3.2 Game setup
- Target score: 5,000 / 10,000 / 15,000 (default 10,000) or custom (1,000–50,000, increments of 500).
- House rules (toggleable, defaults in parens):
  - Three pairs = 1,500 (on)
  - Straight 1–6 = 1,500 (on)
  - Two triples = 2,500 (off)
  - Must open with 500 (on)

### 3.3 Turn order
- Players roll in the order they were added during setup.
- After someone reaches the target, every remaining player gets exactly one more turn ("final round"). Highest total wins. Ties: the player who hit the target first wins.

### 3.4 Scoring actions
A turn is a sequence of one or more **rolls**. Each roll has a delta (positive integer). The user enters the turn total via:
- **Quick-add chips** for common values: 50, 100, 150, 200, 300, 500, 1000.
- **Keypad entry** for arbitrary values.
- **Score Helper** (optional): tap 1–6 dice values; helper computes the roll's score from house rules and adds it to the pending turn.

At any time during a turn the player can:
- **Bank** — commits the turn total to the player's banked score; play passes to the next player.
- **Farkle / bust** — discards the turn total (set to 0); play passes to the next player.

### 3.5 "Must open with 500" rule
- A player whose banked score is 0 cannot bank a turn worth less than 500. The Bank button is disabled with explanatory subtext until the pending turn ≥ 500.

### 3.6 Game end
- When a player banks a score ≥ target, the game enters **final round**: each remaining player takes one more turn, then the game ends.
- During final round, the active-game screen shows a "Final round" pill and a "X turns remain" countdown.

## 4. Screens

Numbering matches the design canvas labels for traceability.

### 4.1 (01) Onboarding
- Single hero screen with title "Roll, hold, *repeat.*", subtitle copy, and a "Start a game" primary CTA.
- Shown only on first launch. Skipping or completing it sets a "seen" flag.

### 4.2 (02) Home
- Greeting line ("Hey, fancy a roll?" — no name in v1 since there's no account).
- **Resume game card** appears only if there is an in-progress game. Shows game name (auto-generated like "Tuesday Night Roll"), player avatars, current round, whose turn, and your score gap if applicable. Tapping resumes.
- **"Start a new game"** primary action (always visible).
- **Recent games list** (most recent 5). Each row shows winner, player count, date, and winning score. Tapping opens the game's recap.

### 4.3 (03) New Game Setup
- Player list with reorder handles, avatar, name field, delete button.
- "Add player" row (disabled at 8 players). Default suggests 2 starter rows.
- Target-score selector (three preset chips + custom).
- House-rules toggles (§3.2).
- Cancel and "Pass the dice →" primary CTA. CTA disabled until ≥2 players have non-empty names.

### 4.4 (04) Active Game

The heart of the app. Layout (top to bottom):

1. **Top bar**: back button (with "leave game" confirm), round/target label, persistent **Undo** button.
2. **"Now Rolling" banner** — high-contrast, includes:
   - Active player's avatar (highlighted ring), name in italic display serif.
   - Animated "ROLLING" pulse dot.
   - Player's currently banked total on the right.
3. **Pending-turn card** — visually distinct (dashed border, "not banked yet" label):
   - Large pending total.
   - Roll count for the turn.
   - Quick-add chip row (§3.4).
   - "+ Custom" opens keypad sheet.
   - "Score helper" link opens §4.6.
   - "Clear" link resets pending turn to 0 without ending the turn.
4. **Standings ladder** — players ranked by banked score; current player marked with "ROLLING" pill; mini progress bar toward target.
5. **Recent actions log** — last 5 banks/busts; each row shows player, action, amount, time-ago, and an undo affordance. Tapping a row prompts a one-tap undo of that specific action.
6. **Bottom action bar**:
   - **Farkle** (secondary, crimson) — confirms then sets turn to 0 and passes.
   - **Bank** (primary, walnut) — shows "+450 → 4,700" preview math; opens §4.5.

**Theme:** Paper (cream) is the v1 default. Felt theme is deferred.

### 4.5 (04d) Bank Confirmation modal
- Bottom sheet that appears before any bank commit.
- Header: "Bank +450 for Maya?"
- Visual delta: avatar, "was 4,250 → 4,700", progress bar toward target.
- Reminder: "You can undo this from the Recent actions list."
- Buttons: "Keep rolling" (cancel) and "Bank & pass to Jules →" (commit).
- If banking will trigger the target, headline reads "Maya hits the target." and the commit button label becomes "Bank & start final round →".

### 4.6 (05) Score Helper (calculator)
- Bottom sheet.
- A row of 6 die slots; the user taps dice values 1–6 from a 6-die pad to fill slots.
- As dice are added, the helper detects combos using the active game's house rules and shows them as line items (e.g., "Single 1 +100", "Three 5s +500") summing to "This roll +X".
- "Cancel" dismisses. "Add to turn" adds the total to the pending turn and dismisses.
- Helper does not enforce that you used scoring dice — it's a calculator, not a referee.

### 4.7 (06) Game Over (winner)
- Felt-green celebration backdrop with confetti.
- Game name, winner's name in display italic, "wins.".
- Winner's avatar with gold winning-score pill.
- Final standings table.
- **Critical "Wait — that's wrong" button**: undoes the winner's last bank and returns to Active Game (the game exits final-round/end state).
- Secondary actions: **Recap** (opens read-only turn log) and **Rematch** (starts a new game with the same players and rules).

### 4.8 (07) Game History
- Header: total games, wins, win-rate. Win-rate is computed against a chosen "primary player" the user selects on first open (persisted setting).
- Filter chips: All games / My wins / 4+ players / This month.
- List rows: game name, date, player avatars, rounds, duration, winner with winning score.
- Tapping a row opens recap (read-only).

### 4.9 (08) Player Stats
- One-player-at-a-time view, with a player picker at top (defaults to primary player).
- Header: avatar, name.
- Stat grid: Games, Wins, Win rate, Avg turn, Hot dice, Farkles.
  - "Hot dice" and "Farkles" are derived from logged events during play (see §5).
- Sparkline of avg-turn over last 10 games, with delta vs. prior 10.
- Badges/achievements row deferred.

### 4.10 (09) Settings
- Account card deferred (no accounts in v1).
- Sections:
  - **Game feel**: dice sound toggle, haptics toggle (uses iOS defaults; no granularity).
  - **Default rules**: target score, three pairs, straight 1–6, must open with — these become the prefilled values in New Game Setup.
  - **Data**: Export game history (JSON share sheet), Reset all data (with confirm).
- Footer: "FARKLE · v1.0 · made with care · No ads. Not now, not ever."

### 4.11 (10) Rules reference
- Static cheat sheet.
- Top: the three numbered "how it works" steps (roll, farkle, target).
- Score chart table of all base combos and their values, rendered with mini bone-dice visuals.

## 5. Behavioral requirements

### 5.1 Undo
- Every banking event, every bust event, and starting the final round are reversible by tapping any of: the top-bar **Undo** button (undoes most recent), a row in Recent Actions, or the "Wait — that's wrong" button on Game Over.
- Undo is unbounded within a game — full action log.
- Undoing a bust restores the turn's pending total so the player can continue or re-bank.
- Undoing a bank rewinds turn order to that player.

### 5.2 Pass-and-play guard
- When the active player changes, the new "Now Rolling" banner uses a subtle slide+fade transition (~400ms) so the change is noticed.
- Optional v1.1: a "Pass to next player — tap when ready" curtain. Deferred for v1.

### 5.3 Hot Dice and Farkle events
- Logged for stats but **not** shown as full-screen takeovers in v1.
- Hot Dice (all 6 dice used in scoring) is an event the user marks via the Score Helper or a "+ all dice scoring" toggle on the pending-turn card; it bumps the player's hot-dice counter.
- Farkle is the existing bust button.

### 5.4 Persistence
- The active game is auto-saved after every action. Killing the app and reopening returns the user to the same game state.
- Completed games are stored in History indefinitely until the user clears data.

### 5.5 Error and edge cases
- App restored to an in-progress game on launch → land directly on Active Game.
- Removing a player mid-game is not allowed in v1 (only via Undo back through that player's turns).
- Renaming a player mid-game is allowed via a long-press in the standings list.
- Attempting to bank 0 → button disabled.
- Attempting to bank below the "must open with" threshold → button disabled with subtext: "Must open with 500."

## 6. Visual identity

- **System name:** "Felt & Bone".
- **Colors:** cream paper `#f3ede0`, walnut `#5b3a1f`, casino felt `#2d5a47`, bone `#faf6ee`, crimson `#a8341a` (Farkle), gold `#b88a3e` (winners, hot dice).
- **Typography:**
  - Display: Instrument Serif (often italicized for character).
  - UI: IBM Plex Sans.
  - Tabular numbers: JetBrains Mono.
- **Surfaces:** paper-grain background as default; subtle paper-card containers with warm shadows; tactile walnut buttons with chunky drop shadow on primary CTAs.

## 7. Non-functional requirements

- **Platform:** native iOS, SwiftUI, minimum iOS 17.
- **Performance:** Active Game screen reaches first interactive frame in <300ms after launch; undo latency <50ms.
- **Accessibility:**
  - Dynamic Type support on all body and label text.
  - VoiceOver labels on every interactive control; "Now Rolling" banner announces player and banked score.
  - Color is never the only signal of state (turn ownership uses banner + pulse + text).
  - Tap targets ≥44pt.
- **Privacy:** All data on-device. No analytics, no network calls.

## 8. Open questions
None at spec time. Will be added here as they arise.

---

## Change log
- 2026-05-15 — Initial draft based on design bundle handoff (Felt & Bone system), targeting SwiftUI iOS 17+, Paper theme default, scope = Core + Helper + History/Stats.
- 2026-05-15 — v1 implementation landed on `feature/initial-implementation`. All 11 screens built; 21 scoring+flow unit tests passing; build green via `xcodebuild`. Bust button now also opens a small confirm sheet (parity with Bank's confirmation, addressing the "I clicked it by accident" concern from the design chat).
