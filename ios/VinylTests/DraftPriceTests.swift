import Testing
@testable import Vinyl

/// The Draft's price rules, driven through the app model the way the Draft screen does.
@MainActor
struct DraftPriceTests {
    let app: AppModel

    init() throws {
        app = try AppModel.pinned()
    }

    /// Saves a Wishlist Disc seen at `price` and opens its Draft.
    func openWishlistDisc(seenAt price: String) throws {
        app.newDraft(wishlist: true)
        app.draft.title = "Homogenic"
        app.draft.priceText = price
        app.saveDraft()
        app.open(try #require(app.wishlist.first))
    }

    @Test func movingToTheCollectionPrefillsThePaidPriceFromTheSeenPrice() throws {
        try openWishlistDisc(seenAt: "12,50")

        app.draft.inWishlist = false
        #expect(app.draft.priceText == "12,50")
        app.saveDraft()

        #expect(app.wishlist.isEmpty)
        let owned = try #require(app.collection.first)
        #expect(owned.paidPrice == 1250)
        #expect(owned.seenPrice == 1250)
    }

    @Test func movingToTheCollectionKeepsAPaidPriceAlreadyTyped() throws {
        try openWishlistDisc(seenAt: "12,50")
        app.draft.paidPriceText = "10"

        app.draft.inWishlist = false

        #expect(app.draft.priceText == "10")
    }

    @Test func movingToTheCollectionDoesNotCopyAMalformedSeenPrice() {
        app.newDraft(wishlist: true)
        app.draft.priceText = "12€"

        app.draft.inWishlist = false

        #expect(app.draft.priceText == "")
    }

    @Test func saveIsRefusedOnAMalformedShownPrice() {
        app.newDraft()
        app.draft.title = "Debut"
        app.draft.priceText = "12,505"

        #expect(!app.canSaveDraft)
        app.saveDraft()
        #expect(app.collection.isEmpty)

        app.draft.priceText = "12.50"
        #expect(app.canSaveDraft)
        app.saveDraft()
        #expect(app.collection.first?.paidPrice == 1250)
    }

    @Test func aBlankShownPriceMeansNoPrice() throws {
        try openWishlistDisc(seenAt: "25")
        #expect(app.draft.priceText == "25")

        app.draft.priceText = " "
        #expect(app.canSaveDraft)
        app.saveDraft()

        #expect(app.wishlist.first?.seenPrice == nil)
    }

    @Test func aHiddenMalformedPriceKeepsItsStoredValue() throws {
        try openWishlistDisc(seenAt: "12,50")
        app.draft.priceText = "12,"
        // The Seen price is hidden once the Draft leaves the Wishlist: it cannot be fixed from the form.
        app.draft.inWishlist = false
        app.draft.priceText = "15"

        #expect(app.canSaveDraft)
        app.saveDraft()

        let owned = try #require(app.collection.first)
        #expect(owned.seenPrice == 1250)
        #expect(owned.paidPrice == 1500)
    }

    @Test func thePriceFieldIsPrixVuInTheWishlistAndPrixPayeInTheCollection() {
        app.newDraft(wishlist: true)
        #expect(app.draft.priceLabel(in: app.language) == "Prix vu")

        app.draft.inWishlist = false
        #expect(app.draft.priceLabel(in: app.language) == "Prix payé")
    }

    @Test func thePriceFieldAndItsExampleSpeakEnglishInEnglish() {
        app.language.select(.english)
        app.newDraft(wishlist: true)
        #expect(app.draft.priceLabel(in: app.language) == "Seen price")

        app.draft.inWishlist = false
        #expect(app.draft.priceLabel(in: app.language) == "Paid price")

        app.draft.priceText = "12,"
        #expect(app.draft.priceHint(in: app.language) == "Example: 12.50")
    }

    @Test func bothSeparatorsAreAcceptedInEitherLanguage() {
        for language in AppLanguage.allCases {
            app.language.select(language)
            for typed in ["12,50", "12.50"] {
                app.newDraft()
                app.draft.title = "Debut"
                app.draft.priceText = typed
                #expect(app.canSaveDraft)
                #expect(app.draft.priceHint(in: app.language) == nil)
                app.saveDraft()
            }
        }
        #expect(app.collection.map(\.paidPrice) == [1250, 1250, 1250, 1250])
    }

    @Test func aDraftBuiltStraightFromASavedDiscKeepsItsPricesOnSave() throws {
        app.newDraft()
        app.draft.title = "Homogenic"
        app.draft.priceText = "12,50"
        app.saveDraft()
        let disc = try #require(app.collection.first)

        // Not through `AppModel.edit`: the stored prices must not depend on `showingPrices(in:)`.
        let draft = Draft(disc)

        #expect(draft.paidPriceText == "12.50")
        #expect(draft.withTypedPrices.paidPrice == 1250)
    }

    @Test func theExampleShowsUnderAMalformedPriceOnly() {
        app.newDraft()
        #expect(app.draft.priceHint(in: app.language) == nil)

        app.draft.priceText = "12,"
        #expect(app.draft.priceHint(in: app.language) == "Exemple : 12,50")

        app.draft.priceText = "12,5"
        #expect(app.draft.priceHint(in: app.language) == nil)
    }
}
