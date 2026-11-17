import Testing
@testable import Vinyl

/// The words under a cover card: Collection cards show title, artist and rating; Wishlist cards the title only
/// (Android `CoverCard(showMeta = false)`).
struct CoverCaptionTests {
    @Test func aCollectionCardShowsTitleArtistAndRating() {
        let caption = CoverCaption(Disc(Draft(title: "Kid A", artist: "Radiohead", rating: 4)))

        #expect(caption == CoverCaption(title: "Kid A", artist: "Radiohead", showsRating: true))
    }

    @Test func aWishlistCardShowsTheTitleOnly() {
        let caption = CoverCaption(Disc(Draft(title: "Homogenic", artist: "Björk", wishlist: true)))

        #expect(caption == CoverCaption(title: "Homogenic", artist: nil, showsRating: false))
    }

    @Test func aBlankTitleIsSansTitreAndABlankArtistIsLeftOut() {
        let caption = CoverCaption(Disc(Draft(title: "  ", artist: " \n")))

        #expect(caption == CoverCaption(title: "Sans titre", artist: nil, showsRating: true))
    }
}
