# Privacy Policy — Farkle

_Last updated: 2026-05-16_

**TL;DR — Farkle collects nothing.** All scores stay on your device.
There is no account, no server, no analytics, no tracking, no ads.

## What Farkle does

Farkle is a score-tracking app for the physical dice game of the same
name. It records the scores you and your friends type in during a
game, lets you keep a local history, and — if you choose — broadcasts
a live read-only scoreboard to friends nearby running the same app.

## What Farkle stores

- **On your device only:** the games you create (player names, scores,
  per-turn history), your house-rules preferences, and any photo you
  voluntarily attach to a player slot (Photos / Contacts picker). All
  of this lives in the app's private SwiftData store and is not sent
  anywhere.
- **Nowhere else.** Farkle has no servers, no cloud sync, and makes
  no network requests to anyone we operate.

## Permissions Farkle may ask for

- **Local Network** — to discover other phones on the same Wi-Fi that
  are running Farkle and want to watch the live scoreboard. Connections
  are peer-to-peer via Apple's MultipeerConnectivity framework. No data
  leaves the local network.
- **Photos (Add only)** — _only_ when you tap "Save image" on the
  winner screen, so Farkle can write the brag image to your photo
  library. Farkle never reads your existing photos.
- **Contacts** — _only_ if you tap "Pick from Contacts" while choosing
  a player avatar. The picker is supplied by iOS and runs out of
  process; Farkle only receives the image data for the contact you
  explicitly tap. Farkle never enumerates or reads your contacts.

You can deny any of these in iOS Settings without breaking the app.

## What Farkle does NOT do

- No accounts, sign-ins, or unique identifiers
- No analytics (no Firebase, Mixpanel, Amplitude, anything)
- No advertising, no ad networks, no SDKs that collect
- No crash reporting that includes user data
- No location access
- No microphone or camera access
- No data sold or shared with third parties

## Children

The app is appropriate for all ages. We do not knowingly collect any
information from anyone, including children.

## Changes

If we ever change this, the updated policy will live at the same URL
and the "Last updated" date above will change. Material changes will
ship with a release note.

## Contact

Questions? Open an issue at the project's GitHub repo (see the App
Store listing's Support URL).
