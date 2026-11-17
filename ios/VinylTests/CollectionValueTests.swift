import Testing
@testable import Vinyl

/// Collection value, tested directly on Discs (spec #2, seam 3). Port of the Android `collectionValue` cases.
struct CollectionValueTests {
    func disc(_ format: Format, paid: Int? = nil, seen: Int? = nil, wishlist: Bool = false) -> Disc {
        Disc(Draft(format: format, wishlist: wishlist, seenPrice: seen, paidPrice: paid))
    }

    /// Android `PriceTest.collectionValueSkipsWishlistAndCountsUnpriced`.
    @Test func collectionValueSkipsWishlistAndCountsUnpriced() {
        let value = CollectionValue([
            disc(.cd, paid: 1000),
            disc(.vinyl, paid: 2550),
            disc(.vinyl),
            disc(.vinyl, paid: 9999, seen: 3000, wishlist: true),
        ])
        #expect(value == CollectionValue(total: 3550, cd: 1000, vinyl: 2550, unpriced: 1))
    }

    @Test func noDiscsAreWorthNothing() {
        #expect(CollectionValue([]) == CollectionValue(total: 0, cd: 0, vinyl: 0, unpriced: 0))
    }

    @Test func aWishlistOnlyIsWorthNothingAndHasNothingUnpriced() {
        let value = CollectionValue([disc(.cd, wishlist: true), disc(.vinyl, seen: 1500, wishlist: true)])
        #expect(value == CollectionValue(total: 0, cd: 0, vinyl: 0, unpriced: 0))
    }

    /// The Seen price of an owned Disc is hidden: only the Paid price counts.
    @Test func anOwnedDiscCountsItsPaidPriceNotItsSeenPrice() {
        let value = CollectionValue([disc(.cd, paid: 1200, seen: 2000), disc(.cd, seen: 800)])
        #expect(value == CollectionValue(total: 1200, cd: 1200, vinyl: 0, unpriced: 1))
    }

    /// A Paid price of zero is a price (a gift), not an unpriced Disc.
    @Test func aZeroPaidPriceIsPriced() {
        #expect(CollectionValue([disc(.vinyl, paid: 0)]) == CollectionValue(total: 0, cd: 0, vinyl: 0, unpriced: 0))
    }
}
