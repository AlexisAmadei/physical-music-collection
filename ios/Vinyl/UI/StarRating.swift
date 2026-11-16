import SwiftUI

/// Read-only 0 to 5 stars, read as one element: "Note : n sur 5" or "Non noté". Mirrors Android `StarRating`.
struct StarRating: View {
    let rating: Int
    var size: CGFloat = 15

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                StarShape()
                    .fill(star <= rating ? Palette.ink : Palette.line)
                    .frame(width: size, height: size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rating > 0 ? Text("Note : \(rating) sur 5") : Text("Non noté"))
    }
}

/// Five star buttons for the Draft: tapping a star rates, tapping the current star clears.
struct StarPicker: View {
    @Binding var draft: Draft

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Button { draft.tapStar(star) } label: {
                    Image(systemName: star <= draft.rating ? "star.fill" : "star")
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Rate \(star)"))
                .accessibilityAddTraits(star <= draft.rating ? .isSelected : [])
            }
        }
    }
}

/// The Android `Glyphs.Star` path, drawn in a 24 × 24 box scaled to the frame.
struct StarShape: Shape {
    private static let points: [CGPoint] = [
        (12, 2.5), (14.9, 8.6), (21.5, 9.4), (16.6, 14), (17.9, 20.6),
        (12, 17.3), (6.1, 20.6), (7.4, 14), (2.5, 9.4), (9.1, 8.6),
    ].map { CGPoint(x: $0.0, y: $0.1) }

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        var path = Path()
        path.addLines(Self.points.map { CGPoint(x: rect.minX + $0.x * scale, y: rect.minY + $0.y * scale) })
        path.closeSubpath()
        return path
    }
}
