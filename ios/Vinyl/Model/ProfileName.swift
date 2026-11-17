import Foundation

/// The name the user types for the Profile card. Blank = unset. Port of the Android `ProfileName`.
enum ProfileName {
    static let max = 24

    /// Trimmed, cut to `max` characters, trimmed again.
    static func clean(_ raw: String) -> String {
        String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(max))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The "Ton nom" field while typing: stops at `max` characters, spaces kept (`clean` trims on OK).
    static func typed(_ text: String) -> String {
        String(text.prefix(max))
    }

    /// The counter under the "Ton nom" field: "7 / 24".
    static func counter(_ text: String) -> String {
        "\(text.count) / \(max)"
    }
}

/// Where the Profile name is kept: on-device preferences only, never synced. nil = unset.
@MainActor
protocol ProfilePreferences: AnyObject {
    var name: String? { get set }
}

/// The real preferences: `UserDefaults`, key "profile.name".
@MainActor
final class UserDefaultsProfilePreferences: ProfilePreferences {
    private let defaults: UserDefaults
    private static let key = "profile.name"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var name: String? {
        get { defaults.string(forKey: Self.key) }
        set {
            if let newValue { defaults.set(newValue, forKey: Self.key) } else { defaults.removeObject(forKey: Self.key) }
        }
    }
}

/// Preferences that live in memory: tests and previews.
@MainActor
final class InMemoryProfilePreferences: ProfilePreferences {
    var name: String?

    init(name: String? = nil) {
        self.name = name
    }
}
