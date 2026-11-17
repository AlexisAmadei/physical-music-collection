import Foundation
import Testing
@testable import Vinyl

/// The Search screen through the app model: "My discs", "Search catalog" and picking a Catalog result.
@MainActor
struct SearchTests {
    func app(_ transport: FakeTransport = FakeTransport(fixture: "discogs-search-ok-computer")) throws -> AppModel {
        try AppModel(container: DiscStore.inMemoryContainer(), catalogTransport: transport)
    }

    func add(_ title: String, by artist: String, wishlist: Bool = false, to app: AppModel) {
        app.newDraft(wishlist: wishlist)
        app.draft.title = title
        app.draft.artist = artist
        app.saveDraft()
    }

    @Test func myDiscsAreTheDiscsWhoseTitleOrArtistContainsTheText() throws {
        let app = try app()
        add("OK Computer", by: "Radiohead", to: app)
        add("Homogenic", by: "Björk", wishlist: true, to: app)
        add("Radio Ga Ga", by: "Queen", to: app)
        add("Discovery", by: "Daft Punk", to: app)

        app.searchState.text = "radio"
        #expect(app.myDiscs.map(\.title) == ["Radio Ga Ga", "OK Computer"])

        app.searchState.text = "BJÖRK"
        #expect(app.myDiscs.map(\.title) == ["Homogenic"])
    }

    @Test func blankTextShowsNoDiscs() throws {
        let app = try app()
        add("OK Computer", by: "Radiohead", to: app)

        app.searchState.text = "  "
        #expect(app.myDiscs.isEmpty)
    }

    @Test func searchCatalogShowsTheCatalogResults() async throws {
        let transport = FakeTransport(fixture: "discogs-search-ok-computer")
        let app = try app(transport)

        app.searchState.text = "ok computer"
        await app.searchCatalog()

        #expect(app.searchState.catalogResults.map(\.title) == ["OK Computer", "OK Computer", "OK Computer OKNOTOK 1997 2017"])
        #expect(transport.requests.first?.url?.host() == "api.discogs.com")
    }

    @Test func searchCatalogIsDisabledForBlankText() async throws {
        let transport = FakeTransport(fixture: "discogs-search-ok-computer")
        let app = try app(transport)

        #expect(!app.searchState.canSearchCatalog)
        app.searchState.text = " \n"
        #expect(!app.searchState.canSearchCatalog)
        await app.searchCatalog()
        #expect(transport.requests.isEmpty)

        app.searchState.text = "kid a"
        #expect(app.searchState.canSearchCatalog)
    }

    @Test func searchCatalogIsDisabledWhileSearching() async throws {
        let (opened, open) = AsyncStream.makeStream(of: Void.self)
        let transport = FakeTransport { request in
            for await _ in opened { break }
            return (Fixture.data("discogs-search-ok-computer"), .ok(request))
        }
        let app = try app(transport)
        app.searchState.text = "ok computer"

        let search = Task { await app.searchCatalog() }
        while !app.searchState.isSearchingCatalog { await Task.yield() }
        #expect(!app.searchState.canSearchCatalog)

        open.yield()
        await search.value
        #expect(!app.searchState.isSearchingCatalog)
        #expect(app.searchState.canSearchCatalog)
        #expect(app.searchState.catalogResults.count == 3)
    }

    @Test func pickingACatalogResultOpensItsPrefilledDraft() async throws {
        let app = try app(FakeTransport(fixture: "discogs-search-ok-computer"))
        app.select(.search)
        app.searchState.text = "ok computer"
        await app.searchCatalog()

        app.pick(app.searchState.catalogResults[1])

        #expect(app.path == [.draft])
        #expect(app.draft.isNew)
        #expect(app.draft.title == "OK Computer")
        #expect(app.draft.artist == "Radiohead")
        #expect(app.draft.year == 1997)
        #expect(app.draft.format == .cd)

        app.saveDraft()
        #expect(app.collection.map(\.title) == ["OK Computer"])
    }
    /// Android makes a fresh Search entry each time: the nav pill and "Rechercher un album" open Search blank.
    @Test(arguments: [false, true])
    func searchOpensBlankEachTimeItIsEntered(fromAddChoices: Bool) async throws {
        let app = try app()
        app.select(.search)
        app.searchState.text = "ok computer"
        await app.searchCatalog()
        app.select(.home)

        if fromAddChoices { app.choose(.search) } else { app.select(.search) }

        #expect(app.tab == .search)
        #expect(app.searchState == SearchState())
    }

    @Test func goingBackFromAPickedResultKeepsTheSearch() async throws {
        let app = try app()
        app.select(.search)
        app.searchState.text = "ok computer"
        await app.searchCatalog()

        app.pick(app.searchState.catalogResults[0])
        app.back()

        #expect(app.searchState.text == "ok computer")
        #expect(app.searchState.catalogResults.count == 3)
    }
}
