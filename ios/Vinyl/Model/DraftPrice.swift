import Foundation

/// Price rules of the Draft form, kept out of the views. The prices are typed as text so "12," survives
/// while typing; the app model parses them into cents on save (`withTypedPrices`).
extension Draft {
    /// The Seen price as typed, or as stored ("25", "12,50") until typed.
    var seenPriceText: String {
        get { seenPriceEdit ?? Price.input(seenPrice) }
        set { seenPriceEdit = newValue }
    }

    /// The Paid price as typed, or as stored until typed.
    var paidPriceText: String {
        get { paidPriceEdit ?? Price.input(paidPrice) }
        set { paidPriceEdit = newValue }
    }

    /// The one price field the form shows: "Prix vu" in the Wishlist, "Prix payé" in the Collection.
    /// The other price stays hidden, not cleared.
    var priceText: String {
        get { wishlist ? seenPriceText : paidPriceText }
        set { if wishlist { seenPriceText = newValue } else { paidPriceText = newValue } }
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
