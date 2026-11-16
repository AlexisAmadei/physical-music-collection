import SwiftUI

/// Design tokens ("Physical" handoff v1), mirroring Android `ui/Theme.kt`. Reference frame 412 × 917 pt.
enum Palette {
    static let ink = Color(hex: 0x241111)
    static let accent = Color(hex: 0xFF8181)
    static let muted = Color(hex: 0x797979)
    static let line = Color(hex: 0xD9D9D9)
    static let surface = Color.white
    static let thumb = Color.black
    static let placeholder = Color(hex: 0xEEEEEE)
    static let tint = Color(hex: 0xF6F4F4)
}

/// A text style token: Lexend at a size, weight, line height and letter spacing (all in points).
struct TextStyle: Sendable {
    enum Weight: String, Sendable {
        case regular = "Lexend-Regular", medium = "Lexend-Medium", semibold = "Lexend-SemiBold", bold = "Lexend-Bold"
    }

    var size: CGFloat
    var lineHeight: CGFloat
    var weight = Weight.regular
    var letterSpacing: CGFloat = 0

    var font: Font { .custom(weight.rawValue, fixedSize: size) }
}

/// Text styles, mirroring Android `Type`.
enum Typography {
    static let display = TextStyle(size: 32, lineHeight: 36, weight: .bold, letterSpacing: 0.5)
    static let title = TextStyle(size: 20, lineHeight: 24, weight: .bold)
    static let welcome = TextStyle(size: 20, lineHeight: 28, weight: .bold, letterSpacing: -0.2)
    static let body = TextStyle(size: 16, lineHeight: 22)
    static let chip = TextStyle(size: 14, lineHeight: 20)
    static let label = TextStyle(size: 13, lineHeight: 18)
}

extension View {
    /// Applies a text style token.
    func textStyle(_ style: TextStyle) -> some View {
        font(style.font)
            .tracking(style.letterSpacing)
            // Lexend's natural line is 1.25 × size; add the rest of the token's line height between lines.
            .lineSpacing(max(0, style.lineHeight - style.size * 1.25))
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
