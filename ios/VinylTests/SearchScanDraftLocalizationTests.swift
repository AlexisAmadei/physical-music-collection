import Foundation
import Testing
@testable import Vinyl

/// Search, Scan, the Draft form and the camera prompt in English and French (spec #30).
/// Expected texts are written out by hand: they are the copy, shared with Android.
@MainActor
struct SearchScanDraftLocalizationTests {
    func language(_ language: AppLanguage) -> Language {
        Language(preferences: InMemoryLanguagePreferences(language: language), deviceLanguages: [])
    }

    /// Each key, with its English and French text, as the screens use them.
    static let copy: [(key: String.LocalizationValue, en: String, fr: String)] = [
        // Search
        ("Looking for something?", "Looking for something?", "Tu cherches quelque chose ?"),
        ("My discs", "My discs", "Mes disques"),
        ("Search catalog", "Search catalog", "Chercher dans le catalogue"),
        ("Searching…", "Searching…", "Recherche…"),
        ("Add manually", "Add manually", "Ajouter à la main"),
        // Scan
        ("Enter manually", "Enter manually", "Saisie manuelle"),
        ("Camera permission needed", "Camera permission needed", "Accès à l’appareil photo requis"),
        // Draft form
        ("Add disc", "Add disc", "Ajouter un disque"),
        ("Edit disc", "Edit disc", "Modifier le disque"),
        ("Title", "Title", "Titre"),
        ("Artist", "Artist", "Artiste"),
        ("Year", "Year", "Année"),
        ("Barcode", "Barcode", "Code-barres"),
        ("VINYL", "VINYL", "VINYLE"),
        ("Vitesse", "Speed", "Vitesse"),
        ("Vinyle couleur", "Colored vinyl", "Vinyle couleur"),
        ("Comment", "Comment", "Commentaire"),
        ("In wishlist", "In wishlist", "Dans la wishlist"),
        ("Save", "Save", "Enregistrer"),
        ("Delete", "Delete", "Supprimer"),
    ]

    @Test func everySearchScanAndDraftStringHasBothLanguages() {
        for entry in Self.copy {
            #expect(language(.english).string(entry.key) == entry.en)
            #expect(language(.french).string(entry.key) == entry.fr)
        }
    }

    // MARK: Interpolated messages

    @Test func barcodeNotFoundNamesTheCodeInBothLanguages() {
        let code = "5099902988054"
        #expect(language(.english).string("Barcode \(code) not found. Search by name.")
            == "Barcode 5099902988054 not found. Search by name.")
        #expect(language(.french).string("Barcode \(code) not found. Search by name.")
            == "Code-barres 5099902988054 introuvable. Cherche par nom.")
    }

    @Test func lookingUpNamesTheCodeInBothLanguages() {
        let code = "5099902988054"
        #expect(language(.english).string("Looking up \(code)…") == "Looking up 5099902988054…")
        #expect(language(.french).string("Looking up \(code)…") == "Recherche de 5099902988054…")
    }

    @Test func rateNamesTheStarInBothLanguages() {
        #expect(language(.english).string("Rate \(3)") == "Rate 3")
        #expect(language(.french).string("Rate \(3)") == "Noter 3")
    }

    // MARK: Camera prompt

    /// The OS shows the prompt, from InfoPlist.strings, in the device or per-app language (not the in-app switch).
    @Test func cameraPromptIsLocalizedInBothLanguages() throws {
        func prompt(_ code: String) throws -> String? {
            let path = try #require(Bundle.main.path(forResource: "InfoPlist", ofType: "strings", inDirectory: nil, forLocalization: code))
            return NSDictionary(contentsOfFile: path)?["NSCameraUsageDescription"] as? String
        }
        #expect(try prompt("en") == "Vinyl uses the camera to scan the barcodes of your discs.")
        #expect(try prompt("fr") == "Vinyl utilise l’appareil photo pour scanner le code-barres de tes disques.")
    }
}
