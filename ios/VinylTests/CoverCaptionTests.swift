import Testing
@testable import Vinyl

/// The words under a cover card: Collection cards show title, artist and rating; Wishlist cards the title only
/// (Android `CoverCard(showMeta = false)`).
@MainActor
struct CoverCaptionTests {
    let language = Language.pinned(.french)

    @Test func aCollectionCardShowsTitleArtistAndRating() {
        let caption = CoverCaption(Disc(Draft(title: "Kid A", artist: "Radiohead", rating: 4)), language: language)

        #expect(caption == CoverCaption(title: "Kid A", artist: "Radiohead", showsRating: true))
    }

    @Test func aWishlistCardShowsTheTitleOnly() {
        let caption = CoverCaption(Disc(Draft(title: "Homogenic", artist: "Björk", wishlist: true)), language: language)

        #expect(caption == CoverCaption(title: "Homogenic", artist: nil, showsRating: false))
    }

    @Test func aBlankTitleIsSansTitreAndABlankArtistIsLeftOut() {
        let caption = CoverCaption(Disc(Draft(title: "  ", artist: " \n")), language: language)

        #expect(caption == CoverCaption(title: "Sans titre", artist: nil, showsRating: true))
    }

    @Test func aBlankTitleIsUntitledInEnglish() {
        language.select(.english)
        let caption = CoverCaption(Disc(Draft(title: "  ", artist: " \n")), language: language)

        #expect(caption == CoverCaption(title: "Untitled", artist: nil, showsRating: true))
    }

    @Test func theCaptionFollowsTheLanguageWhenItSwitches() {
        let disc = Disc(Draft(title: ""))
        #expect(CoverCaption(disc, language: language).title == "Sans titre")

        language.select(.english)
        #expect(CoverCaption(disc, language: language).title == "Untitled")
    }
}
