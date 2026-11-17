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
        title = disc.shownTitle
        artist = disc.wishlist ? nil : disc.shownArtist
        showsRating = !disc.wishlist
    }
}
