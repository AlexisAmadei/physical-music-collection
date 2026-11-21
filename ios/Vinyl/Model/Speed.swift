import Foundation

/// Speed of a vinyl Disc: the RPM it plays at. Only 33 or 45; no value (nil) means not set.
/// Mirrors the Android `Speed`: the raw value is the RPM.
enum Speed: Int, Codable, CaseIterable, Sendable {
    case rpm33 = 33
    case rpm45 = 45

    /// "33" or "45", the text of its button in the form.
    var rpmText: String { String(rawValue) }

    /// "33 tr/min" or "45 tr/min", as shown on the Disc detail.
    var label: String { String(localized: "\(rawValue) tr/min") }

    /// A Speed shows only on vinyl. A CD keeps its value hidden.
    static func shown(_ speed: Speed?, on format: Format) -> Speed? {
        format == .vinyl ? speed : nil
    }
}

extension Optional where Wrapped == Speed {
    /// The new Speed after tapping `picked` in the form: tapping the selected one clears it.
    func tapped(_ picked: Speed) -> Speed? {
        self == picked ? nil : picked
    }
}

extension Disc {
    /// The Speed as shown: only on vinyl. A CD keeps its value hidden.
    var shownSpeed: Speed? { Speed.shown(speed, on: format) }

    /// "33 tr/min" / "45 tr/min" for the Disc detail; nil when nothing should show.
    var speedLabel: String? { shownSpeed?.label }
}

extension Draft {
    /// The Speed as shown: only on vinyl. A CD Draft keeps its value hidden.
    var shownSpeed: Speed? { Speed.shown(speed, on: format) }

    /// The Draft form shows the "Vitesse" control on vinyl Drafts only.
    var showsSpeedField: Bool { format == .vinyl }
}
