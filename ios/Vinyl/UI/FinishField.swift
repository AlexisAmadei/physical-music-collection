import SwiftUI

/// The Finish choice of the Draft form, under the Vinyl color: Solid then each Finish as a round preview with its name,
/// the picked one ringed. A Finish that uses a Second color adds a row of dots for it.
/// Mirrors the Android `FinishField`. Shown on vinyl Drafts with a Vinyl color.
struct FinishField: View {
    @Binding var draft: Draft
    let language: Language

    /// Solid (nil) first, then the Finishes in their order.
    private static let options: [Finish?] = [nil] + Finish.allCases.map(Optional.some)

    var body: some View {
        if let color = draft.shownVinylColor {
            VStack(alignment: .leading, spacing: 8) {
                Text("Finition").font(.subheadline.weight(.medium))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.options, id: \.self) { finish in
                            let picked = finish == draft.finish
                            let name = finish.label(in: language)
                            Button { draft.pickFinish(finish) } label: {
                                VStack(spacing: 4) {
                                    FinishSwatch(finish: finish, color: color, second: draft.secondColor ?? finish?.defaultSecondColor)
                                        .frame(width: 40, height: 40)
                                        .padding(4)
                                        .overlay { Circle().strokeBorder(picked ? Palette.ink : .clear, lineWidth: 2) }
                                    Text(name).font(.caption2)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 2)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(name)
                            .accessibilityAddTraits(picked ? .isSelected : [])
                        }
                    }
                }
                if let finish = draft.finish, finish.usesSecondColor {
                    Text("Deuxième couleur").font(.subheadline.weight(.medium))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(VinylColor.secondChoices, id: \.self) { second in
                                let picked = second == draft.shownSecondColor
                                Button { draft.secondColor = second } label: {
                                    Circle()
                                        .fill(second.color)
                                        .overlay { Circle().strokeBorder(Palette.line, lineWidth: 1) }
                                        .frame(width: 24, height: 24)
                                        .frame(width: 32, height: 32)
                                        .overlay { Circle().strokeBorder(picked ? Palette.ink : .clear, lineWidth: 2) }
                                        .frame(width: 44, height: 44)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(second.label(in: language))
                                .accessibilityAddTraits(picked ? .isSelected : [])
                            }
                        }
                    }
                }
            }
        }
    }
}

/// A round hint of a Finish in the form. A stand-in until the wax drawing exists: Split is two halves, Marble, Splatter
/// and Galaxy are the Vinyl color with spots of the Second color, Glitter has silver flecks.
struct FinishSwatch: View {
    let finish: Finish?
    let color: VinylColor
    let second: VinylColor?

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let c2 = (second ?? .white).color
            func dot(_ x: Double, _ y: Double, _ r: Double, _ fill: Color) {
                context.fill(Path(ellipseIn: CGRect(x: w * x - w * r, y: w * y - w * r, width: 2 * w * r, height: 2 * w * r)), with: .color(fill))
            }
            switch finish {
            case nil: break
            case .split: context.fill(Path(CGRect(x: w / 2, y: 0, width: w / 2, height: size.height)), with: .color(c2))
            case .marble, .splatter, .galaxy:
                dot(0.32, 0.34, 0.22, c2)
                dot(0.70, 0.62, 0.14, c2)
                dot(0.40, 0.78, 0.08, c2)
            case .glitter:
                for (x, y) in [(0.25, 0.3), (0.6, 0.22), (0.72, 0.55), (0.35, 0.65), (0.55, 0.8)] {
                    dot(x, y, 0.045, Color(white: 0.9))
                }
            }
        }
        .background(color.color)
        .clipShape(Circle())
        .overlay { Circle().strokeBorder(Palette.line, lineWidth: 1) }
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        ForEach([nil] + Finish.allCases.map(Optional.some), id: \.self) { finish in
            FinishSwatch(finish: finish, color: .red, second: finish?.defaultSecondColor).frame(width: 40, height: 40)
        }
    }
    .padding()
}
