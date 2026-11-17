import SwiftUI

/// "Par format": the Collection value for CD and Vinyle; Discs without a Paid price counted apart.
struct ValueByFormat: View {
    let value: CollectionValue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Par format")
                .textStyle(Typography.label)
                .foregroundStyle(Palette.muted)
                .padding(.bottom, 4)
            row("CD", value.cd)
            row("Vinyle", value.vinyl)
            if value.unpriced > 0 {
                Group {
                    if value.unpriced == 1 { Text("1 disque sans prix") } else { Text("\(value.unpriced) disques sans prix") }
                }
                .textStyle(Typography.body)
                .foregroundStyle(Palette.muted)
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ label: LocalizedStringKey, _ cents: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(verbatim: Price.format(cents)).fontWeight(.medium)
        }
        .textStyle(Typography.body)
        .foregroundStyle(Palette.ink)
        .accessibilityElement(children: .combine)
    }
}

/// "Ton nom": one field for the Profile name, 24 characters at most. Blank clears it.
struct ProfileNameSheet: View {
    let current: String
    let onDone: (String) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ton nom")
                .textStyle(Typography.title)
                .foregroundStyle(Palette.ink)
            VStack(alignment: .leading, spacing: 4) {
                TextField("Ton nom", text: $text)
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.ink)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($focused)
                    .onSubmit { onDone(text) }
                    .onChange(of: text) { _, new in
                        let typed = ProfileName.typed(new)
                        if typed != new { text = typed }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(Palette.ink, lineWidth: 1) }
                Text(verbatim: ProfileName.counter(text))
                    .textStyle(Typography.label)
                    .foregroundStyle(Palette.muted)
                    .padding(.leading, 16)
            }
            Button { onDone(text) } label: {
                Text("OK")
                    .textStyle(Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 48)
                    .background(Palette.ink, in: .capsule)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .presentationDetents([.height(240)])
        .presentationBackground(Palette.surface)
        .presentationDragIndicator(.visible)
        .onAppear {
            text = current
            focused = true
        }
    }
}
