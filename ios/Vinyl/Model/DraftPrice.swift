import Foundation

/// Price rules of the Draft form, kept out of the views. The prices are typed as text so "12," survives
/// while typing; the app model parses them into cents on save (`withTypedPrices`).
extension Draft {
    /// The Seen price as typed; before any typing, the stored price (with a "." separator: `showingPrices(in:)`
    /// rewrites it with the language's own separator).
    var seenPriceText: String {
        get { seenPriceEdit ?? Price.input(seenPrice, locale: Self.neutralLocale) }
        set { seenPriceEdit = newValue }
    }

    /// The Paid price as typed; before any typing, the stored price (see `seenPriceText`).
    var paidPriceText: String {
        get { paidPriceEdit ?? Price.input(paidPrice, locale: Self.neutralLocale) }
        set { paidPriceEdit = newValue }
    }

    private static let neutralLocale = Locale(identifier: "en")

    /// The Draft with its stored prices written as typed text, with the language's decimal separator:
    /// "12,50" in French, "12.50" in English.
    func showingPrices(in locale: Locale) -> Draft {
        var shown = self
        shown.seenPriceEdit = Price.input(seenPrice, locale: locale)
        shown.paidPriceEdit = Price.input(paidPrice, locale: locale)
        return shown
    }

    /// The one price field the form shows: "Prix vu" in the Wishlist, "Prix payé" in the Collection.
    /// The other price stays hidden, not cleared.
    var priceText: String {
        get { wishlist ? seenPriceText : paidPriceText }
        set { if wishlist { seenPriceText = newValue } else { paidPriceText = newValue } }
    }

    /// The label of the one price field: "Prix vu" in the Wishlist, "Prix payé" in the Collection.
    @MainActor
    func priceLabel(in language: Language) -> String {
        wishlist ? language.string("Prix vu") : language.string("Prix payé")
    }

    /// Shown under the price field while its text is malformed; nil when the text is a price or blank.
    @MainActor
    func priceHint(in language: Language) -> String? {
        Price.isValid(priceText) ? nil : language.string("Exemple : 12,50")
    }

    /// The "In wishlist" switch. Leaving the Wishlist (bought) suggests the Seen price as the Paid price,
    /// when the Paid price is blank and the Seen price valid. It stays editable.
    var inWishlist: Bool {
        get { wishlist }
        set {
            if wishlist, !newValue, Price.isBlank(paidPriceText), Price.isValid(seenPriceText) {
                paidPriceText = seenPriceText
            }
            wishlist = newValue
        }
    }

    /// The Draft as saved: each price text parsed into cents, blank meaning no price.
    /// A malformed text keeps the stored price: the hidden field cannot be fixed from the form.
    var withTypedPrices: Draft {
        func cents(_ text: String, stored: Int?) -> Int? {
            Price.isValid(text) ? Price.parse(text) : stored
        }
        var saved = self
        saved.seenPrice = cents(seenPriceText, stored: seenPrice)
        saved.paidPrice = cents(paidPriceText, stored: paidPrice)
        saved.seenPriceEdit = nil
        saved.paidPriceEdit = nil
        return saved
    }
}
