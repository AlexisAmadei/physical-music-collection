import SwiftUI

/// "English | Français": the Language switch. Each name is in its own language and never translated.
struct LanguagePicker: View {
    let language: Language

    var body: some View {
        Picker("Langue", selection: Binding(get: { language.current }, set: { language.select($0) })) {
            ForEach(AppLanguage.allCases) { Text(verbatim: $0.nativeName).tag($0) }
        }
        .pickerStyle(.segmented)
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
