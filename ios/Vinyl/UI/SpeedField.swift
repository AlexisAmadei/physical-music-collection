import SwiftUI

/// "Vitesse": a two-option 33 | 45 segmented control, nothing selected at first. Tapping the selected one clears it.
/// Mirrors the Android `SpeedField`. Shown on vinyl Drafts only.
struct SpeedField: View {
    @Binding var draft: Draft
    let language: Language

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vitesse")
            HStack(spacing: 2) {
                ForEach(Speed.allCases, id: \.self) { speed in
                    let selected = draft.speed == speed
                    Button { draft.speed = draft.speed.tapped(speed) } label: {
                        Text(verbatim: speed.rpmText)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .foregroundStyle(selected ? Color.white : Palette.ink)
                            .background(selected ? Palette.ink : .clear, in: .rect(cornerRadius: 8))
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(speed.label(in: language))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(2)
            .background(Palette.tint, in: .rect(cornerRadius: 10))
        }
    }
}
