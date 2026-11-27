import Foundation
import Testing

/// The String Catalogs are the one source of every user-visible text: each key carries an English and a French
/// translation (plural forms for the counts), so a missing language fails here, not on a device.
/// Mirrors the Android `StringResourcesTest`, which checks `values/` against `values-fr/`.
struct CatalogCompletenessTests {
    /// A catalog file read straight from the source tree, which the test host shares with the simulator.
    private func catalog(_ name: String) throws -> [String: [String: Any]] {
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Vinyl")
        let data = try Data(contentsOf: sources.appendingPathComponent("\(name).xcstrings"))
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try #require(root["strings"] as? [String: [String: Any]])
    }

    /// The text of one localization: a plain value, or every plural form it has.
    private func texts(_ localization: [String: Any]?) -> [String] {
        guard let localization else { return [] }
        if let unit = localization["stringUnit"] as? [String: Any], let value = unit["value"] as? String { return [value] }
        let variations = localization["variations"] as? [String: [String: [String: Any]]] ?? [:]
        return variations.values.flatMap { $0.values }.compactMap { ($0["stringUnit"] as? [String: Any])?["value"] as? String }
    }

    @Test(arguments: ["Localizable", "InfoPlist"])
    func everyKeyHasAnEnglishAndAFrenchText(name: String) throws {
        let strings = try catalog(name)
        #expect(!strings.isEmpty)
        for (key, entry) in strings {
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            for language in ["en", "fr"] {
                let values = texts(localizations[language])
                #expect(!values.isEmpty && !values.contains(where: \.isEmpty), "\(name): \"\(key)\" has no \(language) text")
            }
        }
    }

    /// Format labels come from the model (`Format.label`), not from a screen-specific key.
    @Test func noScreenSpecificFormatKeyLeftBehind() throws {
        #expect(try catalog("Localizable")["collection.filter.vinyl"] == nil)
    }
}
