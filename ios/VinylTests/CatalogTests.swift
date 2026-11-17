import Foundation
import Testing
@testable import Vinyl

/// The Catalog asks its Sources in order, the first non-empty answer wins, and any failure counts as empty.
/// Two Discogs Sources on separate fake networks stand for "first Source" and "next Source".
struct CatalogTests {
    let next = FakeTransport(fixture: "discogs-search-ok-computer")

    func catalog(first: FakeTransport, timeout: Duration = .seconds(8)) -> Catalog {
        Catalog(
            sources: [DiscogsSource(transport: first, credentials: nil), DiscogsSource(transport: next, credentials: nil)],
            timeout: timeout
        )
    }

    @Test func firstSourceWithAnAnswerWins() async {
        let first = FakeTransport(fixture: "discogs-search-nirvana-local-anaesthetic")
        let results = await catalog(first: first).search("nirvana")

        #expect(results.first?.artist == "Nirvana")
        #expect(next.requests.isEmpty)
    }

    @Test func emptyAnswerAsksTheNextSource() async {
        let results = await catalog(first: FakeTransport(fixture: "discogs-search-empty")).search("ok computer")

        #expect(results.first?.title == "OK Computer")
        #expect(next.requests.count == 1)
    }

    /// The error bodies hold valid JSON results, so only the status tells them apart.
    @Test(arguments: [401, 429, 500])
    func errorStatusCountsAsEmpty(status: Int) async {
        let first = FakeTransport(fixture: "discogs-search-nirvana-local-anaesthetic", status: status)
        let results = await catalog(first: first).search("ok computer")

        #expect(results.first?.title == "OK Computer")
    }

    @Test func badJSONCountsAsEmpty() async {
        let first = FakeTransport { request in (Data("<html>Service Unavailable</html>".utf8), .ok(request)) }
        let results = await catalog(first: first).search("ok computer")

        #expect(results.first?.title == "OK Computer")
    }

    @Test func networkErrorCountsAsEmpty() async {
        let first = FakeTransport { _ in throw URLError(.notConnectedToInternet) }
        let results = await catalog(first: first).search("ok computer")

        #expect(results.first?.title == "OK Computer")
    }

    /// A Source that never answers gives up after the timeout (8 s in the app, shortened here).
    @Test func slowSourceGivesUpAndTheNextIsAsked() async {
        let first = FakeTransport { request in
            try await Task.sleep(for: .seconds(60))
            return (Fixture.data("discogs-search-nirvana-local-anaesthetic"), .ok(request))
        }
        let clock = ContinuousClock()
        let start = clock.now
        let results = await catalog(first: first, timeout: .milliseconds(200)).search("ok computer")

        #expect(results.first?.title == "OK Computer")
        // Far below the 60 s the slow Source sleeps, yet loose enough for a loaded CI runner.
        #expect(clock.now - start < .seconds(30))
    }

    @Test func noSourceWithAnAnswerGivesNothing() async {
        let catalog = Catalog(sources: [
            DiscogsSource(transport: FakeTransport(fixture: "discogs-search-empty"), credentials: nil),
            DiscogsSource(transport: FakeTransport(fixture: "discogs-search-ok-computer", status: 429), credentials: nil),
        ])

        #expect(await catalog.search("ok computer").isEmpty)
        #expect(await catalog.lookup(barcode: "0000000000000").isEmpty)
    }
}
