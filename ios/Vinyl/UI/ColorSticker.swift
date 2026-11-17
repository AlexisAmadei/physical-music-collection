import SwiftUI

extension VinylColor {
    /// The wax color to draw. Transparent carries its own alpha, so it is drawn half see-through.
    var color: Color {
        Color(hex: argb & 0xFF_FFFF, opacity: Double(argb >> 24) / 255)
    }
}

/// Round holo silver sticker, a dot of the wax color in the middle. Mirrors Android `ColorSticker`: the same silver
/// as the Profile card without the brush lines, its sheen following the phone tilt (`HoloLight`), fixed with
/// Reduce Motion. Decorative: the cover's VoiceOver label says the Vinyl color.
struct ColorSticker: View {
    let color: VinylColor

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let rim = LinearGradient(
        colors: [.white.opacity(0.9), Color(hex: 0x8A9097, opacity: 0.8)], startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                SilverSheen(tilt: reduceMotion ? ProfileCard.stillLight : HoloLight.shared.light)
                    .clipShape(Circle())
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
        .onAppear { HoloLight.shared.addReader() }
        .onDisappear { HoloLight.shared.removeReader() }
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
