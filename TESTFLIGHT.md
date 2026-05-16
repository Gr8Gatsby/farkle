# Farkle — TestFlight beta

Thanks for helping test Farkle before it ships to the App Store.

## Install

1. On your iPhone, open the **TestFlight** app (install from the App Store if you don't have it).
2. Open the invite link the developer sent you.
3. Tap **Accept** → **Install**.
4. Launch Farkle from your home screen.

The beta build is signed with a TestFlight-only certificate and expires
90 days after upload. If it expires, the developer will push a fresh
build and TestFlight will prompt you to update.

## Quick tour

- **Home → Start a new game** to set up players and house rules.
- **Quick-add chips** (+50, +100, …) record what you rolled. The
  "Score helper" sheet is a tappable cheat sheet of every Farkle
  combo with its value.
- **Farkle button** in the pending-turn card busts the turn (zero
  the pending total and pass).
- **Bank** when you're done rolling. Confirmation sheet previews
  the math — and tells you "WINS!" or "SHORT BY N" during the final
  round.
- **Edit** chip in the standings header lets you reorder players
  mid-game and add new ones (during round 1 only).
- **Top-bar chip (📡 1234 / 👤 1)** is the room code for the live
  scoreboard. Tap it to open the invite sheet and read it aloud
  to friends nearby.
- **Join a game** on Home → other phones running Farkle on the same
  Wi-Fi can watch the live scoreboard, claim a seat, and add a photo.

## What to look for / test

- [ ] Run a full game to "Maya wins." — verify confetti + trophy + count-up appear.
- [ ] Tap **Share the win** → does the iOS share sheet open with a brag image preview?
- [ ] Tap **Save image** → check Photos app for the saved card. The first tap should prompt for Photos permission.
- [ ] Try **Rematch** — does it drop you into a new game with the same players?
- [ ] Try **Wait — that's wrong** below the standings — does it return to Final Round?
- [ ] Two devices on the same Wi-Fi: open Farkle on phone B, tap **Join a game**, pick the room code from phone A. Verify the live scoreboard updates as A banks scores.
- [ ] As a joiner, tap your player card → set a photo → does it show up on the host's standings?
- [ ] Background the app mid-game, return — game state restored?

## How to report issues

Reply to the TestFlight invite email with:

- iPhone model + iOS version
- Steps to reproduce
- Screenshot or screen recording if visual
- Anything in TestFlight → Send Beta Feedback (shake gesture also works)

## Known limitations (v1)

- iPhone only (iPad coming later).
- The "live scoreboard" feature only works with other iPhones on the same Wi-Fi (or Bluetooth as a fallback).
- "Recap" of a finished game isn't available yet — for now the Game History list just shows the final result.
- English only.

Thanks for the time. The faster we find issues, the better the
1.0 release will be.
