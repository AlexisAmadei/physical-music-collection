import Foundation
import Testing
@testable import Vinyl

/// Texts and formats that must read the same on iOS and Android (spec #32). Expected values are written out by hand:
/// they are the copy and the formats the Android tests (`StringResourcesTest`, `PriceTest`, `DatesTest`) pin too.
@MainActor
struct CrossPlatformParityTests {
    func language(_ language: AppLanguage) -> Language {
        Language(preferences: InMemoryLanguagePreferences(language: language), deviceLanguages: [])
    }

    // MARK: Wording that used to differ from Android's

    @Test func wordingThatDifferedIsNowTheSameAsAndroid() {
        let en = language(.english)
        #expect(en.string("Ajouter mon premier disque") == "Add my first disc")
        #expect(en.string("Ajoute les disques que tu cherches.") == "Add the discs you are looking for.")
        #expect(en.string("Note : \(4) sur 5") == "Rating: 4 out of 5")
    }

    // MARK: Format tag (Search rows, Draft form), Android `Format.tag()`

    @Test func formatTagIsTheUppercaseFormatInTheLanguage() {
        #expect(Format.cd.tag(in: language(.english)) == "CD")
        #expect(Format.vinyl.tag(in: language(.english)) == "VINYL")
        #expect(Format.cd.tag(in: language(.french)) == "CD")
        #expect(Format.vinyl.tag(in: language(.french)) == "VINYLE")
    }

    // MARK: Price in the edit field, Android `Price.input(cents, language)`

    @Test func priceInputUsesTheLanguagesDecimalSeparator() {
        #expect(Price.input(1250, locale: Locale(identifier: "en")) == "12.50")
        #expect(Price.input(1250, locale: Locale(identifier: "fr")) == "12,50")
        #expect(Price.input(5, locale: Locale(identifier: "en")) == "0.05")
        #expect(Price.input(2500, locale: Locale(identifier: "en")) == "25")
        #expect(Price.input(nil, locale: Locale(identifier: "en")) == "")
    }

    @Test func editingASavedDiscShowsItsPriceInTheLanguage() throws {
        for (picked, expected) in [(AppLanguage.english, "12.50"), (.french, "12,50")] {
            let app = try AppModel.pinned(picked)
            app.newDraft()
            app.draft.title = "Homogenic"
            app.draft.priceText = "12,50"
            app.saveDraft()

            app.open(try #require(app.collection.first))

            #expect(app.draft.priceText == expected)
            app.saveDraft()
            #expect(app.collection.first?.paidPrice == 1250)
        }
    }

    @Test func aPriceTypedInEnglishSavesTheSameAsInFrench() throws {
        let app = try AppModel.pinned(.english)
        app.newDraft()
        app.draft.title = "Homogenic"
        app.draft.priceText = "12.50"
        app.saveDraft()
        #expect(app.collection.first?.paidPrice == 1250)
    }
}
