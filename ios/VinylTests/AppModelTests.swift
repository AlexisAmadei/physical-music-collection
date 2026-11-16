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
        app.saveDraft()

        #expect(app.collection.map(\.title) == ["Amnesiac"])
        #expect(app.collection.first?.year == 2001)
    }

    @Test func deletingTheEditedDiscRemovesIt() throws {
        add("Kid A", by: "Radiohead")
        add("Debut", by: "Björk")

        app.edit(try #require(app.collection.first { $0.title == "Kid A" }))
        app.deleteDraft()

        #expect(app.collection.map(\.title) == ["Debut"])
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
