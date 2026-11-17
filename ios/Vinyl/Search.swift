import Foundation

/// What the Search screen holds: the typed text, the Catalog results and whether the Catalog is being asked.
struct SearchState: Equatable, Sendable {
    var text = ""
    /// The last "Search catalog" answer: one prefilled Draft per Pressing shown.
    var catalogResults: [Draft] = []
    /// The Catalog is being asked: the button shows "Searching…".
    var isSearchingCatalog = false
    /// The scanned barcode the Catalog did not know: Search says so, and the Disc added from here keeps it.
    var notFound: String?

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

    /// Tapping a Catalog result: opens its prefilled Draft. After a not-found scan it keeps the scanned barcode.
    func pick(_ result: Draft) {
        draft = result
        if let code = searchState.notFound { draft.barcode = code }
        path.append(.draft)
    }

    /// "Add manually", shown after a not-found scan: a new Draft with the scanned barcode and the typed text as title.
    func addManually() {
        draft = Draft(title: searchState.text, barcode: searchState.notFound)
        path.append(.draft)
    }
}
