import Foundation

/// The color of a vinyl Disc's wax. No value (nil) means black. Solid colors only.
/// Mirrors the Android `VinylColor`: same list, same order, same wax colors and labels.
enum VinylColor: String, Codable, CaseIterable, Sendable {
    case red = "RED", orange = "ORANGE", yellow = "YELLOW", green = "GREEN", blue = "BLUE"
    case purple = "PURPLE", pink = "PINK", white = "WHITE"
    /// See-through: drawn half transparent.
    case clear = "CLEAR"

    /// Wax color as 0xAARRGGBB, as on Android.
    var argb: UInt32 {
        switch self {
        case .red: 0xFFC8_242B
        case .orange: 0xFFE8_731E
        case .yellow: 0xFFF2_C94C
        case .green: 0xFF2E_8B57
        case .blue: 0xFF2B_5BA8
        case .purple: 0xFF6B_3FA0
        case .pink: 0xFFE0_609A
        case .white: 0xFFF4_F2EE
        case .clear: 0x8CE6_ECF0
        }
    }

    /// The name shown to the user and read by VoiceOver.
    var label: String {
        switch self {
        case .red: String(localized: "Rouge")
        case .orange: String(localized: "Orange")
        case .yellow: String(localized: "Jaune")
        case .green: String(localized: "Vert")
        case .blue: String(localized: "Bleu")
        case .purple: String(localized: "Violet")
        case .pink: String(localized: "Rose")
        case .white: String(localized: "Blanc")
        case .clear: String(localized: "Transparent")
        }
    }

    /// Light wax needs dark grooves, or they vanish.
    var light: Bool { luminance > 0.4 }

    /// Relative luminance (sRGB), alpha ignored.
    private var luminance: Double {
        func lin(_ shift: UInt32) -> Double {
            let c = Double((argb >> shift) & 0xFF) / 255
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(16) + 0.7152 * lin(8) + 0.0722 * lin(0)
    }

    /// A Vinyl color shows only on vinyl. A CD keeps its value hidden.
    static func isShown(on format: Format) -> Bool { format == .vinyl }

    /// The Vinyl color as shown: only on vinyl. A CD keeps its value hidden.
    static func shown(_ color: VinylColor?, on format: Format) -> VinylColor? {
        isShown(on: format) ? color : nil
    }
}

extension Disc {
    /// The Vinyl color as shown: only on vinyl. A CD keeps its value hidden.
    var shownVinylColor: VinylColor? { VinylColor.shown(vinylColor, on: format) }

    /// Shows the Color sticker on its cover.
    var hasColorSticker: Bool { shownVinylColor != nil }

    /// What VoiceOver reads for its cover: title, artist, Format ("CD", "Vinyle" or "Vinyle couleur <color>"), year.
    /// Mirrors the Android `Disc.a11yLabel()`.
    var coverLabel: String {
        let formatLabel = if let color = shownVinylColor {
            String(localized: "Vinyle couleur \(color.label.lowercased())")
        } else {
            format.label
        }
        return [
            shownTitle,
            shownArtist,
            formatLabel,
            year.map(String.init),
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}

extension Draft {
    /// The Vinyl color as shown: only on vinyl. A CD Draft keeps its value hidden.
    var shownVinylColor: VinylColor? { VinylColor.shown(vinylColor, on: format) }

    /// The Draft form shows the "Vinyle couleur" field on vinyl Drafts only.
    var showsVinylColorField: Bool { VinylColor.isShown(on: format) }

    /// The "Vinyle couleur" switch: turning it on picks Rouge, off means black (no Vinyl color).
    var coloredVinyl: Bool {
        get { vinylColor != nil }
        set { vinylColor = newValue ? vinylColor ?? .red : nil }
    }
}
