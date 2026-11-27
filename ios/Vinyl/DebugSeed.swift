#if DEBUG
import SwiftData
import SwiftUI

/// Debug builds only: launch with `-seedDiscs 240` to open the app on an in-memory store filled with that many
/// Collection Discs (generated covers), to check the cover wheel by eye with a large Collection.
/// The real store is left untouched. Not compiled into release builds.
@MainActor
enum DebugSeed {
    /// An in-memory container with the requested Discs, or nil when the launch argument is absent.
    static func containerIfRequested() throws -> ModelContainer? {
        let count = UserDefaults.standard.integer(forKey: "seedDiscs")
        guard count > 0 else { return nil }
        let container = try DiscStore.inMemoryContainer()
        let store = DiscStore(container: container)
        let covers = makeCovers(24)
        let start = Date.now
        for i in 0..<count {
            var draft = Draft()
            draft.title = "Disc \(i + 1)"
            draft.artist = "Artist \(i % 37 + 1)"
            draft.year = 1960 + i % 60
            draft.format = i % 3 == 0 ? .cd : .vinyl
            if i % 4 == 1 { draft.vinylColor = VinylColor.firstChoices[i % VinylColor.firstChoices.count] } // Color bands
            draft.addedAt = start.addingTimeInterval(-Double(i) * 3_600) // Disc 1 is the newest
            draft.coverURL = i % 7 == 6 ? nil : covers[i % covers.count] // some placeholders too
            _ = store.upsert(draft)
        }
        return container
    }

    /// Writes numbered gradient covers to the caches folder and returns their file URLs.
    private static func makeCovers(_ n: Int) -> [URL] {
        let folder = URL.cachesDirectory.appending(path: "debug-covers", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return (0..<n).map { i in
            let url = folder.appending(path: "cover-\(i).png")
            if !FileManager.default.fileExists(atPath: url.path()) {
                let hue = Double(i) / Double(n)
                let art = ZStack {
                    LinearGradient(
                        colors: [Color(hue: hue, saturation: 0.7, brightness: 0.9), Color(hue: hue, saturation: 0.9, brightness: 0.35)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Text(verbatim: "\(i + 1)").font(.system(size: 120, weight: .black)).foregroundStyle(.white.opacity(0.85))
                }
                .frame(width: 600, height: 600)
                if let png = ImageRenderer(content: art).uiImage?.pngData() { try? png.write(to: url) }
            }
            return url
        }
    }
}
#endif
