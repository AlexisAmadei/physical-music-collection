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
    /// The main screen the nav pill shows. Change it with `select(_:)` (see `Navigation.swift`).
    var tab = Tab.home
    /// Screens pushed over the main screen; empty = a single level.
    var path: [Route] = []
    /// The Collection screen's Format filter and sort. Lives here so it survives switching screens.
    var collectionFilter = CollectionFilter()
    /// The Collection as the Collection screen shows it: filtered by Format and sorted.
    var shownCollection: [Disc] { collectionFilter.apply(to: collection) }
    /// The Collection value, by Format; follows every save and delete.
    var collectionValue: CollectionValue { CollectionValue(collection) }
    /// What the Profile card shows; follows every save and delete.
    var collectionStats: CollectionStats { CollectionStats(collection) }
    /// Profile name; "" = unset. Change it with `setProfileName(_:)`.
    private(set) var profileName: String
    @ObservationIgnored private let profilePreferences: any ProfilePreferences
    /// The language the app shows; screens read its locale (see `Language.swift`).
    let language: Language

    @ObservationIgnored private let store: DiscStore
    /// Asked by Search (and Scan) to prefill a Draft.
    @ObservationIgnored let catalog: Catalog
    /// The Search screen's text and Catalog results (see `Search.swift`).
    var searchState = SearchState()
    /// The Scan screen: scanning, or looking up the barcode it read (see `Scan.swift`).
    var scanState = ScanState.scanning

    /// - Parameters:
    ///   - container: `DiscStore.persistentContainer()` in the app, `DiscStore.inMemoryContainer()` in tests.
    ///   - catalogTransport: the real network by default, a fake in tests.
    ///   - profilePreferences: where the Profile name is kept; `UserDefaults` by default, in memory in tests.
    ///   - languagePreferences: where the language pick is kept; `UserDefaults` by default, in memory in tests.
    ///   - deviceLanguages: the device's preferred languages, which decide the language until the user picks one.
    init(
        container: ModelContainer, catalogTransport: any CatalogTransport = URLSessionTransport(),
        profilePreferences: any ProfilePreferences = UserDefaultsProfilePreferences(),
        languagePreferences: any LanguagePreferences = UserDefaultsLanguagePreferences(),
        deviceLanguages: [String] = Locale.preferredLanguages
    ) {
        store = DiscStore(container: container)
        catalog = .standard(transport: catalogTransport)
        self.profilePreferences = profilePreferences
        profileName = profilePreferences.name ?? ""
        language = Language(preferences: languagePreferences, deviceLanguages: deviceLanguages)
        refresh()
    }

    /// Starts an empty Draft, in the Wishlist or the Collection.
    func newDraft(wishlist: Bool = false) {
        draft = Draft(wishlist: wishlist)
    }

    /// Starts a Draft that edits a saved Disc.
    func edit(_ disc: Disc) {
        draft = Draft(disc).showingPrices(in: language.locale)
    }

    /// Whether Save is enabled: the Draft needs a title and a valid shown price.
    var canSaveDraft: Bool {
        !draft.title.isBlank && Price.isValid(draft.priceText)
    }

    /// Saves the current Draft as a new or updated Disc. Refused (does nothing) when `canSaveDraft` is false.
    func saveDraft() {
        guard canSaveDraft else { return }
        store.upsert(draft.withTypedPrices)
        refresh()
    }

    /// Deletes the saved Disc the current Draft edits. Does nothing for a new Draft.
    func deleteDraft() {
        guard let id = draft.id, let disc = store.get(id) else { return }
        store.delete(disc)
        refresh()
    }

    /// Sets the Profile name: trimmed and cut to 24 characters; blank unsets it. Kept in on-device preferences only.
    func setProfileName(_ raw: String) {
        profileName = ProfileName.clean(raw)
        profilePreferences.name = profileName.isEmpty ? nil : profileName
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
