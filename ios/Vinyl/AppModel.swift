import Foundation
import Observation
import SwiftData

/// The one object screens talk to (the Android `AppVm`). It owns the store, the current Draft and the lists.
@MainActor
@Observable
final class AppModel {
    /// The Disc being added or edited.
    var draft = Draft()
    /// Owned Discs, in store order.
    private(set) var collection: [Disc] = []
    /// Wanted Discs, in store order.
    private(set) var wishlist: [Disc] = []
    /// The Collection screen's Format filter and sort. Lives here so it survives switching screens.
    var collectionFilter = CollectionFilter()
    /// The Collection as the Collection screen shows it: filtered by Format and sorted.
    var shownCollection: [Disc] { collectionFilter.apply(to: collection) }

    @ObservationIgnored private let store: DiscStore
    /// The network the Catalog will use. Unused until the Catalog ticket.
    @ObservationIgnored let catalogTransport: any CatalogTransport

    /// - Parameters:
    ///   - container: `DiscStore.persistentContainer()` in the app, `DiscStore.inMemoryContainer()` in tests.
    ///   - catalogTransport: the real network by default, a fake in tests.
    init(container: ModelContainer, catalogTransport: any CatalogTransport = URLSessionTransport()) {
        store = DiscStore(container: container)
        self.catalogTransport = catalogTransport
        refresh()
    }

    /// Starts an empty Draft, in the Wishlist or the Collection.
    func newDraft(wishlist: Bool = false) {
        draft = Draft(wishlist: wishlist)
    }

    /// Starts a Draft that edits a saved Disc.
    func edit(_ disc: Disc) {
        draft = Draft(disc)
    }

    /// Saves the current Draft as a new or updated Disc.
    func saveDraft() {
        store.upsert(draft)
        refresh()
    }

    /// Deletes the saved Disc the current Draft edits. Does nothing for a new Draft.
    func deleteDraft() {
        guard let id = draft.id, let disc = store.get(id) else { return }
        store.delete(disc)
        refresh()
    }

    /// My Discs (Collection and Wishlist) whose title or artist contains the text, by artist.
    func search(_ text: String) -> [Disc] {
        store.search(text)
    }

    private func refresh() {
        collection = store.list(wishlist: false)
        wishlist = store.list(wishlist: true)
    }
}
