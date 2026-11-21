import Foundation
import Testing
@testable import Vinyl

/// The Catalog with Discogs as its Source, fed recorded Discogs JSON through a fake network.
/// Fixtures were recorded from the Discogs search API without a key (so no covers), trimmed to the fields that matter.
struct DiscogsCatalogTests {
    func catalog(_ transport: FakeTransport, credentials: DiscogsCredentials? = nil) -> Catalog {
        Catalog(sources: [DiscogsSource(transport: transport, credentials: credentials)])
    }

    @Test func textSearchGivesOnePressingPerAlbumAndFormat() async {
        let results = await catalog(FakeTransport(fixture: "discogs-search-ok-computer")).search("ok computer")

        #expect(results.map(\.title) == ["OK Computer", "OK Computer", "OK Computer OKNOTOK 1997 2017"])
        #expect(results.map(\.artist) == ["Radiohead", "Radiohead", "Radiohead"])
        #expect(results.map(\.format) == [.vinyl, .cd, .vinyl])
        #expect(results.map(\.year) == [2016, 1997, 2017])
    }

    /// The keyless recording with covers filled in the way Discogs sends them with a key: the first vinyl Pressing has
    /// the spacer placeholder, the next two have covers; the first CD has none, the second has one.
    @Test func keptPressingIsTheFirstWithACoverIgnoringTheSpacer() async {
        let results = await catalog(FakeTransport(fixture: "discogs-search-ok-computer-covers")).search("ok computer")

        #expect(results.map(\.format) == [.vinyl, .cd])
        #expect(results.map(\.year) == [2008, 1997])
        #expect(results.map(\.coverURL) == [
            URL(string: "https://i.discogs.com/vinyl-2008/rs:fit/g:sm/q:90/h:600/w:600/R-1587168.jpeg"),
            URL(string: "https://i.discogs.com/cd-1997/rs:fit/g:sm/q:90/h:600/w:600/R-83182.jpeg"),
        ])
    }

    @Test func catalogResultsHaveNoSpeed() async {
        let results = await catalog(FakeTransport(fixture: "discogs-search-ok-computer")).search("ok computer")

        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.speed == nil })
    }

    @Test func withoutAnyCoverTheFirstPressingIsKeptWithNoCover() async {
        let results = await catalog(FakeTransport(fixture: "discogs-search-ok-computer")).search("ok computer")

        #expect(results.map(\.coverURL) == [nil, nil, nil])
        #expect(results.map(\.year) == [2016, 1997, 2017])
    }

    @Test func barcodeLookupStampsTheBarcodeOnEveryResult() async {
        let transport = FakeTransport(fixture: "discogs-barcode-724385522918")
        let results = await catalog(transport).lookup(barcode: "724385522918")

        #expect(results.map(\.title) == ["OK Computer"])
        #expect(results.map(\.barcode) == ["724385522918"])
        #expect(query(of: transport)["barcode"] == "724385522918")
    }

    @Test func searchAsksForReleasesThirtyPerPage() async {
        let transport = FakeTransport(fixture: "discogs-search-empty")
        _ = await catalog(transport).search("kid a")

        let request = transport.requests.first
        #expect(request?.url?.host() == "api.discogs.com")
        #expect(request?.url?.path() == "/database/search")
        #expect(query(of: transport) == ["type": "release", "per_page": "30", "q": "kid a"])
    }

    @Test func withAKeyTheRequestCarriesKeyAndSecret() async {
        let transport = FakeTransport(fixture: "discogs-search-empty")
        _ = await catalog(transport, credentials: DiscogsCredentials(key: "the-key", secret: "the-secret")).search("kid a")

        let request = transport.requests.first
        #expect(request?.value(forHTTPHeaderField: "Authorization") == "Discogs key=the-key, secret=the-secret")
        #expect(request?.value(forHTTPHeaderField: "User-Agent") == "VinylCollectionApp/0.1")
    }

    @Test(arguments: [nil, DiscogsCredentials(key: "", secret: "")])
    func withoutAKeyNoAuthorizationIsSent(credentials: DiscogsCredentials?) async {
        let transport = FakeTransport(fixture: "discogs-search-empty")
        _ = await catalog(transport, credentials: credentials).search("kid a")

        let request = transport.requests.first
        #expect(request?.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(request?.value(forHTTPHeaderField: "User-Agent") == "VinylCollectionApp/0.1")
    }

    /// The app reads them from its Info.plist, filled from the git-ignored Secrets.xcconfig (empty without it).
    @Test func credentialsComeFromTheInfoPlistOnlyWithAKey() {
        #expect(DiscogsCredentials.from(["DiscogsKey": "k", "DiscogsSecret": "s"]) == DiscogsCredentials(key: "k", secret: "s"))
        #expect(DiscogsCredentials.from(["DiscogsKey": "", "DiscogsSecret": ""]) == nil)
        #expect(DiscogsCredentials.from([:]) == nil)
    }

    func query(of transport: FakeTransport) -> [String: String] {
        let url = transport.requests.first?.url
        let items = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        return Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
    }

    /// The recording holds 21 different albums.
    @Test func atMostFifteenPressingsComeBack() async {
        let results = await catalog(FakeTransport(fixture: "discogs-search-greatest-hits")).search("greatest hits")

        #expect(results.map(\.artist) == [
            "Queen", "Tom Petty & The Heartbreakers", "Elton John", "The Doors", "Foo Fighters", "Queen", "ABBA",
            "Fleetwood Mac", "The Cure", "Leonard Cohen", "Sly & The Family Stone", "Cat Stevens", "Guns N' Roses",
            "ABBA", "The Police",
        ])
    }

    /// The recording holds a cassette and a FLAC file next to the CDs and LPs.
    @Test func onlyCDAndVinylReleasesComeBack() async {
        let results = await catalog(FakeTransport(fixture: "discogs-search-nirvana-local-anaesthetic")).search("nirvana local anaesthetic")

        #expect(results.map(\.title) == [
            "Local Anaesthetic", "Local Anaesthetic", "Local Anaesthetic = 涅槃", "Local Anaesthetic = 局部麻酔",
            "Black Flower (To Markos III) + Local Anaesthetic", "Songlife", "The Show Must Go On",
        ])
        #expect(results.map(\.format) == [.vinyl, .cd, .vinyl, .cd, .cd, .vinyl, .cd])
    }

    @Test func artistLosesDiscogsNumberAndVariationMarks() async {
        let results = await catalog(FakeTransport(fixture: "discogs-search-nirvana-local-anaesthetic")).search("nirvana local anaesthetic")

        #expect(results.map(\.artist) == [
            "Nirvana", "Nirvana", "Nirvana  =  ニアヴァーナ", "Nirvana  =  ニルヴァーナ", "Nirvana", "Nirvana", "Nirvana",
        ])
    }
}
