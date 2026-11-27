import Foundation

/// A wax color of a vinyl Disc: its Vinyl color, or the Second color of a Finish. No Vinyl color (nil) means black wax;
/// `black` exists only to be a Second color.
/// Mirrors the Android `VinylColor`: same list, same order, same wax colors and labels.
/// New colors go at the end: the raw values are stored.
enum VinylColor: String, Codable, CaseIterable, Sendable {
    case red = "RED", orange = "ORANGE", yellow = "YELLOW", green = "GREEN", blue = "BLUE"
    case purple = "PURPLE", pink = "PINK", white = "WHITE"
    /// See-through: drawn half transparent.
    case clear = "CLEAR"
    case gold = "GOLD", silver = "SILVER", grey = "GREY", brown = "BROWN", teal = "TEAL", bone = "BONE"
    /// Only as a Second color: plain black wax is "no Vinyl color". Same near black as the black wax.
    case black = "BLACK"

    /// The colors offered as the Vinyl color: all but `black`. Order is the order in the form.
    static let firstChoices: [VinylColor] = allCases.filter { $0 != .black }

    /// The colors offered as the Second color: all but `clear`.
    static let secondChoices: [VinylColor] = allCases.filter { $0 != .clear }

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
        case .gold: 0xFFC9_A227
        case .silver: 0xFFB8_BCC2
        case .grey: 0xFF7D_8085
        case .brown: 0xFF6B_4A32
        case .teal: 0xFF1F_8A8A
        case .bone: 0xFFE9_E1CC
        case .black: 0xFF12_1212
        }
    }

    /// The name shown to the user and read by VoiceOver.
    @MainActor
    func label(in language: Language) -> String {
        switch self {
        case .red: language.string("Rouge")
        case .orange: language.string("Orange")
        case .yellow: language.string("Jaune")
        case .green: language.string("Vert")
        case .blue: language.string("Bleu")
        case .purple: language.string("Violet")
        case .pink: language.string("Rose")
        case .white: language.string("Blanc")
        case .clear: language.string("Transparent")
        case .gold: language.string("Or")
        case .silver: language.string("Argent")
        case .grey: language.string("Gris")
        case .brown: language.string("Marron")
        case .teal: language.string("Bleu canard")
        case .bone: language.string("Os")
        case .black: language.string("Noir")
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

    /// Shows the Color band on its cover.
    var hasColorBand: Bool { shownVinylColor != nil }

    /// What VoiceOver reads for its cover: title, artist, Format ("CD", "Vinyle" or "Vinyle couleur <color>"), year.
    /// Mirrors the Android `Disc.a11yLabel()`.
    @MainActor
    func coverLabel(in language: Language) -> String {
        let formatLabel = if let color = shownVinylColor {
            language.string("Vinyle couleur \(color.label(in: language).lowercased())")
        } else {
            format.label(in: language)
        }
        return [
            shownTitle(in: language),
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

    /// The "Vinyle couleur" switch: turning it on picks Rouge, off means black (no Vinyl color) and clears the Finish
    /// and the Second color too.
    var coloredVinyl: Bool {
        get { vinylColor != nil }
        set {
            if newValue {
                vinylColor = vinylColor ?? .red
            } else {
                vinylColor = nil
                finish = nil
                secondColor = nil
            }
        }
    }
}
