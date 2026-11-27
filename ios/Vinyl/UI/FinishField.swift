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
                                    FinishSwatch(finish: finish, color: color, second: draft.secondColor ?? finish?.defaultSecondColor, seed: draft.waxSeed)
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

/// A round preview of a Finish in the form, drawn like the wax of the Disc: same colors, same pattern.
/// Solid is the plain color; the others are rendered off the main thread and cached.
struct FinishSwatch: View {
    let finish: Finish?
    let color: VinylColor
    let second: VinylColor?
    let seed: UInt64
    @Environment(\.displayScale) private var displayScale
    @State private var rendered: RenderedWax?

    private var look: WaxLook? {
        guard let finish else { return nil }
        return WaxLook(base: color, finish: finish, second: second, seed: seed, side: Int((40 * displayScale).rounded()), marbleSide: 64)
    }

    var body: some View {
        let currentLook = look
        let image = rendered.image(for: currentLook)
        Group {
            if let image {
                Image(decorative: image, scale: displayScale).resizable()
            } else {
                Circle().fill(color.color)
            }
        }
        .clipShape(Circle())
        .overlay { Circle().strokeBorder(Palette.line, lineWidth: 1) }
        .accessibilityHidden(true)
        .task(id: currentLook) { rendered = await WaxRenderer.renderedOffMain(currentLook) }
    }
}

#Preview {
    HStack {
        ForEach([nil] + Finish.allCases.map(Optional.some), id: \.self) { finish in
            FinishSwatch(finish: finish, color: .red, second: finish?.defaultSecondColor, seed: 42).frame(width: 40, height: 40)
        }
    }
    .padding()
}
