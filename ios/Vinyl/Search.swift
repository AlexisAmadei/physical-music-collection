import Foundation

/// What the Search screen holds: the typed text, the Catalog results and whether the Catalog is being asked.
struct SearchState: Equatable, Sendable {
    var text = ""
    /// The last "Search catalog" answer: one prefilled Draft per Pressing shown.
    var catalogResults: [Draft] = []
    /// The Catalog is being asked: the button shows "Searching…".
    var isSearchingCatalog = false

    /// "Search catalog" is enabled: some text, and no search running.
    var canSearchCatalog: Bool { !isBlank && !isSearchingCatalog }

    var isBlank: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

extension AppModel {
    /// "My discs": my Discs (Collection and Wishlist) whose title or artist contains the text, by artist. None for blank text.
    var myDiscs: [Disc] {
        searchState.isBlank ? [] : search(searchState.text)
    }

    /// "Search catalog": asks the Catalog for the text. Does nothing when `canSearchCatalog` is false.
    func searchCatalog() async {
        guard searchState.canSearchCatalog else { return }
        searchState.isSearchingCatalog = true
        let results = await catalog.search(searchState.text)
        searchState.catalogResults = results
        searchState.isSearchingCatalog = false
    }

    /// Tapping a Catalog result: opens its prefilled Draft.
    func pick(_ result: Draft) {
        draft = result
        path.append(.draft)
    }
}
