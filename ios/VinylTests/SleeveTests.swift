import Foundation
import Testing
@testable import Vinyl

/// What the back of an open sleeve says (Android `BackFace` in `ui/Flip.kt`).
struct SleeveBackTests {
    let paris = TimeZone(identifier: "Europe/Paris")!

    /// 2024-11-03 12:00 in Paris.
    let november3 = Date(timeIntervalSince1970: 1_730_631_600)

    func back(_ draft: Draft) -> SleeveBack {
        SleeveBack(Disc(draft), timeZone: paris)
    }

    @Test func showsTitleArtistYearFormatAndDateAdded() {
        let face = back(Draft(title: "Kid A", artist: "Radiohead", year: 2000, format: .vinyl, addedAt: november3))

        #expect(face.title == "Kid A")
        #expect(face.artist == "Radiohead")
        #expect(face.details == "2000 · Vinyle")
        #expect(face.addedOn == "Ajouté le 3 nov. 2024")
    }

    @Test func blankTitleReadsSansTitreAndBlankArtistIsLeftOut() {
        let face = back(Draft(title: "  ", artist: " "))

        #expect(face.title == "Sans titre")
        #expect(face.artist == nil)
    }

    @Test func detailsWithoutYearShowTheFormatOnly() {
        #expect(back(Draft(format: .cd)).details == "CD")
        #expect(back(Draft(year: 1997, format: .cd)).details == "1997 · CD")
        // Colored wax still reads "Vinyle" here; the Color sticker is on the front.
        #expect(back(Draft(format: .vinyl, vinylColor: .red)).details == "Vinyle")
    }

    @Test func wishlistShowsTheSeenPrice() {
        let face = back(Draft(wishlist: true, seenPrice: 1250, paidPrice: 900))

        #expect(face.price == "Vu à 12,50\u{A0}€")
    }

    @Test func collectionShowsThePaidPrice() {
        let face = back(Draft(wishlist: false, seenPrice: 1250, paidPrice: 124_000))

        #expect(face.price == "Payé 1\u{202F}240\u{A0}€")
    }

    @Test func noPriceLineWhenTheShownPriceIsUnset() {
        #expect(back(Draft(wishlist: true, paidPrice: 900)).price == nil)
        #expect(back(Draft(wishlist: false, seenPrice: 900)).price == nil)
    }

    @Test func ratingShowsInTheCollectionOnly() {
        #expect(back(Draft(rating: 4, wishlist: false)).showsRating)
        #expect(!back(Draft(rating: 4, wishlist: true)).showsRating)
    }
}

/// How the vinyl that slides out of the sleeve is drawn (Android `Vinyl` in `ui/Flip.kt`).
struct VinylWaxTests {
    func wax(_ draft: Draft) -> VinylWax { VinylWax(Disc(draft)) }

    @Test func noVinylColorIsBlackWaxWithLightGrooves() {
        let black = wax(Draft(format: .vinyl))

        #expect(black.argb == 0xFF12_1212)
        #expect(black.grooves == .light)
    }

    @Test func coloredWaxIsDrawnInItsVinylColor() {
        #expect(wax(Draft(format: .vinyl, vinylColor: .red)).argb == 0xFFC8_242B)
        #expect(wax(Draft(format: .vinyl, vinylColor: .red)).grooves == .light)
    }

    @Test func lightWaxGetsDarkGrooves() {
        #expect(wax(Draft(format: .vinyl, vinylColor: .yellow)).grooves == .dark)
        #expect(wax(Draft(format: .vinyl, vinylColor: .white)).grooves == .dark)
        #expect(wax(Draft(format: .vinyl, vinylColor: .clear)).grooves == .dark)
    }

    @Test func transparentWaxIsHalfSeeThrough() {
        let alpha = wax(Draft(format: .vinyl, vinylColor: .clear)).argb >> 24

        #expect(alpha == 0x8C)
    }

    @Test func aCDKeepsItsHiddenVinylColorAndShowsBlack() {
        let cd = wax(Draft(format: .cd, vinylColor: .white))

        #expect(cd.argb == 0xFF12_1212)
        #expect(cd.grooves == .light)
    }
}
