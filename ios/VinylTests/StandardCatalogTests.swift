import Foundation
import Testing
@testable import Vinyl

/// The app's Catalog (`Catalog.standard`): Discogs first, MusicBrainz when Discogs finds nothing or fails.
/// One fake network answers both, by host, with recorded JSON.
struct StandardCatalogTests {
    typealias Answer = FakeTransport.Answer

    static func recorded(_ name: String, status: Int = 200) -> Answer { FakeTransport.recorded(name, status: status) }

    /// A network where Discogs answers `discogs` and MusicBrainz answers `musicBrainz`.
    static func network(
        discogs: @escaping Answer,
        musicBrainz: @escaping Answer = recorded("musicbrainz-search-ok-computer")
    ) -> FakeTransport {
        FakeTransport.network(discogs: discogs, musicBrainz: musicBrainz)
    }

    func catalog(_ network: FakeTransport, timeout: Duration = .seconds(8)) -> Catalog {
        var catalog = Catalog.standard(transport: network, discogs: nil)
        catalog.timeout = timeout
        return catalog
    }

    func hosts(_ network: FakeTransport) -> [String?] { network.requests.map { $0.url?.host() } }

    @Test func emptyDiscogsFallsBackToMusicBrainz() async {
        let network = Self.network(discogs: Self.recorded("discogs-search-empty"))
        let results = await catalog(network).search("ok computer")

        #expect(results.count == 15)
        #expect(results.first?.coverURL?.host() == "coverartarchive.org")
        #expect(hosts(network) == ["api.discogs.com", "musicbrainz.org"])
    }

    @Test func discogsAnswerWinsAndMusicBrainzIsNotAsked() async {
        let network = Self.network(discogs: Self.recorded("discogs-search-ok-computer"))
        let results = await catalog(network).search("ok computer")

        #expect(results.map(\.year) == [2016, 1997, 2017])
        #expect(hosts(network) == ["api.discogs.com"])
    }

    /// 429 is the Discogs rate limit; the bodies hold valid results, so only the status sends the Catalog on.
    @Test(arguments: [429, 401, 500])
    func discogsErrorStatusFallsBackToMusicBrainz(status: Int) async {
        let network = Self.network(discogs: Self.recorded("discogs-search-ok-computer", status: status))
        let results = await catalog(network).search("ok computer")

        #expect(results.count == 15)
        #expect(hosts(network) == ["api.discogs.com", "musicbrainz.org"])
    }

    @Test func discogsNetworkErrorFallsBackToMusicBrainz() async {
        let network = Self.network(discogs: { _ in throw URLError(.cannotConnectToHost) })
        let results = await catalog(network).search("ok computer")

        #expect(results.count == 15)
    }

    /// Discogs gives up after the timeout (8 s in the app, shortened here) and MusicBrainz answers.
    @Test func slowDiscogsFallsBackToMusicBrainz() async {
        let network = Self.network(discogs: { request in
            try await Task.sleep(for: .seconds(60))
            return (Fixture.data("discogs-search-ok-computer"), .ok(request))
        })
        let clock = ContinuousClock()
        let start = clock.now
        let results = await catalog(network, timeout: .milliseconds(200)).search("ok computer")

        #expect(results.count == 15)
        #expect(clock.now - start < .seconds(5))
    }

    @Test func barcodeLookupFallsBackToMusicBrainz() async {
        let network = Self.network(
            discogs: Self.recorded("discogs-search-empty"),
            musicBrainz: Self.recorded("musicbrainz-barcode-724385522918")
        )
        let results = await catalog(network).lookup(barcode: "724385522918")

        #expect(results.map(\.title) == ["OK Computer", "OK Computer"])
        #expect(results.map(\.barcode) == ["724385522918", "724385522918"])
        #expect(hosts(network) == ["api.discogs.com", "musicbrainz.org"])
    }

    @Test func neitherSourceFindingAnythingGivesNothing() async {
        let network = Self.network(
            discogs: Self.recorded("discogs-search-empty"),
            musicBrainz: Self.recorded("musicbrainz-search-empty")
        )

        #expect(await catalog(network).search("zzzz").isEmpty)
        #expect(await catalog(network).lookup(barcode: "9999999999990").isEmpty)
    }
}
