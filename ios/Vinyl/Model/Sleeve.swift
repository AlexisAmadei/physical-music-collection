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
    /// "Marbré · Rouge et noir": vinyl Discs with a Finish only.
    let finish: String?
    /// The Speed and the Finish on one line, "33 tr/min · Marbré · Rouge et noir"; nil when neither shows. One line, so a
    /// Finish costs no extra title line.
    let specs: String?
    /// "Ajouté le 3 nov. 2024".
    let addedOn: String
    /// "Vu à 12,50 €" in the Wishlist, "Payé 25 €" in the Collection; nil when that price is unset.
    /// The other price stays hidden.
    let price: String?
    /// The star rating shows in the Collection only.
    let showsRating: Bool

    /// Title lines the back keeps (Android `backTitleLines` with `large = true`: the card is always the large one).
    /// The card fits a 3-line title and the price line; the specs line (Speed and Finish) takes a title line.
    var titleLines: Int { specs == nil ? 3 : 2 }

    @MainActor
    init(_ disc: Disc, language: Language, timeZone: TimeZone = .current) {
        price = if disc.wishlist {
            disc.seenPrice.map { language.string("Vu à \(Price.format($0, locale: language.locale))") }
        } else {
            disc.paidPrice.map { language.string("Payé \(Price.format($0, locale: language.locale))") }
        }
        let speedLine = disc.speedLabel(in: language)
        let finishLine = disc.finishLine(in: language)
        let lines = [speedLine, finishLine].compactMap { $0 }
        speed = speedLine
        finish = finishLine
        specs = lines.isEmpty ? nil : lines.joined(separator: " · ")
        showsRating = !disc.wishlist
        title = disc.shownTitle(in: language)
        artist = disc.shownArtist
        details = [disc.year.map(String.init), disc.format.label(in: language)].compactMap { $0 }.joined(separator: " · ")
        addedOn = language.string(
            "Ajouté le \(DateText.format(disc.addedAt, locale: language.locale, timeZone: timeZone))"
        )
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
    /// The Vinyl color as shown, nil = black wax.
    let base: VinylColor?
    /// The Finish as shown, nil = Solid.
    let finish: Finish?
    /// The Second color as shown, for a Finish that uses one.
    let second: VinylColor?
    /// Seed of the Disc's pattern.
    let seed: UInt64

    /// Black wax when there is no Vinyl color.
    static let black: UInt32 = 0xFF12_1212

    init(_ disc: Disc) {
        // Only vinyl shows its Vinyl color; a CD keeps its value hidden.
        let color = disc.shownVinylColor
        argb = color?.argb ?? Self.black
        grooves = color?.light == true ? .dark : .light
        base = color
        finish = disc.shownFinish
        second = disc.shownSecondColor
        seed = disc.waxSeed
    }

    /// What to draw for the Finish: nil for Solid (plain wax needs no image). `side` is the image side in pixels.
    func look(side: Int) -> WaxLook? {
        guard let finish else { return nil }
        return WaxLook(base: base, finish: finish, second: second, seed: seed, side: side, marbleSide: WaxPattern.marbleSize)
    }
}
