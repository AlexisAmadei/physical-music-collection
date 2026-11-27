import Foundation

/// What the Profile card shows, over the Collection Discs only (Wishlist Discs never count). Port of the Android
/// `collectionStats`.
///
/// `colored`: vinyl Discs with a Vinyl color (Clear included); a CD keeping a hidden one is not counted.
/// `oldestYear`: among the Discs that have a year, nil when none has. `value` and `unpriced`: see `CollectionValue`.
struct CollectionStats: Equatable, Sendable {
    var vinyls: Int
    var cds: Int
    var colored: Int
    var oldestYear: Int?
    /// Collection value, euro cents.
    var value: Int
    var unpriced: Int

    init(vinyls: Int, cds: Int, colored: Int, oldestYear: Int?, value: Int, unpriced: Int) {
        self.vinyls = vinyls
        self.cds = cds
        self.colored = colored
        self.oldestYear = oldestYear
        self.value = value
        self.unpriced = unpriced
    }

    init(_ discs: [Disc]) {
        let owned = discs.filter { !$0.wishlist }
        let value = CollectionValue(owned)
        self.init(
            vinyls: owned.count { $0.format == .vinyl },
            cds: owned.count { $0.format == .cd },
            colored: owned.count { $0.format == .vinyl && $0.vinylColor != nil },
            oldestYear: owned.compactMap(\.year).min(),
            value: value.total,
            unpriced: value.unpriced
        )
    }
}
