import SwiftUI

/// "Vinyle couleur" switch; when on, a row of dots, the picked one ringed. Off = black (no Vinyl color).
/// Mirrors the Android `VinylColorField`. Shown on vinyl Drafts only.
struct VinylColorField: View {
    @Binding var draft: Draft
    let language: Language

    var body: some View {
        Toggle("Vinyle couleur", isOn: $draft.coloredVinyl)
        if let picked = draft.vinylColor {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VinylColor.firstChoices, id: \.self) { color in
                        Button { draft.vinylColor = color } label: {
                            Circle()
                                .fill(color.color)
                                .overlay { Circle().strokeBorder(Palette.line, lineWidth: 1) }
                                .frame(width: 24, height: 24)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Circle().strokeBorder(color == picked ? Palette.ink : .clear, lineWidth: 2)
                                }
                                .frame(width: 44, height: 44)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(color.label(in: language))
                        .accessibilityAddTraits(color == picked ? .isSelected : [])
                    }
                }
            }
        }
    }
}
