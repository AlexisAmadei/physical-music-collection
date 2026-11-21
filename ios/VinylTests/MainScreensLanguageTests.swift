import Foundation
import Testing
@testable import Vinyl

/// Home, Collection, Wishlist, navigation, sort labels, the disc flip card and their accessibility labels
/// read right in both languages (spec #29). French wording is the source text, word for word.
@MainActor
struct MainScreensLanguageTests {
    struct Entry: Sendable {
        let key: String.LocalizationValue
        let en: String
        let fr: String
    }

    nonisolated static let entries: [Entry] = [
        // Home
        Entry(key: "Welcome home...", en: "Welcome home...", fr: "Bienvenue à la maison..."),
        // Navigation labels (VoiceOver)
        Entry(key: "Accueil", en: "Home", fr: "Accueil"),
        Entry(key: "Rechercher", en: "Search", fr: "Rechercher"),
        Entry(key: "Profil", en: "Profile", fr: "Profil"),
        Entry(key: "Collection", en: "Collection", fr: "Collection"),
        Entry(key: "Wishlist", en: "Wishlist", fr: "Wishlist"),
        Entry(key: "Ajouter un disque", en: "Add a disc", fr: "Ajouter un disque"),
        Entry(key: "Ajouter à la wishlist", en: "Add to wishlist", fr: "Ajouter à la wishlist"),
        // Screen titles and the Wishlist empty state
        Entry(key: "Ma collection", en: "My collection", fr: "Ma collection"),
        Entry(key: "Ma wishlist", en: "My wishlist", fr: "Ma wishlist"),
        Entry(
            key: "Ajoute les disques que tu cherches.", en: "Add the discs you are looking for.",
            fr: "Ajoute les disques que tu cherches."
        ),
        // Sort labels (the Format chips read the model's Format label, see LanguageTests)
        Entry(key: "Date d’ajout", en: "Date added", fr: "Date d’ajout"),
        Entry(key: "Année", en: "Year", fr: "Année"),
        // Cover wheel and flip card accessibility
        Entry(key: "Disque suivant", en: "Next disc", fr: "Disque suivant"),
        Entry(key: "Disque précédent", en: "Previous disc", fr: "Disque précédent"),
        Entry(key: "Retourner", en: "Flip", fr: "Retourner"),
        Entry(key: "Modifier le disque", en: "Edit disc", fr: "Modifier le disque"),
        // Rating accessibility
        Entry(key: "Non noté", en: "Not rated", fr: "Non noté"),
        Entry(key: "Note : \(3) sur 5", en: "Rating: 3 out of 5", fr: "Note : 3 sur 5"),
    ]

    @Test(arguments: entries)
    func everyStringReadsRightInBothLanguages(entry: Entry) {
        let language = Language(preferences: InMemoryLanguagePreferences(), deviceLanguages: ["fr-FR"])
        #expect(language.string(entry.key) == entry.fr)
        language.select(.english)
        #expect(language.string(entry.key) == entry.en)
    }
}
