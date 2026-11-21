import Foundation
@testable import Vinyl

extension Language {
    /// A Language pinned to `language`, kept in memory: never the device's, never the real preferences.
    @MainActor
    static func pinned(_ language: AppLanguage) -> Language {
        Language(preferences: InMemoryLanguagePreferences(language: language), deviceLanguages: [])
    }
}

extension AppModel {
    /// An app model on an in-memory store, its Language pinned to `language`.
    @MainActor
    static func pinned(_ language: AppLanguage = .french) throws -> AppModel {
        try AppModel(
            container: DiscStore.inMemoryContainer(),
            languagePreferences: InMemoryLanguagePreferences(language: language),
            deviceLanguages: []
        )
    }
}
