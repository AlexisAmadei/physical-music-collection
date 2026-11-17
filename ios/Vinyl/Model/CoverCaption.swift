import Foundation

/// The words under a cover card (Android `CoverCard`). Collection cards: title, artist and rating.
/// Wishlist cards: the title only (Android `showMeta = false`).
struct CoverCaption: Equatable, Sendable {
    /// The title, "Sans titre" when blank.
    let title: String
    /// The artist, nil when blank or on a Wishlist card.
    let artist: String?
    let showsRating: Bool

    init(title: String, artist: String?, showsRating: Bool) {
        self.title = title
        self.artist = artist
        self.showsRating = showsRating
    }

    init(_ disc: Disc) {
        func blank(_ s: String) -> Bool { s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        title = blank(disc.title) ? String(localized: "Sans titre") : disc.title
        artist = disc.wishlist || blank(disc.artist) ? nil : disc.artist
        showsRating = !disc.wishlist
    }
}
