import Foundation
import SwiftData

/// The physical medium of a Disc. Anything else is out of scope.
enum Format: String, Codable, CaseIterable, Sendable {
    case cd = "CD"
    case vinyl = "VINYL"

    /// "CD" or "Vinyle" ("Vinyl" in English), as shown and read by VoiceOver.
    @MainActor
    func label(in language: Language) -> String {
        switch self {
        case .cd: language.string("CD")
        case .vinyl: language.string("Vinyle")
        }
    }

    /// The label as an uppercase tag ("CD", "VINYL" / "VINYLE"): the Search rows and the Draft form.
    @MainActor
    func tag(in language: Language) -> String {
        switch self {
        case .cd: language.string("CD")
        case .vinyl: language.string("VINYL")
        }
    }
}

extension String {
    /// Empty or only spaces and line breaks: what every Disc field treats as "not set".
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

/// One physical release the user owns (Collection) or wants (Wishlist). Mirrors the Android `Disc` entity.
/// Screens never edit a Disc in place: they edit a `Draft` and the app model saves it.
@Model
final class Disc {
    // The defaults only exist so `init(_:)` can hand every field to `update(from:)`: a Disc is always built from a Draft.
    var title = ""
    var artist = ""
    var year: Int?
    var format = Format.vinyl
    var barcode: String?
    /// 0 = not rated, else 1 to 5.
    var rating = 0
    var comment = ""
    var wishlist = false
    var addedAt = Date.now
    var coverURL: URL?
    /// Seen price in euro cents: kept while in the Wishlist, hidden (not cleared) once owned.
    var seenPrice: Int?
    /// Paid price in euro cents: what the Collection value adds up.
    var paidPrice: Int?
    /// Vinyl color, nil = black. Kept (not cleared) if the Format becomes CD.
    var vinylColor: VinylColor?
    /// Speed (33 or 45 RPM), nil = not set. Kept (not cleared) if the Format becomes CD.
    /// Added after release: an optional field, so Discs saved before it open with no Speed.
    var speed: Speed?
    /// Finish, nil = Solid. Needs a Vinyl color; kept (not cleared) if the Format becomes CD.
    /// Added after release: an optional field, so Discs saved before it open Solid.
    var finish: Finish?
    /// Second color of a Finish that uses one. Kept (not cleared) when the Finish goes back to Solid or the Format becomes CD.
    /// Added after release: an optional field, so Discs saved before it open with none.
    var secondColor: VinylColor?

    init(_ draft: Draft) {
        update(from: draft)
    }

    /// Copies every field of the Draft except the identity. `Draft.init(_ disc:)` is the way back: add a field to both.
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
        speed = draft.speed
        finish = draft.finish
        secondColor = draft.secondColor
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
    /// Speed (33 or 45 RPM), nil = not set. Kept (not cleared) if the Format becomes CD.
    var speed: Speed?
    /// Finish, nil = Solid. Kept (not cleared) if the Format becomes CD. Pick it with `pickFinish(_:)`.
    var finish: Finish?
    /// Second color of a Finish that uses one. Kept (not cleared) when the Finish goes back to Solid or the Format becomes CD.
    var secondColor: VinylColor?
    /// Price texts as typed in the Draft form; nil = not typed. Read them through `DraftPrice.swift`.
    var seenPriceEdit: String?
    var paidPriceEdit: String?

    var isNew: Bool { id == nil }
}

extension Disc {
    /// The title as shown: "Sans titre" ("Untitled" in English) when blank.
    @MainActor
    func shownTitle(in language: Language) -> String { title.isBlank ? language.string("Sans titre") : title }
    /// The artist as shown: nil when blank.
    var shownArtist: String? { artist.isBlank ? nil : artist }
}

extension Draft {
    /// A Draft that edits a saved Disc.
    init(_ disc: Disc) {
        self.init(
            id: disc.persistentModelID, title: disc.title, artist: disc.artist, year: disc.year,
            format: disc.format, barcode: disc.barcode, rating: disc.rating, comment: disc.comment,
            wishlist: disc.wishlist, addedAt: disc.addedAt, coverURL: disc.coverURL,
            seenPrice: disc.seenPrice, paidPrice: disc.paidPrice, vinylColor: disc.vinylColor,
            speed: disc.speed, finish: disc.finish, secondColor: disc.secondColor
        )
    }
}
