import SwiftUI

/// The Draft form: add or edit a Disc. Edits `app.draft`; Save and Delete hand it to the app model.
/// `onDone` runs after Save or Delete: the presenter uses it to go back to the previous screen.
struct DraftScreen: View {
    @Bindable var app: AppModel
    var onDone: () -> Void = {}

    var body: some View {
        Form {
            TextField("Title", text: $app.draft.title)
            TextField("Artist", text: $app.draft.artist)
            TextField("Year", text: $app.draft.yearText)
                .keyboardType(.numberPad)
            TextField("Barcode", text: $app.draft.barcodeText)
            Picker("Format", selection: $app.draft.format) {
                Text("CD").tag(Format.cd)
                Text("VINYL").tag(Format.vinyl)
            }
            .pickerStyle(.segmented)
            if app.draft.format == .vinyl { VinylColorField(draft: $app.draft) }
            StarPicker(draft: $app.draft)
            TextField("Comment", text: $app.draft.comment, axis: .vertical)
            DraftPriceFields(draft: $app.draft)
            Section {
                Button("Save") {
                    app.saveDraft()
                    onDone()
                }
                .disabled(!app.canSaveDraft)
                if !app.draft.isNew {
                    Button("Delete", role: .destructive) {
                        app.deleteDraft()
                        onDone()
                    }
                }
            }
        }
        .navigationTitle(app.draft.isNew ? "Add disc" : "Edit disc")
    }
}
