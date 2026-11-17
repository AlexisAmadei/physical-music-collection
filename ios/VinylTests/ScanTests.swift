import Foundation
import Testing
@testable import Vinyl

/// The Scan screen through the app model: a read barcode is looked up in the Catalog and lands on a Draft or on Search.
@MainActor
struct ScanTests {
    func app(_ transport: FakeTransport) throws -> AppModel {
        try AppModel(container: DiscStore.inMemoryContainer(), catalogTransport: transport)
    }

    /// The Catalog knows OK Computer by this barcode.
    var hit: FakeTransport { FakeTransport(fixture: "discogs-barcode-724385522918") }
    /// No Source knows the barcode.
    var miss: FakeTransport { FakeTransport(fixture: "discogs-search-empty") }

    @Test func aKnownBarcodeOpensADraftPrefilledFromTheFirstResultWithTheBarcode() async throws {
        let app = try app(hit)
        app.select(.collection)
        app.scan()

        await app.scanned("724385522918")

        #expect(app.path == [.draft])
        #expect(app.tab == .collection)
        #expect(app.draft.isNew)
        #expect(app.draft.title == "OK Computer")
        #expect(app.draft.artist == "Radiohead")
        #expect(app.draft.barcode == "724385522918")
    }

    /// A hit that waits until the test lets it answer.
    func heldHit() -> (FakeTransport, AsyncStream<Void>.Continuation) {
        let (opened, open) = AsyncStream.makeStream(of: Void.self)
        let transport = FakeTransport { request in
            for await _ in opened { break }
            return (Fixture.data("discogs-barcode-724385522918"), .ok(request))
        }
        return (transport, open)
    }

    @Test func theFirstBarcodeReadStopsScanningAndIsLookedUp() async throws {
        let (transport, open) = heldHit()
        let app = try app(transport)
        app.scan()
        #expect(app.scanState == .scanning)

        let lookup = Task { await app.scanned("724385522918") }
        while transport.requests.isEmpty { await Task.yield() }
        #expect(app.scanState == .lookingUp("724385522918"))

        await app.scanned("5099902987026")
        #expect(app.scanState == .lookingUp("724385522918"))

        open.yield()
        await lookup.value
        #expect(transport.requests.count == 1)
        #expect(app.path == [.draft])
        #expect(app.draft.barcode == "724385522918")
    }

    @Test func openingScanAgainScansAfresh() async throws {
        let app = try app(hit)
        app.scan()
        await app.scanned("724385522918")
        app.back()

        app.scan()

        #expect(app.scanState == .scanning)
    }

    @Test func enterManuallyBeforeAnyBarcodeOpensAnEmptyDraft() throws {
        let app = try app(hit)
        app.select(.wishlist)
        app.scan()

        app.enterManually()

        #expect(app.path == [.draft])
        #expect(app.draft.isNew)
        #expect(app.draft.title.isEmpty)
        #expect(app.draft.barcode == nil)
        #expect(!app.draft.wishlist)
    }

    @Test func enterManuallyDuringALookupOpensADraftWithTheBarcodeAndTheLookupIsDropped() async throws {
        let (transport, open) = heldHit()
        let app = try app(transport)
        app.scan()
        let lookup = Task { await app.scanned("724385522918") }
        while transport.requests.isEmpty { await Task.yield() }

        app.enterManually()
        app.draft.title = "Typed by hand"
        open.yield()
        await lookup.value

        #expect(app.path == [.draft])
        #expect(app.draft.title == "Typed by hand")
        #expect(app.draft.barcode == "724385522918")
    }

    @Test func leavingScanDuringALookupDropsIt() async throws {
        let (transport, open) = heldHit()
        let app = try app(transport)
        app.select(.collection)
        app.scan()
        let lookup = Task { await app.scanned("724385522918") }
        while transport.requests.isEmpty { await Task.yield() }

        app.back()
        open.yield()
        await lookup.value

        #expect(app.path.isEmpty)
        #expect(app.tab == .collection)
    }

    @Test func anUnknownBarcodeReplacesScanWithSearchSayingItWasNotFound() async throws {
        let app = try app(miss)
        app.select(.collection)
        app.searchState.text = "earlier search"
        app.scan()

        await app.scanned("0000000000000")

        #expect(app.path.isEmpty)
        #expect(app.tab == .search)
        #expect(app.searchState.notFound == "0000000000000")
        #expect(app.searchState.text.isEmpty)
        #expect(app.searchState.catalogResults.isEmpty)
    }

    /// The barcode lookup misses, then the text search finds OK Computer.
    var missThenTextHit: FakeTransport {
        FakeTransport { request in
            let byBarcode = request.url?.query()?.contains("barcode=") == true
            return (Fixture.data(byBarcode ? "discogs-search-empty" : "discogs-search-ok-computer"), .ok(request))
        }
    }

    @Test func aCatalogResultPickedAfterAnUnknownBarcodeKeepsTheScannedBarcode() async throws {
        let app = try app(missThenTextHit)
        app.scan()
        await app.scanned("0000000000000")
        app.searchState.text = "ok computer"
        await app.searchCatalog()

        app.pick(app.searchState.catalogResults[1])

        #expect(app.path == [.draft])
        #expect(app.draft.title == "OK Computer")
        #expect(app.draft.format == .cd)
        #expect(app.draft.barcode == "0000000000000")
        app.saveDraft()
        #expect(app.collection.map(\.barcode) == ["0000000000000"])
    }

    @Test func aCatalogResultPickedOnAPlainSearchKeepsItsOwnBarcode() async throws {
        let app = try app(missThenTextHit)
        app.scan()
        await app.scanned("0000000000000")
        app.select(.home)
        app.select(.search)
        #expect(app.searchState.notFound == nil)

        app.searchState.text = "ok computer"
        await app.searchCatalog()
        let result = app.searchState.catalogResults[1]
        app.pick(result)

        #expect(app.draft.barcode == result.barcode)
    }

    @Test func addManuallyAfterAnUnknownBarcodeOpensADraftWithTheBarcodeAndTheTypedTitle() async throws {
        let app = try app(miss)
        app.scan()
        await app.scanned("0000000000000")
        app.searchState.text = "Live at the Cave"

        app.addManually()

        #expect(app.path == [.draft])
        #expect(app.draft.isNew)
        #expect(app.draft.title == "Live at the Cave")
        #expect(app.draft.artist.isEmpty)
        #expect(app.draft.barcode == "0000000000000")
        #expect(!app.draft.wishlist)
    }
}
