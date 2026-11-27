import Foundation

/// How a vinyl Disc's wax is patterned. No value (nil) means Solid, so existing Discs stay Solid. A Finish is drawn from
/// the Vinyl color and, if it uses a Second color, from the Second color, which starts as `defaultSecondColor`.
/// Mirrors the Android `Finish`: same list, same order, same defaults and labels. The raw values are stored.
enum Finish: String, Codable, CaseIterable, Sendable {
    case marble = "MARBLE", splatter = "SPLATTER", split = "SPLIT", galaxy = "GALAXY", glitter = "GLITTER"

    /// White, or Black for Split; nil for Glitter, which has no Second color.
    var defaultSecondColor: VinylColor? {
        switch self {
        case .marble, .splatter, .galaxy: .white
        case .split: .black
        case .glitter: nil
        }
    }

    /// Marble, Splatter, Split and Galaxy take a Second color; Glitter is silver flecks on the Vinyl color.
    var usesSecondColor: Bool { defaultSecondColor != nil }

    /// The name shown to the user and read by VoiceOver.
    @MainActor
    func label(in language: Language) -> String {
        switch self {
        case .marble: language.string("Marbré")
        case .splatter: language.string("Splatter")
        case .split: language.string("Bicolore")
        case .galaxy: language.string("Galaxy")
        case .glitter: language.string("Pailleté")
        }
    }

    /// A Finish shows only on a vinyl Disc that shows a Vinyl color. A CD keeps its value hidden.
    static func shown(_ finish: Finish?, vinylColor: VinylColor?, on format: Format) -> Finish? {
        VinylColor.shown(vinylColor, on: format) == nil ? nil : finish
    }

    /// A Second color shows only for a shown Finish that uses one, falling back to that Finish's default.
    static func shownSecondColor(_ secondColor: VinylColor?, for shownFinish: Finish?) -> VinylColor? {
        guard let shownFinish, shownFinish.usesSecondColor else { return nil }
        return secondColor ?? shownFinish.defaultSecondColor
    }
}

extension Optional where Wrapped == Finish {
    /// The name of the Finish in the language; nil is Solid ("Unie", "Solid" in English).
    @MainActor
    func label(in language: Language) -> String {
        switch self {
        case .none: language.string("Unie")
        case .some(let finish): finish.label(in: language)
        }
    }
}

extension Disc {
    /// The Finish as shown: only on a vinyl Disc that shows a Vinyl color. A CD keeps its value hidden.
    var shownFinish: Finish? { Finish.shown(finish, vinylColor: vinylColor, on: format) }

    /// The Second color as shown: only for a shown Finish that uses one.
    var shownSecondColor: VinylColor? { Finish.shownSecondColor(secondColor, for: shownFinish) }
}

extension Draft {
    /// The Finish as shown: only on a vinyl Draft that shows a Vinyl color.
    var shownFinish: Finish? { Finish.shown(finish, vinylColor: vinylColor, on: format) }

    /// The Second color as shown: only for a shown Finish that uses one.
    var shownSecondColor: VinylColor? { Finish.shownSecondColor(secondColor, for: shownFinish) }

    /// The Draft form shows the Finish choice on vinyl Drafts that have a Vinyl color.
    var showsFinishField: Bool { shownVinylColor != nil }

    /// Picking a Finish in the form (nil = Solid). A Finish that uses a Second color keeps the one already set, or gets
    /// its default; going back to Solid keeps the Second color so it comes back with the next Finish.
    mutating func pickFinish(_ picked: Finish?) {
        finish = picked
        if let picked, picked.usesSecondColor {
            secondColor = secondColor ?? picked.defaultSecondColor
        }
    }
}
