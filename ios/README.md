# Vinyl for iOS

Native Swift and SwiftUI app, iOS 26 minimum, no third-party dependencies (see `docs/adr/0001`).
Plain Xcode project with synchronized folders: drop a file in `Vinyl/` or `VinylTests/` and it is built,
no project file edit needed.

| Path | What |
| --- | --- |
| `Vinyl/AppModel.swift` | The app model: the one object screens talk to |
| `Vinyl/Navigation.swift`, `Search.swift`, `Scan.swift` | The app model's navigation, Search and Scan state and actions |
| `Vinyl/DebugSeed.swift` | Debug builds only: the `-seedDiscs` launch argument (see below) |
| `Vinyl/Model/` | SwiftData `Disc`, the `Draft` value and its form rules, `DiscStore` (the Android DAO queries), and the pure rules screens read: Price, Vinyl color, Collection value, Collection filter, Profile name, cover caption, wheel, sleeve, tilt |
| `Vinyl/Catalog/` | The Catalog (Sources asked in order), its two Sources (Discogs, then MusicBrainz), `CatalogTransport` (the network seam, fake in tests) |
| `Config/` | `Vinyl.xcconfig` (app target build settings), `Secrets.example.xcconfig`, `Vinyl-Info.plist` |
| `Vinyl/UI/` | `Theme.swift` (Palette, Typography = Android `Type`), screens |
| `Vinyl/Fonts/` | Lexend, registered through `Config/Vinyl-Info.plist` (`UIAppFonts`) |
| `VinylTests/` | Swift Testing tests, hosted in the app; recorded Catalog JSON in `VinylTests/Fixtures/` |

## Discogs key and secret

The Catalog asks Discogs with the app's key and secret (the same ones as the Android app). They never go in git:

```sh
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig   # git-ignored
# then fill DISCOGS_KEY and DISCOGS_SECRET in Config/Secrets.xcconfig
```

`Config/Vinyl.xcconfig` includes `Secrets.xcconfig` when it exists, `Vinyl-Info.plist` passes the two build settings
to the app (`DiscogsKey`, `DiscogsSecret`), and `DiscogsCredentials.bundled` reads them. Without the file the app
builds and Catalog search still works, without covers and at 25 requests a minute instead of 60.
Rebuild after changing the file. Do not put `//` in a value: xcconfig reads it as a comment.

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

CI: `.github/workflows/ios.yml` runs the same test command on GitHub's `xcode-27` runner (Xcode 27.2, iPhone 17 simulator)
for pull requests and pushes to `main` that touch `ios/`. It needs no secrets: `Secrets.xcconfig` is optional and tests never
call the network.

## Seams for tests

Build the app model with an in-memory store and drive it like a screen does:

```swift
let app = AppModel(container: try DiscStore.inMemoryContainer(), catalogTransport: FakeTransport())
app.newDraft()
app.draft.title = "Kid A"
app.saveDraft()
#expect(app.collection.map(\.title) == ["Kid A"])
```

`catalogTransport` defaults to `URLSessionTransport()`; tests pass a fake conforming to `CatalogTransport`
(`VinylTests/FakeTransport.swift`, e.g. `FakeTransport(fixture: "discogs-search-ok-computer")`). Tests never touch
the real network. The app model asks both Sources, so tests that search or scan through it answer each Source
explicitly: `FakeTransport.network(discogs: FakeTransport.recorded("discogs-search-empty"), musicBrainz: ...)`.

The Catalog is a list of Sources asked in order (`Catalog.standard` in `Vinyl/Catalog/Catalog.swift`); any failure,
non-2xx status or timeout counts as empty and the next Source is asked. Test it directly:

```swift
let catalog = Catalog(sources: [DiscogsSource(transport: FakeTransport(fixture: "discogs-search-empty"), credentials: nil)])
#expect(await catalog.search("kid a").isEmpty)
```
