import SwiftUI

/// The Draft form: add or edit a Disc. Edits `app.draft`; Save and Delete hand it to the app model,
/// then go back to the previous screen.
struct DraftScreen: View {
    @Bindable var app: AppModel

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
            if app.draft.showsVinylColorField { VinylColorField(draft: $app.draft, language: app.language) }
            if app.draft.showsFinishField { FinishField(draft: $app.draft, language: app.language) }
            if app.draft.showsSpeedField { SpeedField(draft: $app.draft, language: app.language) }
            StarPicker(draft: $app.draft)
            TextField("Comment", text: $app.draft.comment, axis: .vertical)
            DraftPriceFields(draft: $app.draft, language: app.language)
            Section {
                Button("Save") {
                    app.saveDraft()
                    app.back()
                }
                .disabled(!app.canSaveDraft)
                if !app.draft.isNew {
                    Button("Delete", role: .destructive) {
                        app.deleteDraft()
                        app.back()
                    }
                }
            }
        }
        .navigationTitle(app.draft.isNew ? Text("Add disc") : Text("Edit disc"))
    }
}
