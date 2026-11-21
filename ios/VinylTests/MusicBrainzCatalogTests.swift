import Foundation
import Testing
@testable import Vinyl

/// The Catalog with MusicBrainz as its Source, fed recorded MusicBrainz JSON through a fake network.
/// Fixtures were recorded from the MusicBrainz release search, trimmed to the fields that matter.
struct MusicBrainzCatalogTests {
    func catalog(_ transport: FakeTransport) -> Catalog {
        Catalog(sources: [MusicBrainzSource(transport: transport)])
    }

    func query(of transport: FakeTransport) -> [String: String] {
        let url = transport.requests.first?.url
        let items = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        return Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
    }

    /// MusicBrainz asks every client for a User-Agent naming the app and a contact (the same as on Android).
    @Test func searchAsksForFifteenReleasesAsJSONWithAUserAgent() async {
        let transport = FakeTransport(fixture: "musicbrainz-search-empty")
        _ = await catalog(transport).search("kid a")

        let request = transport.requests.first
        #expect(request?.url?.host() == "musicbrainz.org")
        #expect(request?.url?.path() == "/ws/2/release/")
        #expect(query(of: transport) == ["fmt": "json", "limit": "15", "query": "kid a"])
        #expect(request?.value(forHTTPHeaderField: "User-Agent")
            == "VinylCollectionApp/0.1 ( https://github.com )")
    }

    /// A scanner reads the 12-digit UPC "724385522918" as the EAN-13 "0724385522918": the Disc keeps what was scanned.
    @Test func barcodeLookupStampsTheScannedBarcodeOnEveryResult() async {
        let transport = FakeTransport(fixture: "musicbrainz-barcode-724385522918")
        let results = await catalog(transport).lookup(barcode: "0724385522918")

        #expect(results.map(\.title) == ["OK Computer", "OK Computer"])
        #expect(results.map(\.year) == [2008, 1997])
        #expect(results.map(\.barcode) == ["0724385522918", "0724385522918"])
        #expect(query(of: transport)["query"] == "barcode:0724385522918")
    }

    /// MusicBrainz says 503 when it is busy or rate limits (recorded body: `musicbrainz-busy`). A body holding valid
    /// results shows that the status alone makes it count as empty.
    @Test(arguments: ["musicbrainz-busy", "musicbrainz-search-ok-computer"])
    func busyAnswerCountsAsEmpty(body: String) async {
        let results = await catalog(FakeTransport(fixture: body, status: 503)).search("ok computer")

        #expect(results.isEmpty)
    }

    /// "Watch the Throne" is credited to "JAY‐Z" joined by " & " to "Kanye West", or "Dean Blunt" " Meets " "James Ferraro".
    @Test func catalogResultsHaveNoSpeed() async {
        let results = await catalog(FakeTransport(fixture: "musicbrainz-search-ok-computer")).search("ok computer")

        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.speed == nil })
    }

    @Test func artistIsJoinedFromTheArtistCreditsWithTheirJoinPhrases() async {
        let results = await catalog(FakeTransport(fixture: "musicbrainz-search-watch-the-throne")).search("watch the throne")

        #expect(results.map(\.title) == ["WATCH THE THRONE"] + Array(repeating: "Watch the Throne", count: 14))
        #expect(results.map(\.artist) == [
            "Jaeychino", "Eminem", "Dean Blunt Meets James Ferraro", "Warface", "JAŸ‐Z", "Jay‐Z & Kanye West",
            "JAY‐Z & Kanye West", "JAY Z & Kanye West", "Jay Z & Kanye West", "JAY‐Z & Kanye West", "JAY‐Z & Kanye West",
            "Jay‐Z & Kanye West", "Jay Z & Kanye West", "JAY‐Z & Kanye West", "JAY‐Z & Kanye West",
        ])
    }

    /// Dates come as "2011-08-12", "2011" or not at all.
    @Test func yearIsTheFirstFourCharactersOfTheDate() async {
        let results = await catalog(FakeTransport(fixture: "musicbrainz-search-watch-the-throne")).search("watch the throne")

        #expect(results.map(\.year) == [
            nil, 2013, 2012, 2024, 2011, 2011, 2011, 2011, 2012, 2011, nil, 2011, 2016, nil, nil,
        ])
    }

    /// Like Android, anything that is not a CD counts as vinyl: the recording holds "12\" Vinyl", "Cassette",
    /// "Digital Media", and "CD, CD, DVD-Video" box sets.
    @Test func formatIsCDWhenTheFirstMediumIsACDElseVinyl() async {
        let results = await catalog(FakeTransport(fixture: "musicbrainz-search-ok-computer")).search("ok computer")

        #expect(results.map(\.format) == [
            .vinyl, .cd, .cd, .cd, .cd, .cd, .cd, .cd, .vinyl, .vinyl, .vinyl, .vinyl, .cd, .vinyl, .cd,
        ])
    }

    @Test func textSearchResultsKeepTheReleaseBarcode() async {
        let results = await catalog(FakeTransport(fixture: "musicbrainz-search-watch-the-throne")).search("watch the throne")

        #expect(results.map(\.barcode) == [
            nil, "803341389786", nil, "8721093998594", "602527650579", nil, "00602527812557", "602527650579",
            "602527810829", "00602527812519", "00602527812526", "602527650579", "00602547790118", "602547790163",
            "00602527650593",
        ])
    }

    /// The cover is the Cover Art Archive front image for the release id; a release without art 404s to the placeholder.
    @Test func coverIsTheCoverArtArchiveFrontImageOfTheRelease() async {
        let results = await catalog(FakeTransport(fixture: "musicbrainz-search-ok-computer")).search("ok computer")

        #expect(results.count == 15)
        #expect(results.prefix(2).map(\.coverURL) == [
            URL(string: "https://coverartarchive.org/release/de3726da-05b8-4c1a-a19d-1bf53b7889ea/front-500"),
            URL(string: "https://coverartarchive.org/release/a736eb98-ba6b-3e42-ad80-a65f648910a3/front-500"),
        ])
    }
}
