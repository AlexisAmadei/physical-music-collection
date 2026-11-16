import SwiftUI

/// The Draft form: add or edit a Disc. Edits `app.draft`; Save hands it to the app model.
struct DraftScreen: View {
    @Bindable var app: AppModel
    var onDone: () -> Void = {}

    var body: some View {
        Form {
            TextField("Title", text: $app.draft.title)
            TextField("Artist", text: $app.draft.artist)
            TextField("Year", text: year)
                .keyboardType(.numberPad)
            Picker("Format", selection: $app.draft.format) {
                Text("CD").tag(Format.cd)
                Text("VINYL").tag(Format.vinyl)
            }
            .pickerStyle(.segmented)
            Button("Save") {
                app.saveDraft()
                onDone()
            }
        }
        .navigationTitle(app.draft.isNew ? "Add disc" : "Edit disc")
    }

    /// Year as text; anything that is not a number means no year.
    private var year: Binding<String> {
        Binding(
            get: { app.draft.year.map(String.init) ?? "" },
            set: { app.draft.year = Int($0) }
        )
    }
}
