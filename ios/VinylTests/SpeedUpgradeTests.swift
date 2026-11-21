import Foundation
import SwiftData
import Testing
@testable import Vinyl

/// What the store looked like before Speed existed: the same `Disc`, without the `speed` field.
/// SwiftData names the entity after the class, so this opens the very same on-disk table.
private enum BeforeSpeed {
    @Model
    final class Disc {
        var title = ""
        var artist = ""
        var year: Int?
        var format = Format.vinyl
        var barcode: String?
        var rating = 0
        var comment = ""
        var wishlist = false
        var addedAt = Date.now
        var coverURL: URL?
        var seenPrice: Int?
        var paidPrice: Int?
        var vinylColor: VinylColor?

        init(title: String, format: Format) {
            self.title = title
            self.format = format
        }
    }
}

/// Existing Discs open with no Speed after upgrading: the new field is optional, so SwiftData adds it by lightweight migration.
@MainActor
struct SpeedUpgradeTests {
    @Test func discsSavedBeforeSpeedOpenWithNoSpeedAndCanGetOne() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "speed-upgrade-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appending(path: "default.store")

        do {
            let old = try ModelContainer(for: BeforeSpeed.Disc.self, configurations: ModelConfiguration(url: storeURL))
            old.mainContext.insert(BeforeSpeed.Disc(title: "Kid A", format: .vinyl))
            old.mainContext.insert(BeforeSpeed.Disc(title: "OK Computer", format: .cd))
            try old.mainContext.save()
        }

        let upgraded = try ModelContainer(for: Disc.self, configurations: ModelConfiguration(url: storeURL))
        let store = DiscStore(container: upgraded)
        let discs = store.list(wishlist: false).sorted { $0.title < $1.title }

        #expect(discs.map(\.title) == ["Kid A", "OK Computer"])
        #expect(discs.map(\.speed) == [nil, nil])
        #expect(discs.map { $0.speedLabel(in: Language.pinned(.french)) } == [nil, nil])

        var draft = Draft(discs[0])
        draft.speed = .rpm33
        store.upsert(draft)
        #expect(store.list(wishlist: false).first { $0.title == "Kid A" }?.speedLabel(in: Language.pinned(.french)) == "33 tr/min")
    }
}
