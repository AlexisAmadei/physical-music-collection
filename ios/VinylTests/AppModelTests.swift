import Testing
@testable import Vinyl

@MainActor
struct AppModelTests {
    let app: AppModel

    init() throws {
        app = try AppModel(container: DiscStore.inMemoryContainer())
    }

    /// Fills and saves a new Draft the way the Draft screen does.
    func add(_ title: String, by artist: String, year: Int? = nil, wishlist: Bool = false) {
        app.newDraft(wishlist: wishlist)
        app.draft.title = title
        app.draft.artist = artist
        app.draft.year = year
        app.saveDraft()
    }

    @Test func savedDraftShowsInTheCollectionInStoreOrder() {
        add("OK Computer", by: "radiohead", year: 1997)
        add("Kid A", by: "Radiohead", year: 2000)
        add("Discovery", by: "Daft Punk", year: 2001)
        add("Pablo Honey", by: "Radiohead", year: 1993)

        #expect(app.collection.map(\.title) == ["Discovery", "Pablo Honey", "OK Computer", "Kid A"])
        #expect(app.wishlist.isEmpty)
    }

    @Test func wishlistDraftGoesToTheWishlistOnly() {
        add("Homogenic", by: "Björk", wishlist: true)
        add("Debut", by: "Björk")

        #expect(app.wishlist.map(\.title) == ["Homogenic"])
        #expect(app.collection.map(\.title) == ["Debut"])
    }

    @Test func editingASavedDiscUpdatesItInPlace() throws {
        add("Kid A", by: "Radiohead", year: 2000)
        let disc = try #require(app.collection.first)

        app.edit(disc)
        #expect(app.draft.title == "Kid A")
        #expect(!app.draft.isNew)
        app.draft.title = "Amnesiac"
        app.draft.year = 2001
        app.draft.barcodeText = "0724353276420"
        app.draft.tapStar(4)
        app.draft.comment = "Pyramid Song"
        app.saveDraft()

        #expect(app.collection.map(\.title) == ["Amnesiac"])
        let saved = try #require(app.collection.first)
        #expect(saved.year == 2001)
        #expect(saved.barcode == "0724353276420")
        #expect(saved.rating == 4)
        #expect(saved.comment == "Pyramid Song")
    }

    @Test func deletingTheEditedDiscRemovesIt() throws {
        add("Kid A", by: "Radiohead")
        add("Debut", by: "Björk")

        app.edit(try #require(app.collection.first { $0.title == "Kid A" }))
        app.deleteDraft()

        #expect(app.collection.map(\.title) == ["Debut"])
    }

    @Test func saveIsRefusedWithoutATitle() {
        app.newDraft()
        app.draft.artist = "Radiohead"
        #expect(!app.canSaveDraft)
        app.saveDraft()
        app.draft.title = "   "
        #expect(!app.canSaveDraft)
        app.saveDraft()

        #expect(app.collection.isEmpty)
        app.draft.title = "Kid A"
        #expect(app.canSaveDraft)
    }

    @Test func tappingAStarRatesAndTappingTheCurrentStarClears() {
        app.newDraft()
        #expect(app.draft.rating == 0)
        app.draft.tapStar(4)
        #expect(app.draft.rating == 4)
        app.draft.tapStar(2)
        #expect(app.draft.rating == 2)
        app.draft.tapStar(2)
        #expect(app.draft.rating == 0)
    }

    @Test func yearTakesDigitsOnly() {
        app.newDraft()
        app.draft.yearText = "1997"
        #expect(app.draft.year == 1997)
        app.draft.yearText = "1997x"
        #expect(app.draft.year == 1997)
        #expect(app.draft.yearText == "1997")
        app.draft.yearText = "-20"
        #expect(app.draft.year == 20)
        app.draft.yearText = "abc"
        #expect(app.draft.year == nil)
        #expect(app.draft.yearText == "")
    }

    @Test func blankBarcodeMeansNoBarcode() {
        app.newDraft()
        app.draft.barcodeText = "0724384260927"
        #expect(app.draft.barcode == "0724384260927")
        app.draft.barcodeText = "  "
        #expect(app.draft.barcode == nil)
        #expect(app.draft.barcodeText == "")
    }

    @Test func searchFindsMyDiscsByTitleOrArtistOrderedByArtist() {
        add("Radio Ga Ga", by: "Queen")
        add("OK Computer", by: "Radiohead")
        add("Debut", by: "Björk")
        add("Homogenic", by: "Björk", wishlist: true)
        add("Radio", by: "ABBA", wishlist: true)

        #expect(app.search("radio").map(\.title) == ["Radio", "Radio Ga Ga", "OK Computer"])
        #expect(app.search("björk").map(\.title).sorted() == ["Debut", "Homogenic"])
    }
}
