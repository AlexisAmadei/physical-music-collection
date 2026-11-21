import SwiftUI

extension VinylColor {
    /// The wax color to draw. Transparent carries its own alpha, so it is drawn half see-through.
    var color: Color {
        Color(hex: argb & 0xFF_FFFF, opacity: Double(argb >> 24) / 255)
    }
}

/// The diagonal band cutting the top-right corner of a square cover. Mirrors Android `ColorBand`: 11 % of the cover
/// width thick, never under 8 pt, cutting 4 thicknesses off each cover edge.
struct ColorBandShape: Shape {
    static let share = 0.11
    static let minThickness = 8.0
    /// Length of the cut corner along each cover edge, in band thicknesses.
    static let leg = 4.0

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let thickness = max(Self.minThickness, w * Self.share)
        let centre = w - Self.leg * thickness
        let half = thickness / 2.0.squareRoot()
        // The band's two long edges run from the top edge to the right edge of the cover.
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + centre - half, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + centre + half, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + w - (centre + half)))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + w - (centre - half)))
        path.closeSubpath()
        return path
    }
}

/// Flat band of the wax color across the top-right corner of a cover. Decorative: the cover's VoiceOver label says
/// the Vinyl color. Fills the cover it is drawn on.
struct ColorBand: View {
    let color: VinylColor

    /// Clear wax is a frosted band, mostly opaque so it still reads over the cover art.
    private static let clearOpacity = 0.75

    var body: some View {
        ZStack {
            // Small drop shadow, kept off the band itself so frosted wax does not darken.
            ColorBandShape()
                .fill(.black.opacity(0.3))
                .offset(y: 0.75)
                .mask {
                    Rectangle().overlay { ColorBandShape().blendMode(.destinationOut) }.compositingGroup()
                }
            ColorBandShape().fill(color == .clear ? Color(hex: color.argb & 0xFF_FFFF, opacity: Self.clearOpacity) : color.color)
            // Light wax (white, clear...) needs an edge to read on the cover.
            if color.light { ColorBandShape().stroke(.black.opacity(0.3), lineWidth: 0.5) }
        }
        .accessibilityHidden(true)
    }
}

extension View {
    /// The Color band of a cover, across its top-right corner, if the Disc shows a Vinyl color (pass `shownVinylColor`).
    /// Apply to the cover itself.
    func colorBand(_ color: VinylColor?) -> some View {
        overlay { if let color { ColorBand(color: color) } }
    }
}

#Preview {
    HStack {
        ForEach(VinylColor.allCases, id: \.self) { color in
            Color.gray.frame(width: 64, height: 64).colorBand(color)
        }
    }
    .padding()
}
