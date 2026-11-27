import Foundation
import SwiftData
import Testing
@testable import Vinyl

/// What the store looked like before Finish existed: the same `Disc`, without the `finish` and `secondColor` fields.
/// SwiftData names the entity after the class, so this opens the very same on-disk table.
private enum BeforeFinish {
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
        var speed: Speed?

        init(title: String, format: Format, vinylColor: VinylColor? = nil) {
            self.title = title
            self.format = format
            self.vinylColor = vinylColor
        }
    }
}

/// Existing Discs open Solid with no Second color after upgrading: the new fields are optional, so SwiftData adds them
/// by lightweight migration.
@MainActor
struct FinishUpgradeTests {
    @Test func discsSavedBeforeFinishOpenSolidAndCanGetOne() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "finish-upgrade-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appending(path: "default.store")

        do {
            let old = try ModelContainer(for: BeforeFinish.Disc.self, configurations: ModelConfiguration(url: storeURL))
            old.mainContext.insert(BeforeFinish.Disc(title: "Kid A", format: .vinyl, vinylColor: .red))
            old.mainContext.insert(BeforeFinish.Disc(title: "OK Computer", format: .cd))
            try old.mainContext.save()
        }

        let upgraded = try ModelContainer(for: Disc.self, configurations: ModelConfiguration(url: storeURL))
        let store = DiscStore(container: upgraded)
        let discs = store.list(wishlist: false).sorted { $0.title < $1.title }

        #expect(discs.map(\.title) == ["Kid A", "OK Computer"])
        #expect(discs.map(\.finish) == [nil, nil])
        #expect(discs.map(\.secondColor) == [nil, nil])
        #expect(discs.map(\.shownFinish) == [nil, nil])
        #expect(discs[0].vinylColor == .red)

        var draft = Draft(discs[0])
        draft.pickFinish(.marble)
        store.upsert(draft)
        let kid = try #require(store.list(wishlist: false).first { $0.title == "Kid A" })
        #expect(kid.shownFinish == .marble)
        #expect(kid.shownSecondColor == .white)
        #expect(kid.vinylColor == .red)
    }
}
