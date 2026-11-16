import Testing
@testable import Vinyl

/// Navigation through the app model, the way the nav pill, the glass buttons and the add choices drive it.
@MainActor
struct NavigationTests {
    let app: AppModel

    init() throws {
        app = try AppModel(container: DiscStore.inMemoryContainer())
    }

    @Test func startsOnHomeAtASingleLevelWithTheChromeShown() {
        #expect(app.tab == .home)
        #expect(app.path.isEmpty)
        #expect(app.showsChrome)
    }

    @Test func scanOpensTheScanScreenOverTheMainScreenAndHidesTheChrome() {
        app.select(.collection)
        app.scan()

        #expect(app.tab == .collection)
        #expect(app.path == [.scan])
        #expect(!app.showsChrome)
    }

    @Test func switchingScreensAlwaysLandsOnASingleLevel() {
        app.scan()
        app.select(.wishlist)

        #expect(app.tab == .wishlist)
        #expect(app.path.isEmpty)
        #expect(app.showsChrome)
    }

    @Test func plusOnTheWishlistOpensAnEmptyWishlistDraft() {
        app.select(.wishlist)
        app.draft.title = "Left over"

        #expect(!app.plusOffersChoices)
        app.addToWishlist()

        #expect(app.path == [.draft])
        #expect(app.draft.isNew)
        #expect(app.draft.title.isEmpty)
        #expect(app.draft.wishlist)
    }

    @Test(arguments: [Tab.home, .collection, .search, .profile])
    func plusOffersTheAddChoicesOnTheOtherMainScreens(tab: Tab) {
        app.select(tab)
        #expect(app.plusOffersChoices)
    }

    @Test func manualEntryOpensAnEmptyCollectionDraft() {
        app.select(.collection)
        app.draft.title = "Left over"
        app.draft.wishlist = true

        app.choose(.manual)

        #expect(app.path == [.draft])
        #expect(app.draft.isNew)
        #expect(app.draft.title.isEmpty)
        #expect(!app.draft.wishlist)
    }

    @Test func scanChoiceOpensTheScanScreen() {
        app.choose(.scan)
        #expect(app.path == [.scan])
    }

    /// Search is also a nav pill screen (as on Android), so the choice lands on it like the pill does.
    @Test func searchChoiceShowsTheSearchScreenAtASingleLevel() {
        app.select(.profile)
        app.choose(.search)

        #expect(app.tab == .search)
        #expect(app.path.isEmpty)
        #expect(app.showsChrome)
    }

    @Test func savingADraftGoesBackWhereItCameFrom() {
        app.select(.collection)
        app.choose(.manual)
        app.draft.title = "Kid A"
        app.saveDraft()
        app.back()

        #expect(app.tab == .collection)
        #expect(app.path.isEmpty)
        #expect(app.collection.map(\.title) == ["Kid A"])
    }
}
