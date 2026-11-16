import Foundation
import SwiftData

/// The physical medium of a Disc. Anything else is out of scope.
enum Format: String, Codable, CaseIterable, Sendable {
    case cd = "CD"
    case vinyl = "VINYL"
}

/// The color of a vinyl Disc's wax. No value (nil) means black.
/// Labels, wax colors and display rules come with the Vinyl color ticket.
enum VinylColor: String, Codable, CaseIterable, Sendable {
    case red = "RED", orange = "ORANGE", yellow = "YELLOW", green = "GREEN", blue = "BLUE"
    case purple = "PURPLE", pink = "PINK", white = "WHITE", clear = "CLEAR"
}

/// One physical release the user owns (Collection) or wants (Wishlist). Mirrors the Android `Disc` entity.
/// Screens never edit a Disc in place: they edit a `Draft` and the app model saves it.
@Model
final class Disc {
    var title: String
    var artist: String
    var year: Int?
    var format: Format
    var barcode: String?
    /// 0 = not rated, else 1 to 5.
    var rating: Int
    var comment: String
    var wishlist: Bool
    var addedAt: Date
    var coverURL: URL?
    /// Seen price in euro cents: kept while in the Wishlist, hidden (not cleared) once owned.
    var seenPrice: Int?
    /// Paid price in euro cents: what the Collection value adds up.
    var paidPrice: Int?
    /// Vinyl color, nil = black. Kept (not cleared) if the Format becomes CD.
    var vinylColor: VinylColor?

    init(_ draft: Draft) {
        title = draft.title
        artist = draft.artist
        year = draft.year
        format = draft.format
        barcode = draft.barcode
        rating = draft.rating
        comment = draft.comment
        wishlist = draft.wishlist
        addedAt = draft.addedAt
        coverURL = draft.coverURL
        seenPrice = draft.seenPrice
        paidPrice = draft.paidPrice
        vinylColor = draft.vinylColor
    }

    /// Copies every field of the Draft except the identity.
    func update(from draft: Draft) {
        title = draft.title
        artist = draft.artist
        year = draft.year
        format = draft.format
        barcode = draft.barcode
        rating = draft.rating
        comment = draft.comment
        wishlist = draft.wishlist
        addedAt = draft.addedAt
        coverURL = draft.coverURL
        seenPrice = draft.seenPrice
        paidPrice = draft.paidPrice
        vinylColor = draft.vinylColor
    }
}

/// A Disc being added or edited, not yet saved. A plain value: editing it never touches the store.
/// Catalog results are Drafts too.
struct Draft: Equatable, Sendable {
    /// The saved Disc this Draft edits; nil for a new Disc.
    var id: PersistentIdentifier?
    var title = ""
    var artist = ""
    var year: Int?
    var format = Format.vinyl
    var barcode: String?
    var rating = 0
    var comment = ""
    var wishlist = false
    var addedAt = Date.now
    var coverURL: URL?
    var seenPrice: Int?
    var paidPrice: Int?
    var vinylColor: VinylColor?

    var isNew: Bool { id == nil }
}

extension Draft {
    /// A Draft that edits a saved Disc.
    init(_ disc: Disc) {
        self.init(
            id: disc.persistentModelID, title: disc.title, artist: disc.artist, year: disc.year,
            format: disc.format, barcode: disc.barcode, rating: disc.rating, comment: disc.comment,
            wishlist: disc.wishlist, addedAt: disc.addedAt, coverURL: disc.coverURL,
            seenPrice: disc.seenPrice, paidPrice: disc.paidPrice, vinylColor: disc.vinylColor
        )
    }
}
