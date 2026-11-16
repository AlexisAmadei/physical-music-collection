import SwiftData
import SwiftUI

@main
struct VinylApp: App {
    @State private var app: AppModel

    init() {
        do {
            _app = State(initialValue: AppModel(container: try DiscStore.persistentContainer()))
        } catch {
            fatalError("Cannot open the Disc store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup { RootView(app: app) }
    }
}

/// Collection with the "+" button. The custom nav pill and the other screens come in later tickets.
struct RootView: View {
    let app: AppModel
    @State private var editing = false

    var body: some View {
        CollectionScreen(app: app)
            .overlay(alignment: .bottomLeading) {
                Button {
                    app.newDraft()
                    editing = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 56, height: 56)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("Ajouter un disque")
                .padding(.leading, 20)
                .padding(.bottom, 21)
            }
            .sheet(isPresented: $editing) {
                NavigationStack { DraftScreen(app: app) { editing = false } }
            }
    }
}

#Preview {
    RootView(app: AppModel(container: try! DiscStore.inMemoryContainer()))
}
