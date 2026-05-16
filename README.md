# Farkle

A warm, tactile, ad-free iOS app for keeping score in physical Farkle games.

- [Functional spec](FUNCTIONAL_SPEC.md)
- [Dev design](DEV_DESIGN.md)

## Build

Requires Xcode 16+ (Xcode 26 used during development), iOS 17+ deployment target.

```
brew install xcodegen      # one-time
xcodegen generate          # regenerates Farkle.xcodeproj from project.yml
open Farkle.xcodeproj
```

## Tests

```
xcodebuild test -project Farkle.xcodeproj -scheme Farkle -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project layout
See [DEV_DESIGN.md §2](DEV_DESIGN.md#2-repository-layout).

## License

Source is under the [MIT License](LICENSE) — © 2026 Kevin Hill. Use it,
fork it, learn from it, ship something better. The only ask is the
copyright notice + the license text travel with copies.

The bundled fonts ship under their own SIL Open Font License (kept
alongside the TTFs in `Farkle/Resources/Fonts/`):

- **Instrument Serif** — © 2022 The Instrument Serif Project Authors
- **IBM Plex Sans** — © 2018 IBM Corp.
- **JetBrains Mono** — © 2020 The JetBrains Mono Project Authors

OFL allows commercial bundling as long as the license text travels with
the fonts.

## Regenerating the app icon

The "Trio" app icon (three bone dice on cream paper) is rendered from a
SwiftUI view via `ImageRenderer`. To regenerate every iOS size:

```
swift tools/generate-icons.swift
```

Output PNGs land in `Farkle/Resources/Assets.xcassets/AppIcon.appiconset/`,
already wired up by `Contents.json`.
