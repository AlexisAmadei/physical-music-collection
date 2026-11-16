import SwiftData
import SwiftUI

@main
struct VinylApp: App {
    @State private var app: AppModel

    init() {
        do {
            _app = State(initialValue: AppModel(container: try DiscStore.persistentContainer()))        } catch {
            fatalError("Cannot open the Disc store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup { RootView(app: app) }
    }
}
