import Testing
@testable import Vinyl

/// Draft rules of the Speed control (Android `SpeedTest`), driven through the app model like the Draft screen does.
@MainActor
struct DraftSpeedTests {
    let app: AppModel

    init() throws {
        app = try AppModel.pinned()
        app.newDraft()
        app.draft.title = "Currents"
    }

    @Test func aNewDraftHasNoSpeed() {
        #expect(app.draft.speed == nil)
        #expect(app.draft.shownSpeed == nil)
    }

    @Test func tappingTheSelectedSpeedClearsIt() {
        #expect((nil as Speed?).tapped(.rpm33) == .rpm33)
        #expect((Speed.rpm33 as Speed?).tapped(.rpm45) == .rpm45)
        #expect((Speed.rpm45 as Speed?).tapped(.rpm45) == nil)
    }

    @Test func aSpeedSetInTheFormIsSavedAndEditingItAgainFindsIt() throws {
        app.draft.speed = app.draft.speed.tapped(.rpm45)
        app.saveDraft()

        let saved = try #require(app.collection.first)
        #expect(saved.speed == .rpm45)
        #expect(saved.speedLabel(in: app.language) == "45 tr/min")

        app.edit(saved)
        #expect(app.draft.speed == .rpm45)
        app.draft.speed = app.draft.speed.tapped(.rpm33)
        app.saveDraft()
        #expect(app.collection.first?.speed == .rpm33)
        #expect(app.collection.first?.speedLabel(in: app.language) == "33 tr/min")
    }

    @Test func clearingTheSpeedRemovesIt() throws {
        app.draft.speed = .rpm33
        app.saveDraft()

        app.edit(try #require(app.collection.first))
        app.draft.speed = app.draft.speed.tapped(.rpm33)
        app.saveDraft()

        #expect(app.collection.first?.speed == nil)
        #expect(app.collection.first?.speedLabel(in: app.language) == nil)
    }

    @Test func vinylWithoutSpeedShowsNothing() {
        app.saveDraft()
        #expect(app.collection.first?.speedLabel(in: app.language) == nil)
    }

    @Test func aCDKeepsItsSpeedHiddenAndSwitchingBackToVinylRestoresIt() throws {
        app.draft.speed = .rpm45
        app.draft.format = .cd
        #expect(!app.draft.showsSpeedField)
        #expect(app.draft.shownSpeed == nil)
        app.saveDraft()

        let saved = try #require(app.collection.first)
        #expect(saved.speed == .rpm45)
        #expect(saved.shownSpeed == nil)
        #expect(saved.speedLabel(in: app.language) == nil)

        app.edit(saved)
        app.draft.format = .vinyl
        #expect(app.draft.showsSpeedField)
        #expect(app.draft.shownSpeed == .rpm45)
        app.saveDraft()
        #expect(app.collection.first?.speedLabel(in: app.language) == "45 tr/min")
    }

    @Test func speedShowsInTheCollectionAndInTheWishlist() {
        #expect(Disc(Draft(wishlist: false, speed: .rpm33)).speedLabel(in: app.language) == "33 tr/min")
        #expect(Disc(Draft(wishlist: true, speed: .rpm33)).speedLabel(in: app.language) == "33 tr/min")
    }

    @Test func speedReadsTrMinInFrenchAndRpmInEnglish() {
        let disc = Disc(Draft(speed: .rpm45))
        #expect(disc.speedLabel(in: app.language) == "45 tr/min")
        #expect(Speed.rpm33.label(in: app.language) == "33 tr/min")

        app.language.select(.english)
        #expect(disc.speedLabel(in: app.language) == "45 rpm")
        #expect(Speed.rpm33.label(in: app.language) == "33 rpm")
        #expect(Disc(Draft(format: .cd, speed: .rpm33)).speedLabel(in: app.language) == nil)
    }

    @Test func aWishlistDiscMovedToTheCollectionKeepsItsSpeed() throws {
        app.newDraft(wishlist: true)
        app.draft.title = "Currents"
        app.draft.speed = .rpm33
        app.saveDraft()

        let wished = try #require(app.wishlist.first)
        app.edit(wished)
        app.draft.wishlist = false
        app.saveDraft()
        #expect(app.collection.first?.speed == .rpm33)
    }

    @Test func aDraftPrefilledFromAScannedBarcodeHasNoSpeed() async throws {
        let transport = FakeTransport.network(
            discogs: FakeTransport.recorded("discogs-barcode-724385522918"),
            musicBrainz: FakeTransport.recorded("musicbrainz-search-empty")
        )
        let scanning = try AppModel(container: DiscStore.inMemoryContainer(), catalogTransport: transport)
        scanning.scan()

        await scanning.scanned("724385522918")

        #expect(scanning.draft.title == "OK Computer")
        #expect(scanning.draft.speed == nil)
    }

    @Test func aDraftPrefilledFromAPickedSearchResultHasNoSpeed() async throws {
        let transport = FakeTransport.network(
            discogs: FakeTransport.recorded("discogs-search-ok-computer"),
            musicBrainz: FakeTransport.recorded("musicbrainz-search-empty")
        )
        let searching = try AppModel(container: DiscStore.inMemoryContainer(), catalogTransport: transport)
        searching.select(.search)
        searching.searchState.text = "ok computer"
        await searching.searchCatalog()

        searching.pick(try #require(searching.searchState.catalogResults.first))

        #expect(searching.draft.title == "OK Computer")
        #expect(searching.draft.speed == nil)
    }
}
