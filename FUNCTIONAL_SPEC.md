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

### 2.2 Live scoreboard (Multipeer)
- A host (the device running the game) broadcasts their score sheet over local network / Bluetooth to nearby phones running Farkle. No internet, no accounts.
- Hosting starts automatically when a game is created or resumed. The 4-digit room code is shown in the Active Game top bar as a tappable chip (e.g. `📡 1357 · 👤 2`), so the host can read it aloud without opening a separate sheet.
- Joiners see a read-only **Scoreboard** view that mirrors the host's state with animated score tickers, an active-player highlight, a live action feed, and pop-up "flavor" messages ("Maya passed Jules!", "🔥 Hot dice!", "Final round!", "Maya wins.").
- On connect, the joiner picks an identity: **one of the host's player slots** (e.g. "I'm Jules") or **"Just watching"**. The chosen player card on the scoreboard gets a "YOU" badge, and when it's that player's turn an "IT'S YOUR TURN" banner appears in gold above the grid.
- Discovery: auto-discover nearby hosts by default; the room code is the fallback for tricky networks. Joiner can pick a discovered host or enter the code.
- Permissions: prompts for Local Network access on first use. Nothing leaves the devices; payloads are JSON `GameSnapshot`s on Multipeer's reliable channel.
- The joiner cannot edit scores. Only the host owns the score sheet.
- If the host quits, joiners get a "Host ended the game" overlay and return to Home.

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
  - Two triplets = 2,500 (on)
  - 4 of a kind with a pair = 1,500 (on)
  - Must open with 500 (on)
- Base scoring (always on):
  - Single 1 = 100, Single 5 = 50
  - Three 1s = 300, Three N (N≥2) = N × 100
  - Four / Five / Six of a kind = 1,000 / 2,000 / 3,000 (any face)
- The New Game screen prefills with the players from the most recent game (names + avatar colors). The user can edit any row, remove rows (down to one), or add up to eight.

### 3.3 Turn order
- Players roll in the order they were added during setup.
- After someone reaches the target, every remaining player gets exactly one more turn ("final round"). Highest total wins. Ties: the player who hit the target first wins.

#### Final round (when the target is hit)
- When a player banks a total ≥ the target, the **triggering player does not get another turn** — they're done.
- Every other player gets exactly one more turn. Turn order continues normally.
- The screen transitions to a dedicated felt-themed **Final Round screen** that hosts every remaining player's last roll. It shows: trigger player's name, score to beat, current player's avatar + gap to win, pending-turn controls (chips, keypad, score helper, hot-dice toggle), the "still to roll" queue with each player's deficit, and the Bank / Bust buttons with WINS! / SHORT BY N coaching on the preview.
- The "score to beat" is the highest banked total at any moment — if a later player overtakes the trigger, the bar moves up for everyone after them.
- After the last remaining player completes their turn, the highest total wins. Tie: trigger player wins (they got there first).

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
5. **Recent actions log** — last 5 banks/busts; each row shows player, action, amount, and time-ago. Tapping a row opens an Edit/Undo sheet:
   - **Edit**: for bank actions, the user can change the amount via keypad (fixes a mistyped score without losing turn order).
   - **Undo**: removes the action (and everything after it) and replays state.
   - **Cancel**: no change.
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

### 4.6 (05) Score Helper (scoresheet)
- Full-height sheet titled "SCORE HELPER".
- A reference list of scoring combos grouped by section: Singles, Three of a kind, Four of a kind, Five of a kind, Six of a kind, Special combos (Straight, Three pairs, Two triples — each shown only when the matching house rule is on).
- Each row shows: mini dice glyph, combo name, value, plus button.
- Tapping a row adds its value to a running "Add +X to turn" total. Tapping again adds again (so two singles 5 = +100).
- "Clear" resets the running total. "Add +X to turn" commits to pending turn and dismisses.
- Hot Dice mark: if the user has selected any 6-die combo (or accumulated 6 dice worth of selections), the helper passes a `usesAllDice = true` flag back, which auto-checks the Hot Dice toggle on the pending-turn card.
- Helper is a reference list, not a calculator — the player still has to recognize their hand.

### 4.7 (06) Game Over (winner)
- Felt-green celebration backdrop with continuous confetti.
- Game name, winner's name in display italic, "wins.".
- Winner's avatar with gold winning-score pill.
- Final standings table.
- The screen stays visible until the user explicitly chooses **Rematch** or **Done**; the system never auto-navigates away.
- **Critical "Wait — that's wrong" button**: undoes the winner's last bank and returns to the final round (the game exits ended state).
- **Share the win** primary action: generates a 1080×1080 felt brag card image (winner, final standings, game name, date) and presents the iOS share sheet. The user can send it via Messages, Mail, Photos, social apps, AirDrop, etc.
- **Rematch** (starts a new game with the same players and rules) and **Done** (exits to Home, the completed game is preserved in History).

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
- 2026-05-16 — New Game refinements: prefill players (names + avatar colors) from the most recent game; flip Two-triples default to on (2,500); New Game sheet pinned to full-height `.large` detent with tighter top padding so the title and player rows sit near the top; trash icon now appears on every player row when there are at least two, so any seat can be removed.
- 2026-05-16 — Active Game polish: removed duplicate top safe-area padding so content sits right under the system bar (was leaving ~100pt of empty cream); enlarged the quick-add chip buttons (height 36→48, font 13→16) for a more tactile press. Score Helper rewritten from a dice-input calculator to a tappable scoresheet: each scoring combo in the rules is a row the player taps to accumulate; encourages players to spot their own hands instead of letting the phone do the math. Defaults migrator covers the change to the Two-triples house rule so cached preferences pick up the new default on first launch.
- 2026-05-16 — Fix four/five/six-of-a-kind multipliers to match the standard Farkle rule (per Wikipedia and dicegamedepot/farkle.games): four = 2×, five = 3×, six = 4× (the three-of-a-kind value). The design bundle's cheat sheet used 2/4/8 (a less-common doubling variant). Updated in the scoring engine, the Rules cheat sheet, and the Score Helper rows; tests updated accordingly.
- 2026-05-16 — Switch to the user's house variant. Three 1s = 300 (small bonus over the uniform face×100); three of any other face = face × 100; four / five / six of any face = fixed 1000 / 2000 / 3000. Added a new "4 of a kind with a pair = 1500" combo as a House Rule (default on; toggle in New Game and Settings). Score Helper restructured: per-face rows only for three-of-a-kind; four/five/six of a kind collapse to one row each since the value is face-independent. Defaults migrator bumped to v2 to enable the new combo on cached preferences.
- 2026-05-16 — Final-round redesign. When a player banks past the target the game now shows a full-screen "FINAL ROUND" announcement (trigger player named, score to beat, remaining players each with the deficit they need to close). Trigger player explicitly does NOT get another turn. While the final round is active, the Now Rolling banner swaps "BANKED" for "BEAT: X" coaching and the Bank-preview shows "WINS!" / "SHORT BY N" relative to the current high score. The bar moves up if a later player overtakes the trigger. Recent Actions tap now opens an Edit/Undo sheet — bank amounts can be edited in place (e.g., correct a typo without losing turn order); bust actions can only be undone. Engine gains `setActionAmount(actionID:newAmount:)` and `markFinalRoundAnnouncementShown()`. Game model persists `finalRoundAnnouncementShown` so the announcement survives app restarts. 7 new tests cover the new paths.
- 2026-05-16 — Final-round special screen hosts the rolls. Promoted FinalRoundAnnouncement to a full FinalRoundView that stays up for the entire final round (felt theme, hero with score-to-beat, current-player card with deficit, pending-turn controls, "still to roll" queue, recent-final-round turns, Bank/Bust with WIN/SHORT preview). Game Over: added "Share the win" — renders a 1080×1080 felt brag card (winner, final standings, game name, date) via SwiftUI ImageRenderer and presents `UIActivityViewController`, so the win can go out via Messages/Mail/Photos/AirDrop/etc. Replaced the Recap shortcut with explicit Rematch / Done buttons; the celebration screen now requires explicit dismissal.
- 2026-05-16 — Live multipeer scoreboard. New `FarkleNetSession` (MultipeerConnectivity, service type `farkle-game`) lets the host broadcast `GameSnapshot` payloads to nearby joiners. Host gets an "Invite viewers" button on Active Game / Final Round; sheet shows a 4-digit room code (Bonjour `discoveryInfo`) + connected viewer count. Snapshots re-broadcast on every state-changing fingerprint (action count, pending turn, banked totals, active player, end). Joiner gets a "Join a game" entry on Home → `JoinGameSheet` (auto-discover nearby + manual room-code fallback) → animated `ScoreboardView` (number-ticker scores via `contentTransition(.numericText)`, glowing active-player card, live action feed, flavor messages from `FlavorMessageMaker` for position swaps / hot dice / Farkles / final-round trigger / win, full win celebration mirror with confetti). 7 new snapshot/flavor tests; total 35 passing.
- 2026-05-16 — Multipeer polish round. Hosting now starts automatically when Active Game appears (no waiting for a tap), and the room code is always visible as a top-bar chip (`📡 1357 · 👤 2`). New peers get the current snapshot the moment they connect (was: they had to wait for the next state change). Joiner gets an `IdentityPickerOverlay` after connecting — they pick one of the host's player slots ("I'm Jules") or "Just watching". The chosen player's card gets a "YOU" badge with a paper-tone border on the scoreboard, and when that player is the active roller, an "IT'S YOUR TURN" gold banner appears above the player grid with instructions ("Roll, then tell the scorekeeper what you got").
