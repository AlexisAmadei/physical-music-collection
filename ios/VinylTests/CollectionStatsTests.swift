import Testing
@testable import Vinyl

/// What the Profile card shows. Port of the Android `CollectionStatsTest`, same cases.
struct CollectionStatsTests {
    func disc(
        _ format: Format = .vinyl, year: Int? = nil, color: VinylColor? = nil, paid: Int? = nil, wishlist: Bool = false
    ) -> Disc {
        Disc(Draft(year: year, format: format, wishlist: wishlist, paidPrice: paid, vinylColor: color))
    }

    @Test func countsFormatsColoredDiscsAndTheOldestYear() {
        let stats = CollectionStats([
            disc(.vinyl, year: 1994, color: .red, paid: 2500),
            disc(.vinyl, year: 1971),
            disc(.vinyl, color: .clear),
            disc(.cd, year: 1988, paid: 1000),
        ])
        #expect(stats == CollectionStats(vinyls: 3, cds: 1, colored: 2, oldestYear: 1971, value: 3500, unpriced: 2))
    }

    @Test func aCdKeepingAHiddenVinylColorIsNotColored() {
        #expect(CollectionStats([disc(.cd, color: .blue)]).colored == 0)
    }

    @Test func discsWithoutAYearAreIgnoredAndNoYearAtAllIsNil() {
        #expect(CollectionStats([disc(), disc(.cd)]).oldestYear == nil)
        #expect(CollectionStats([disc(), disc(year: 2001)]).oldestYear == 2001)
    }

    @Test func wishlistDiscsNeverCount() {
        let stats = CollectionStats([disc(year: 1950, color: .pink, paid: 900, wishlist: true)])
        #expect(stats == CollectionStats(vinyls: 0, cds: 0, colored: 0, oldestYear: nil, value: 0, unpriced: 0))
    }

    @Test func anEmptyCollectionIsAllZero() {
        #expect(CollectionStats([]) == CollectionStats(vinyls: 0, cds: 0, colored: 0, oldestYear: nil, value: 0, unpriced: 0))
    }
}
