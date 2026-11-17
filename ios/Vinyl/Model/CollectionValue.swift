import Foundation

/// Sum of the Paid prices (euro cents) of Collection Discs; `unpriced` counts the Collection Discs without one,
/// apart, not as zero. Wishlist Discs never count. Port of the Android `collectionValue`.
struct CollectionValue: Equatable, Sendable {
    var total: Int
    var cd: Int
    var vinyl: Int
    var unpriced: Int

    init(total: Int, cd: Int, vinyl: Int, unpriced: Int) {
        self.total = total
        self.cd = cd
        self.vinyl = vinyl
        self.unpriced = unpriced
    }

    init(_ discs: [Disc]) {
        let owned = discs.filter { !$0.wishlist }
        func sum(_ format: Format) -> Int {
            owned.filter { $0.format == format }.reduce(0) { $0 + ($1.paidPrice ?? 0) }
        }
        let cd = sum(.cd)
        let vinyl = sum(.vinyl)
        self.init(total: cd + vinyl, cd: cd, vinyl: vinyl, unpriced: owned.count { $0.paidPrice == nil })
    }
}
