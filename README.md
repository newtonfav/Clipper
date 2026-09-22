# Clipper

An on-device clipboard keyboard for iOS. Clipper remembers the last ten things you copied, lets you pin snippets forever, and inserts any of them from a custom keyboard. Nothing leaves the device: no network, no iCloud, no analytics.

## Targets

| Target            | Kind                    | Purpose                                                   |
|-------------------|-------------------------|-----------------------------------------------------------|
| `Clipper`         | iOS app                 | History + pins list, settings, onboarding, App Intents    |
| `ClipperKeyboard` | Custom keyboard         | Clipboard-only keyboard: tap to insert, pin, delete       |
| `ClipperShare`    | Share extension         | "Save to Clipper" from any share sheet                    |
| `ClipperTests`    | Unit tests              | Store rules, kind detection, text transforms              |

`Shared/` is compiled into every target and holds the model, storage and capture logic.

## Setup

```sh
brew install xcodegen
xcodegen generate
open Clipper.xcodeproj
```

### Bundle identifiers

The root is `com.newtonfav.clip`. To change it, edit:

1. `project.yml`: `PRODUCT_BUNDLE_IDENTIFIER` on all four targets and the three `group.com.newtonfav.clip` entitlement entries.
2. `Shared/AppGroup.swift`: `AppGroup.identifier`.

Then re-run `xcodegen generate`. For device builds set `DEVELOPMENT_TEAM` in `project.yml` and enable the App Group in your Apple developer account.

## Building from the command line

```sh
xcodebuild -project Clipper.xcodeproj -scheme Clipper \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build

xcodebuild -project Clipper.xcodeproj -scheme Clipper \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO test
```

## How capture works (and why it needs setup)

iOS does not let apps watch the clipboard in the background. Clipper records a copy at these moments:

- when the Clipper keyboard opens (needs **Allow Full Access**),
- when the Clipper app comes to the foreground,
- when you run the **Save to Clipper** shortcut (bind it to Back Tap or the Action Button),
- when you use **Share > Clipper** on selected text or a link.

The first programmatic clipboard read shows the iOS "would like to paste" prompt. Set Settings > Apps > Clipper > Paste from Other Apps to **Allow** to stop it.

## Testing in the simulator

1. Build and run the `Clipper` scheme on an iPhone simulator.
2. In the simulator: Settings › General › Keyboard › Keyboards › Add New Keyboard › Clipper, then tap Clipper › Allow Full Access.
3. Open Notes, type something, select all, Copy.
4. Open Clipper › ⋯ › Setup guide, tap the "Try it" field, hold the globe key and choose Clipper. Accept the paste prompt once. The copied text appears under Recent; tap it to insert.
5. Share sheet: in Safari select text › Share › Clipper › Save to Recent.
6. Shortcuts: build Get Clipboard → Save to Clipper and run it; the item appears without the app opening.

Unit tests: `xcodebuild … test` runs `ClipperTests` (store rules, kind detection, text transforms).
