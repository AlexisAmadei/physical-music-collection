import SwiftData
import SwiftUI

@main
struct VinylApp: App {
    @State private var app: AppModel

    init() {
        do {
            #if DEBUG
            let container = try DebugSeed.containerIfRequested() ?? DiscStore.persistentContainer()
            #else
            let container = try DiscStore.persistentContainer()
            #endif
            _app = State(initialValue: AppModel(container: container))
        } catch {
            fatalError("Cannot open the Disc store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup { RootView(app: app) }
    }
}
