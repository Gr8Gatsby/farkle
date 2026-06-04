# Farkle for Android — Functional Spec

A warm, tactile, ad-free Android app for keeping score in physical Farkle games.
Phone tracks scores; dice stay on the table. This is the Android counterpart to the
iOS app and targets **full feature parity** with it (see `FUNCTIONAL_SPEC.md`).

> Functional requirements only. Platform/implementation choices (Kotlin, Jetpack
> Compose, WebSocket + Network Service Discovery for the live scoreboard) are
> recorded separately in the dev design document, not here.

## 1. Product principles

1. **Score tracker, not a game.** The app never rolls dice or decides outcomes. It records what humans rolled.
2. **Whose turn is unmissable.** A player must never wonder who is currently rolling or whether a score has been submitted.
3. **Everything is reversible.** Every score change can be undone, including after a "winner" is declared.
4. **Warm and unhurried.** Aesthetic: paper, walnut, bone — game-night vibes, no neon, no ads, ever.
5. **Free and ad-free.** No advertising, no paid tiers.
6. **Parity, not a port of bugs.** Behavior should match the iOS app screen-for-screen and rule-for-rule. Where a platform convention differs (system back, share sheet, permissions), follow the Android convention while preserving the same outcome.

## 2. Scope

### 2.1 In scope
- Local-only, single-device pass-and-play (no accounts, no cloud sync).
- The 11 screens listed in §4 (parity with iOS).
- House-rule toggles per game (target score, three-pair, straight, two triplets, four-with-pair, must-open).
- Persistent game state across app launches and process death.
- Live read-only scoreboard for nearby devices over the local network (§2.2).

### 2.2 Live scoreboard
- A **host** (the device running the game) broadcasts its score sheet over the local network to nearby devices running Farkle. No internet, no accounts.
- Because the transport is a standard local-network protocol rather than an Apple-only one, joiners are **not limited to iOS** — any device on the same network that can run the Farkle client (Android, and in future a web viewer) can join. Cross-platform join is an explicit goal.
- Hosting starts automatically when a game is created or resumed. A short **room code** is shown in the Active Game top bar as a tappable chip (e.g. `📡 1357 · 👤 2`) so the host can read it aloud.
- Joiners see a read-only **Scoreboard** view that mirrors the host's state with animated score tickers, an active-player highlight, a live action feed, and pop-up "flavor" messages ("Maya passed Jules!", "🔥 Hot dice!", "Final round!", "Maya wins.").
- On connect, the joiner picks an identity: **one of the host's player slots** (e.g. "I'm Jules") or **"Just watching"**. After picking a player, the joiner may attach a photo for that seat. The photo is resized and compressed to a small payload and sent back to the host, which merges it into every snapshot so all viewers — and the host — see the photo in place of the colored initial. The chosen player card gets a "YOU" badge, and when it's that player's turn an "IT'S YOUR TURN" banner appears above the grid.
- Discovery: auto-discover nearby hosts by default; the room code is the fallback for tricky networks. The joiner can pick a discovered host or enter the code.
- Permissions: prompts for local-network / nearby-devices access per Android requirements on first use. Nothing leaves the local network; payloads are JSON game snapshots.
- The joiner cannot edit scores. Only the host owns the score sheet.
- If the host quits, joiners get a "Host ended the game" overlay and return to Home.

### 2.3 Out of scope
- Accounts, cloud sync, internet multiplayer.
- Full-screen Hot Dice / Farkle celebrations (still announced in-line).
- Sound/haptics customization beyond OS defaults.
- Achievements / badges (stats screen ships without the badge row).
- Tablet-optimized layout (phone-first; tablets get default scaling).
- Localization (English only).
- Onboarding pages 2 & 3 (single hero screen only).

## 3. Players, games, and scoring

### 3.1 Players
- A game has 2–8 players.
- Each player has a display name (1–20 characters) and a deterministic avatar color/initial.
- Players are entered fresh per game (no persistent roster).

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
- The screen transitions to a dedicated felt-themed **Final Round screen** that hosts every remaining player's last roll. It shows: trigger player's name, score to beat, current player's avatar + gap to win, pending-turn controls (chips, keypad, score helper), the "still to roll" queue with each player's deficit, and the Bank / Bust buttons with WINS! / SHORT BY N coaching on the preview.
- The "score to beat" is the highest banked total at any moment — if a later player overtakes the trigger, the bar moves up for everyone after them.
- After the last remaining player completes their turn, the highest total wins. Tie: trigger player wins (they got there first).

### 3.4 Scoring actions
A turn is a sequence of one or more **rolls**. Each roll has a delta (positive integer). The user enters the turn total via:
- **Quick-add chips** for common values: 50, 100, 150, 200, 300, 350, 500, 1000.
- **Keypad entry** for arbitrary values.
- **Score Helper** (optional): tap scoring combos; helper computes the roll's score from house rules and adds it to the pending turn.

At any time during a turn the player can:
- **Bank** — commits the turn total to the player's banked score; play passes to the next player.
- **Farkle / bust** — discards the turn total (set to 0); play passes to the next player.

### 3.5 "Must open with 500" rule
- A player whose banked score is 0 cannot bank a turn worth less than 500. The Bank button is disabled with explanatory subtext until the pending turn ≥ 500.

### 3.6 Game end
- When a player banks a score ≥ target, the game enters **final round**: each remaining player takes one more turn, then the game ends.
- During final round, the active-game screen shows a "Final round" pill and a "X turns remain" countdown.

## 4. Screens

Numbering matches the iOS design canvas labels for traceability/parity.

### 4.1 (01) Onboarding
- Single hero screen with title "Roll, hold, *repeat.*", subtitle copy, and a "Start a game" primary CTA.
- Shown only on first launch. Skipping or completing it sets a "seen" flag.

### 4.2 (02) Home
- Greeting line ("Hey, fancy a roll?").
- **Resume game card** appears only if there is an in-progress game. Shows game name (auto-generated like "Tuesday Night Roll"), player avatars, current round, whose turn, and your score gap if applicable. Tapping resumes.
- **"Start a new game"** primary action (always visible).
- **Join a game** entry point for the live scoreboard joiner flow.
- **Recent games list** (most recent 5). Each row shows winner, player count, date, and winning score. Tapping opens the game's recap.

### 4.3 (03) New Game Setup
- Player list with reorder handles, avatar, name field, delete button.
- "Add player" row (disabled at 8 players). Default suggests 2 starter rows.
- Target-score selector (three preset chips + custom).
- House-rules toggles (§3.2).
- Cancel and "Pass the dice →" primary CTA. CTA disabled until ≥2 players have non-empty names.

### 4.4 (04) Active Game
The heart of the app. Layout (top to bottom):
1. **Top bar**: back button (with "leave game" confirm), round/target label, persistent **Undo** button, room-code chip.
2. **"Now Rolling" banner** — high-contrast: active player's avatar (highlighted ring), name in italic display serif, animated "ROLLING" pulse dot, player's currently banked total on the right.
3. **Pending-turn card** — visually distinct ("not banked yet" label): large pending total, roll count, quick-add chip row, "+ Custom" keypad, "Score helper" link, "Clear" link (resets pending to 0 without ending the turn), and a crimson Farkle capsule.
4. **Standings ladder** — players ranked by banked score; current player marked with "ROLLING" pill; mini progress bar toward target; an Edit affordance for mid-game roster editing.
5. **Recent actions log** — last 5 banks/busts; each row shows player, action, amount, and time-ago. Tapping a row opens an Edit/Undo sheet (Edit amount for banks; Undo removes the action and everything after it and replays; Cancel).
6. **Bottom action bar**: a single full-width walnut **Bank** button showing "+450 → 4,700" preview math; opens §4.5.

**Theme:** Paper (cream) default. Felt theme deferred.

### 4.5 (04d) Bank Confirmation modal
- Bottom sheet before any bank commit.
- Header: "Bank +450 for Maya?"
- Visual delta: avatar, "was 4,250 → 4,700", progress bar toward target.
- Reminder: "You can undo this from the Recent actions list."
- Buttons: "Keep rolling" (cancel) and a turn-context commit ("Bank & pass to Jules →" / "Bank & start final round →" / "Bank & end the game" / "Bank & win 🎉").

### 4.6 (05) Score Helper
- Full-height sheet titled "SCORE HELPER".
- Reference list of scoring combos grouped: Singles, Three of a kind (per face), Four of a kind, Five of a kind, Six of a kind, Special combos (Straight, Three pairs, Two triples, Four-with-pair — each shown only when its house rule is on).
- Each row: mini dice glyph, combo name, value, plus button. Tapping adds its value to a running "Add +X to turn" total; tapping again adds again.
- "Clear" resets the running total. "Add +X to turn" commits to pending turn and dismisses.
- If selections total six dice, the helper flags Hot Dice (bumps the player's hot-dice stat).
- Helper is a reference list, not a calculator — the player still recognizes their hand.

### 4.7 (06) Game Over (winner)
- **Paper variant**: cream-and-walnut backdrop, warm gold halo behind a hand-drawn trophy + crimson ribbon banner with the winner's first name. Continuous warm-palette confetti.
- Eyebrow: game name in tracked mono caps. Headline: winner's first name in display italic walnut + " wins." in display roman ink. Score counts up from 0 over ~1.4s.
- Standings card: 1st-place row with winner's avatar and "1ST PLACE" label, divider, then remaining seats in italic-numbered rows. Winner avatar uses the trophy-crest treatment (golden halo + laurel ring + trophy badge).
- **Connection chip** top-left: "SYNCED · N" when peers connected, or "SAVED LOCALLY" when none. Informational only.
- **Close (X)** top-right is the only exit; returns to Home. Never auto-navigates away.
- **"Wait — that's wrong" undo link**: undoes the winner's last bank and returns to the final round.
- **Share the win**: pre-rendered portrait "story card" image via the Android share sheet.
- **Save image**: writes the same image to the device gallery (prompts per Android requirements), with a "Saved" confirmation.
- **Rematch** starts a new game with the same players and rules.

### 4.8 (07) Game History
- Header: total games, wins, win-rate (computed against a chosen "primary player" selected on first open, persisted).
- Filter chips: All games / My wins / 4+ players / This month.
- List rows: game name, date, player avatars, rounds, duration, winner with winning score.
- Tapping a row opens recap (read-only).

### 4.9 (08) Player Stats
- One-player-at-a-time view with a player picker at top (defaults to primary player).
- Header: avatar, name.
- Stat grid: Games, Wins, Win rate, Avg turn, Hot dice, Farkles (Hot dice / Farkles derived from logged events).
- Sparkline of avg-turn over last 10 games, with delta vs. prior 10.
- Badges/achievements row deferred.

### 4.10 (09) Settings
- Sections:
  - **Game feel**: dice sound toggle, haptics toggle (OS defaults; no granularity).
  - **Default rules**: target score, three pairs, straight 1–6, two triplets, four-with-pair, must open with — prefill values in New Game Setup.
  - **Data**: Export game history (JSON share), Reset all data (with confirm).
- Footer: "FARKLE · made with care · No ads. Not now, not ever."

### 4.11 (10) Rules reference
- Static cheat sheet.
- Top: the three numbered "how it works" steps (roll, farkle, target).
- Score chart of all base combos and values, rendered with mini bone-dice visuals.

## 5. Behavioral requirements

### 5.1 Undo
- Every banking event, every bust event, and starting the final round are reversible via: the top-bar **Undo** button (undoes most recent), a row in Recent Actions, or the "Wait — that's wrong" button on Game Over.
- Undo is unbounded within a game (full action log).
- Undoing a bust restores the turn's pending total so the player can continue or re-bank.
- Undoing a bank rewinds turn order to that player.
- The Android system **Back** gesture/button follows the same intent (confirm before leaving an active game; dismiss sheets/overlays first).

### 5.2 Pass-and-play guard
- When the active player changes, the new "Now Rolling" banner uses a subtle slide+fade transition (~400ms) so the change is noticed.

### 5.3 Hot Dice and Farkle events
- Logged for stats but **not** shown as full-screen takeovers.
- Hot Dice (all 6 dice used in scoring) is detected via the Score Helper; it bumps the player's hot-dice counter.
- Farkle is the bust button.

### 5.4 Persistence & roster editing
- The host can edit the player roster mid-game from an **Edit** affordance in the Standings header. The Edit Players sheet supports drag-to-reorder at any point (the currently rolling player stays the rolling player), and an **Add player** action while the first round is still incomplete (no more than `players.count` bank/bust actions logged). After the first round closes, the Add row is replaced with an info note.
- The active game is auto-saved after every action. Killing the app / process death and reopening returns the user to the same game state.
- Completed games are stored in History indefinitely until the user clears data.

### 5.5 Error and edge cases
- App restored to an in-progress game on launch → land directly on Active Game.
- Removing a player mid-game is not allowed (only via Undo back through that player's turns).
- Renaming a player mid-game is allowed via a long-press in the standings list.
- Attempting to bank 0 → button disabled.
- Attempting to bank below the "must open with" threshold → button disabled with subtext: "Must open with 500."

## 6. Visual identity (parity with iOS)
- **System name:** "Felt & Bone".
- **Colors:** cream paper `#f3ede0`, walnut `#5b3a1f`, casino felt `#2d5a47`, bone `#faf6ee`, crimson `#a8341a` (Farkle), gold `#b88a3e` (winners, hot dice).
- **Typography (same families):**
  - Display: Instrument Serif (often italicized).
  - UI: IBM Plex Sans.
  - Tabular numbers: JetBrains Mono.
- **Surfaces:** paper-grain background default; warm paper-card containers with soft shadows; tactile walnut buttons with chunky drop shadow on primary CTAs.

## 7. Non-functional requirements
- **Platform:** native Android, phone-first. Minimum supported OS version to be set in the dev design doc.
- **Performance:** Active Game screen reaches first interactive frame quickly after launch; undo latency feels instant (<50ms target).
- **Accessibility:**
  - Respect system font scaling on all body and label text.
  - Content descriptions on every interactive control; "Now Rolling" banner announces player and banked score to the screen reader.
  - Color is never the only signal of state (turn ownership uses banner + pulse + text).
  - Tap targets ≥48dp.
- **Privacy:** All data on-device. No analytics, no internet calls. Local-network traffic stays on the LAN.

## 8. Open questions
- Minimum Android API level (decide in dev design).
- Whether the room-code transport should already account for the future web viewer in v1 of the Android app, or just be compatible.

---

## Change log
- 2026-06-03 — Initial draft. Android counterpart to the iOS Farkle app, targeting full feature parity (all 11 screens, scoring rules, final round, undo, persistence, live read-only scoreboard). Live scoreboard generalized from Apple Multipeer to a local-network transport so non-Apple devices (Android now, web viewer later) can join. Implementation/tech choices deferred to the dev design doc.
- 2026-06-03 — v1 implementation landed on `feature/android-app` (Kotlin + Jetpack Compose; see `ANDROID_DEV_DESIGN.md`). Game model + engine ported with 32 passing unit tests (scoring + game flow, 1:1 with the iOS XCTest suites). All screens built to parity: Onboarding, Home (+ resume card), New Game, Active Game (Now Rolling banner, pending card with quick-add chips/keypad/score helper/clear/Farkle, standings ladder with edit, recent-actions edit/undo, Bank with preview math + must-open enforcement + turn-context confirm), felt Final Round (announcement + play screen), Game Over (trophy crest, count-up, standings, share/save image, rematch, "wait that's wrong" undo), History, Stats, Settings, Rules. JSON file persistence with auto-save + resume across process death. Live scoreboard host (WebSocket + NSD/Bonjour) auto-starts on Active Game with a room-code chip; joiner discovers hosts, mirrors read-only with active-player highlight, seat pick ("YOU" badge + "it's your turn" banner) and photo claim. Android system-back kept in-app via BackHandler. Manually verified end-to-end on a Pixel 7 (API 35) emulator; host NSD advertising confirmed on-device (two-device join needs a second LAN device).
- 2026-06-03 — Resolved open questions: minimum API level set to 26 (Android 8.0). The room-code transport is JSON-over-WebSocket so it is already compatible with a future web viewer.
- 2026-06-03 — Re-aligned the score-keeping UI to the current iOS revision (the original Android branch predated the iOS "Redesign scoring UI" change; merged from `feature/license`). Functional changes: the active player is now shown inline at the top of the unified Standings (no separate "Now Rolling" banner); the recent-actions list is removed from the score-keeper (undo is via the top-bar Undo); quick-add values are now 50/100/200/300/350/500/1,000/1,500 with no free-form keypad; banking shows a confirmation with a 5-second auto-bank countdown; the final-round screen doubles as its announcement and coaches each player with "needs X to win". Also fixed broken on-device graphics: emoji that rendered as missing-glyph boxes were replaced with vector icons. All 32 unit tests still pass; redesigned screens verified on the Pixel 7 (API 35) emulator.
