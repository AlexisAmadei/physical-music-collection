import Foundation
import Testing
@testable import Vinyl

/// The Language: device language by default (English fallback), the user's pick once made (spec #24).
@MainActor
struct LanguageTests {
    let preferences = InMemoryLanguagePreferences()

    func language(device: [String]) -> Language {
        Language(preferences: preferences, deviceLanguages: device)
    }

    // MARK: Preference resolution

    @Test func frenchDeviceShowsFrenchUntilThePickIsMade() {
        #expect(language(device: ["fr-FR"]).current == .french)
        #expect(language(device: ["fr-CA", "en-US"]).current == .french)
    }

    @Test func anyOtherDeviceShowsEnglish() {
        #expect(language(device: ["en-US"]).current == .english)
        #expect(language(device: ["de-DE"]).current == .english)
        #expect(language(device: ["ja-JP", "es-ES"]).current == .english)
        #expect(language(device: []).current == .english)
    }

    /// The first device language the app has, like the OS: a French second choice still gives French.
    @Test func theFirstSupportedDeviceLanguageWins() {
        #expect(language(device: ["de-DE", "fr-FR"]).current == .french)
        #expect(language(device: ["de-DE", "en-GB", "fr-FR"]).current == .english)
    }

    @Test func theUsersPickWinsOverTheDevice() {
        preferences.language = .english
        #expect(language(device: ["fr-FR"]).current == .english)
        preferences.language = .french
        #expect(language(device: ["en-US"]).current == .french)
    }

    @Test func selectingKeepsThePickInPreferences() {
        let language = language(device: ["en-US"])
        language.select(.french)

        #expect(language.current == .french)
        #expect(preferences.language == .french)
        // The next launch, whatever the device says.
        #expect(Language(preferences: preferences, deviceLanguages: ["en-US"]).current == .french)
    }

    @Test func nothingIsStoredUntilThePickIsMade() {
        _ = language(device: ["fr-FR"])
        #expect(preferences.language == nil)
    }

    // MARK: Locale and bundle

    @Test func localeAndBundleFollowTheCurrentLanguage() {
        let language = language(device: ["en-US"])
        #expect(language.locale.language.languageCode?.identifier == "en")
        #expect(language.bundle.bundleURL.lastPathComponent == "en.lproj")

        language.select(.french)
        #expect(language.locale.language.languageCode?.identifier == "fr")
        #expect(language.bundle.bundleURL.lastPathComponent == "fr.lproj")
    }

    @Test func eachLanguageIsNamedInItsOwnLanguage() {
        #expect(AppLanguage.allCases.map(\.nativeName) == ["English", "Français"])
    }

    // MARK: String Catalog, through the language object

    @Test func discCountIsCorrectFor0_1AndNInBothLanguages() {
        let language = language(device: ["fr-FR"])
        func count(_ n: Int) -> String { language.string("\(n) disques") }

        // French: 0 and 1 are singular.
        #expect(count(0) == "0 disque")
        #expect(count(1) == "1 disque")
        #expect(count(2) == "2 disques")
        #expect(count(42) == "42 disques")

        language.select(.english)
        // English: 0 is plural.
        #expect(count(0) == "0 discs")
        #expect(count(1) == "1 disc")
        #expect(count(2) == "2 discs")
        #expect(count(42) == "42 discs")
    }

    @Test func unpricedCountIsCorrectInBothLanguages() {
        let language = language(device: ["fr-FR"])
        func count(_ n: Int) -> String { language.string("\(n) disques sans prix") }

        #expect(count(1) == "1 disque sans prix")
        #expect(count(3) == "3 disques sans prix")

        language.select(.english)
        #expect(count(1) == "1 disc without a price")
        #expect(count(3) == "3 discs without a price")
    }

    @Test func existingFrenchWordingIsUnchanged() {
        let language = language(device: ["fr-FR"])
        #expect(language.string("MON PROFIL") == "MON PROFIL")
        #expect(language.string("Ton nom") == "Ton nom")
        #expect(language.string("Valeur de la collection") == "Valeur de la collection")
        #expect(language.string("Par format") == "Par format")
        #expect(language.string("Rien ici pour l’instant.") == "Rien ici pour l’instant.")
    }

    @Test func profileScreenIsTranslatedToEnglish() {
        let language = language(device: ["en-US"])
        #expect(language.string("MON PROFIL") == "MY PROFILE")
        #expect(language.string("Ton nom") == "Your name")
        #expect(language.string("Valeur de la collection") == "Collection value")
        #expect(language.string("Par format") == "By format")
        #expect(language.string("valueByFormat.vinyl") == "Vinyl")
        language.select(.french)
        #expect(language.string("valueByFormat.vinyl") == "Vinyle")
    }

    // MARK: Through the app model

    @Test func appModelHoldsTheLanguageAndKeepsThePick() throws {
        let app = try AppModel(
            container: DiscStore.inMemoryContainer(), languagePreferences: preferences, deviceLanguages: ["en-US"]
        )
        #expect(app.language.current == .english)

        app.language.select(.french)

        let reopened = try AppModel(
            container: DiscStore.inMemoryContainer(), languagePreferences: preferences, deviceLanguages: ["en-US"]
        )
        #expect(reopened.language.current == .french)
    }
}
