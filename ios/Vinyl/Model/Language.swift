import Foundation
import Observation

/// A language the app is written in. French is the source language of the String Catalog.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case french = "fr"

    var id: String { rawValue }

    /// The language's own name, shown as is in the switch and never translated.
    var nativeName: String {
        switch self {
        case .english: "English"
        case .french: "Français"
        }
    }

    /// The first of the device's preferred languages the app has; English when it has none.
    static func forDevice(_ preferred: [String]) -> AppLanguage {
        for identifier in preferred {
            let code = Locale.Language(identifier: identifier).languageCode?.identifier
            if let language = AppLanguage(rawValue: code ?? "") { return language }
        }
        return .english
    }
}

/// Where the user's language pick is kept: on-device preferences only. nil = never picked, follow the device.
@MainActor
protocol LanguagePreferences: AnyObject {
    var language: AppLanguage? { get set }
}

/// The real preferences: `UserDefaults`, key "profile.language".
@MainActor
final class UserDefaultsLanguagePreferences: LanguagePreferences {
    private let defaults: UserDefaults
    private static let key = "profile.language"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var language: AppLanguage? {
        get { defaults.string(forKey: Self.key).flatMap(AppLanguage.init(rawValue:)) }
        set {
            if let newValue { defaults.set(newValue.rawValue, forKey: Self.key) } else { defaults.removeObject(forKey: Self.key) }
        }
    }
}

/// Preferences that live in memory: tests and previews.
@MainActor
final class InMemoryLanguagePreferences: LanguagePreferences {
    var language: AppLanguage?

    init(language: AppLanguage? = nil) {
        self.language = language
    }
}

/// The Language: the one place that knows which language the app shows (the Android equivalent of its language holder).
///
/// Device language until the user picks one in the Profile (English for any non-French device); the pick wins after.
/// SwiftUI views read `locale` (put in the environment at the root) and get their text from the String Catalog.
/// Anything that builds text outside a view asks `string(_:)`, which uses `bundle` and `locale`, so it follows the
/// switch too. Ticket #28 moves the model-layer `String(localized:)` calls here.
@MainActor
@Observable
final class Language {
    /// The language shown now. Change it with `select(_:)`.
    private(set) var current: AppLanguage
    @ObservationIgnored private let preferences: any LanguagePreferences

    /// - Parameters:
    ///   - preferences: where the pick is kept; `UserDefaults` by default, in memory in tests.
    ///   - deviceLanguages: the device's preferred languages, e.g. "fr-FR"; the real ones by default.
    init(
        preferences: any LanguagePreferences = UserDefaultsLanguagePreferences(),
        deviceLanguages: [String] = Locale.preferredLanguages
    ) {
        self.preferences = preferences
        current = preferences.language ?? AppLanguage.forDevice(deviceLanguages)
    }

    /// Switches to the language right away and keeps the pick for the next launch.
    func select(_ language: AppLanguage) {
        current = language
        preferences.language = language
    }

    /// The locale SwiftUI views get through the environment.
    var locale: Locale { Locale(identifier: current.rawValue) }

    /// The app's String Catalog localization for the current language.
    var bundle: Bundle {
        Bundle.main.path(forResource: current.rawValue, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
    }

    /// Text for a String Catalog key, in the current language.
    func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: bundle, locale: locale)
    }
}
