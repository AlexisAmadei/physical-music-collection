import SwiftUI

extension VinylColor {
    /// The wax color to draw. Transparent carries its own alpha, so it is drawn half see-through.
    var color: Color {
        Color(hex: argb & 0xFF_FFFF, opacity: Double(argb >> 24) / 255)
    }
}

/// Round holo silver sticker, a dot of the wax color in the middle. Mirrors Android `ColorSticker`.
/// Static for now: the sheen follows the phone tilt in a later ticket.
/// Decorative: the cover's VoiceOver label says the Vinyl color.
struct ColorSticker: View {
    let color: VinylColor

    /// Fixed light position (x, y in -1...1), the Android `StillLight`.
    private static let light = UnitPoint(x: 0.5 + 0.5 * 0.35, y: 0.5 + 0.5 * -0.3)
    private static let base: [Color] = [
        Color(hex: 0xC6CACF), Color(hex: 0xEEF0F2), Color(hex: 0xB6BBC1), Color(hex: 0xE2E5E8), Color(hex: 0xC2C6CB),
    ]
    private static let rim = LinearGradient(
        colors: [.white.opacity(0.9), Color(hex: 0x8A9097, opacity: 0.8)], startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(LinearGradient(colors: Self.base, startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().fill(
                    RadialGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.12), .clear],
                        center: Self.light, startRadius: 0, endRadius: size * 0.7
                    )
                )
                Circle()
                    .fill(color.color)
                    // Light wax (white, clear...) needs an edge to read on silver.
                    .overlay { if color.light { Circle().strokeBorder(.black.opacity(0.3), lineWidth: 0.5) } }
                    .frame(width: size * 0.4, height: size * 0.4)
            }
            .overlay { Circle().strokeBorder(Self.rim, lineWidth: 0.5) }
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.35), radius: 1.5, y: 0.5)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

extension View {
    /// The Color sticker of a cover, top right, if the Disc shows a Vinyl color (pass `shownVinylColor`).
    /// About 22 % of the cover width, never under 14 pt. Apply to the cover itself.
    func colorSticker(_ color: VinylColor?) -> some View {
        overlay(alignment: .topTrailing) {
            if let color {
                GeometryReader { geo in
                    let width = geo.size.width
                    ColorSticker(color: color)
                        .frame(width: max(14, width * 0.22), height: max(14, width * 0.22))
                        .padding(max(3, width * 0.05))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
        }
    }
}

#Preview {
    HStack {
        ForEach(VinylColor.allCases, id: \.self) { ColorSticker(color: $0).frame(width: 32) }
    }
    .padding()
}
