import SwiftUI

/// The "+" choice: scan, catalog search or manual entry (Android `AddChoices`), as a menu on any label.
struct AddChoicesMenu<Label: View>: View {
    let app: AppModel
    @ViewBuilder var label: () -> Label

    var body: some View {
        Menu {
            ForEach(AddChoice.allCases, id: \.self) { choice in
                Button(choice.label) { app.choose(choice) }
            }
        } label: {
            label()
        }
        .menuOrder(.fixed)
    }
}

extension AddChoice {
    var label: LocalizedStringKey {
        switch self {
        case .scan: "Scanner un code-barres"
        case .search: "Rechercher un album"
        case .manual: "Saisie manuelle"
        }
    }
}

/// "Rien ici pour l’instant." + hint + filled Ink button (Android `EmptyState`).
struct EmptyState<Action: View>: View {
    let hint: LocalizedStringKey
    @ViewBuilder var action: () -> Action

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rien ici pour l’instant.")
                .textStyle(Typography.welcome)
                .foregroundStyle(Palette.ink)
            Text(hint)
                .textStyle(Typography.body)
                .foregroundStyle(Palette.muted)
            action()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension EmptyState where Action == AddChoicesMenu<EmptyStateButtonLabel> {
    /// Empty Home, Collection or Profile: "Ajouter mon premier disque" opens the add choices.
    init(app: AppModel) {
        self.init(hint: "Scanne un code-barres ou cherche un album pour commencer.") {
            AddChoicesMenu(app: app) { EmptyStateButtonLabel(text: "Ajouter mon premier disque") }
        }
    }
}

/// The empty state's filled Ink pill.
struct EmptyStateButtonLabel: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .textStyle(Typography.body)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(height: 48)
            .background(Palette.ink, in: .capsule)
    }
}
