import Foundation

/// The text on the back of an open sleeve on Home (Android `BackFace` in `ui/Flip.kt`).
struct SleeveBack: Equatable, Sendable {
    /// The title, "Sans titre" when blank.
    let title: String
    /// The artist, nil when blank (drawn uppercase).
    let artist: String?
    /// Year and Format: "2000 · Vinyle", "CD".
    let details: String
    /// "33 tr/min" or "45 tr/min": vinyl Discs with a Speed only, in the Collection and the Wishlist.
    let speed: String?
    /// "Ajouté le 3 nov. 2024".
    let addedOn: String
    /// "Vu à 12,50 €" in the Wishlist, "Payé 25 €" in the Collection; nil when that price is unset.
    /// The other price stays hidden.
    let price: String?
    /// The star rating shows in the Collection only.
    let showsRating: Bool

    /// Title lines the back keeps (Android `backTitleLines` with `large = true`: the card is always the large one).
    /// The card fits a 3-line title and the price line; a Speed line takes a title line.
    var titleLines: Int { speed == nil ? 3 : 2 }

    init(_ disc: Disc, timeZone: TimeZone = .current) {
        price = if disc.wishlist {
            disc.seenPrice.map { String(localized: "Vu à \(Price.format($0))") }
        } else {
            disc.paidPrice.map { String(localized: "Payé \(Price.format($0))") }
        }
        speed = disc.speedLabel
        showsRating = !disc.wishlist
        title = disc.shownTitle
        artist = disc.shownArtist
        details = [disc.year.map(String.init), disc.format.label].compactMap { $0 }.joined(separator: " · ")
        addedOn = String(localized: "Ajouté le \(Self.dateText(disc.addedAt, timeZone: timeZone))")
    }

    /// "d MMM yyyy" in French, as on Android.
    private static func dateText(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.timeZone = timeZone
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

/// The wax of the vinyl that slides out of an open sleeve (Android `Vinyl` in `ui/Flip.kt`).
struct VinylWax: Equatable, Sendable {
    /// Groove lines: light on dark wax, dark on light wax.
    enum Grooves: Sendable {
        /// White at 7 %.
        case light
        /// Black at 10 %.
        case dark
    }

    /// Wax color as 0xAARRGGBB: the Vinyl color, or near black when none. Transparent carries its own alpha.
    let argb: UInt32
    let grooves: Grooves

    /// Black wax when there is no Vinyl color.
    static let black: UInt32 = 0xFF12_1212

    init(_ disc: Disc) {
        // Only vinyl shows its Vinyl color; a CD keeps its value hidden.
        let color = disc.shownVinylColor
        argb = color?.argb ?? Self.black
        grooves = color?.light == true ? .dark : .light
    }
}
