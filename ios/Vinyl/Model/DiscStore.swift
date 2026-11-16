import Foundation
import SwiftData

/// The Discs kept on the phone. Same queries as the Android `DiscDao`.
@MainActor
final class DiscStore {
    private let container: ModelContainer
    private let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        context = container.mainContext
    }

    /// The on-disk store used by the app.
    static func persistentContainer() throws -> ModelContainer {
        try ModelContainer(for: Disc.self)
    }

    /// A throwaway store for tests and previews.
    static func inMemoryContainer() throws -> ModelContainer {
        try ModelContainer(for: Disc.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    /// The Collection (`wishlist: false`) or the Wishlist, by artist (case-insensitive) then year.
    func list(wishlist: Bool) -> [Disc] {
        fetch(#Predicate { $0.wishlist == wishlist }).sorted(by: Self.byArtistThenYear)
    }

    /// Discs whose title or artist contains the text, by artist (case-insensitive).
    func search(_ text: String) -> [Disc] {
        fetch(#Predicate { $0.title.localizedStandardContains(text) || $0.artist.localizedStandardContains(text) })
            .sorted { Self.compareArtist($0, $1) == .orderedAscending }
    }

    func get(_ id: PersistentIdentifier) -> Disc? {
        context.registeredModel(for: id) ?? fetch(#Predicate { $0.persistentModelID == id }).first
    }

    /// Inserts a new Disc, or updates the one the Draft edits.
    @discardableResult
    func upsert(_ draft: Draft) -> Disc {
        let disc: Disc
        if let id = draft.id, let saved = get(id) {
            saved.update(from: draft)
            disc = saved
        } else {
            disc = Disc(draft)
            context.insert(disc)
        }
        save()
        return disc
    }

    func delete(_ disc: Disc) {
        context.delete(disc)
        save()
    }

    private func fetch(_ predicate: Predicate<Disc>) -> [Disc] {
        (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private func save() {
        do { try context.save() } catch { assertionFailure("Disc store save failed: \(error)") }
    }

    // Android sorts in SQLite: `artist COLLATE NOCASE`, then `year` with no year first.
    private static func compareArtist(_ a: Disc, _ b: Disc) -> ComparisonResult {
        a.artist.compare(b.artist, options: .caseInsensitive)
    }

    private static func byArtistThenYear(_ a: Disc, _ b: Disc) -> Bool {
        switch compareArtist(a, b) {
        case .orderedAscending: true
        case .orderedDescending: false
        case .orderedSame: (a.year ?? .min) < (b.year ?? .min)
        }
    }
}
