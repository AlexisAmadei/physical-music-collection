# Vinyl for iOS

Native Swift and SwiftUI app, iOS 26 minimum, no third-party dependencies (see `docs/adr/0001`).
Plain Xcode project with synchronized folders: drop a file in `Vinyl/` or `VinylTests/` and it is built,
no project file edit needed.

| Path | What |
| --- | --- |
| `Vinyl/AppModel.swift` | The app model: the one object screens talk to |
| `Vinyl/Model/` | SwiftData `Disc`, the `Draft` value, `DiscStore` (the Android DAO queries) |
| `Vinyl/Catalog/` | `CatalogTransport`: the network seam the Catalog uses (fake in tests) |
| `Vinyl/UI/` | `Theme.swift` (Palette, Typography = Android `Type`), screens |
| `Vinyl/Fonts/` | Lexend, registered through `Config/Vinyl-Info.plist` (`UIAppFonts`) |
| `VinylTests/` | Swift Testing tests, hosted in the app |

## Commands

Run from `ios/`. Simulator commands need CoreSimulator, so in a Claude Code sandbox run them with the sandbox disabled.
Derived data goes to `ios/build/DerivedData` (git-ignored), so parallel worktrees never share a build.

Build (no simulator needed):

```sh
xcodebuild build -project Vinyl.xcodeproj -scheme Vinyl \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO -quiet
```

Test, on your own simulator (create once, delete when done):

```sh
UDID=$(xcrun simctl create vinyl-tN "iPhone 17")
xcodebuild test -project Vinyl.xcodeproj -scheme Vinyl \
  -destination "id=$UDID" \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO -quiet
xcrun simctl delete "$UDID"
```

One test or suite: add `-only-testing:VinylTests/AppModelTests` (or `.../AppModelTests/savedDraftShowsInTheCollectionInStoreOrder()`).

Large Collection, debug builds only: `xcrun simctl launch "$UDID" dev.kiwi.vinyl -seedDiscs 240` opens the app on an
in-memory store with 240 generated Collection Discs (`Vinyl/DebugSeed.swift`, not compiled into release). The real store is untouched.

If `xcrun simctl list runtimes` shows no iOS runtime, install it with `xcodebuild -downloadPlatform iOS`.

## Seams for tests

Build the app model with an in-memory store and drive it like a screen does:

```swift
let app = AppModel(container: try DiscStore.inMemoryContainer(), catalogTransport: FakeTransport())
app.newDraft()
app.draft.title = "Kid A"
app.saveDraft()
#expect(app.collection.map(\.title) == ["Kid A"])
```

`catalogTransport` defaults to `URLSessionTransport()`; tests pass a fake conforming to `CatalogTransport`.
