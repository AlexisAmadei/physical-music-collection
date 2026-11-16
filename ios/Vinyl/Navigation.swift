/// A main screen of the nav pill, in the pill's order from top to bottom (Android `pillTabs`).
enum Tab: CaseIterable, Sendable {
    case profile, wishlist, collection, search, home
}

/// A screen pushed over a main screen.
enum Route: Hashable, Sendable {
    case scan, draft
}

extension AppModel {
    /// The nav pill and the glass buttons show on main screens only, never over a pushed screen.
    var showsChrome: Bool { path.isEmpty }

    /// Nav pill: shows a main screen, always at a single level (no stack).
    func select(_ tab: Tab) {
        self.tab = tab
        path = []
    }

    /// Scan glass button: opens the Scan screen over the current one.
    func scan() {
        path.append(.scan)
    }

    /// Tapping a cover: opens the Draft that edits that Disc.
    func open(_ disc: Disc) {
        edit(disc)
        path.append(.draft)
    }

    /// Leaves the pushed screen (after Save or Delete on a Draft): back where the user came from.
    func back() {
        _ = path.popLast()
    }

    /// "+" offers the add choices everywhere but on the Wishlist, where it opens a Wishlist Draft.
    var plusOffersChoices: Bool { tab != .wishlist }

    /// "+" on the Wishlist (and its empty state): an empty Wishlist Draft.
    func addToWishlist() {
        newDraft(wishlist: true)
        path.append(.draft)
    }

    /// One of the add choices: "Scanner un code-barres", "Rechercher un album", "Saisie manuelle".
    func choose(_ choice: AddChoice) {
        switch choice {
        case .scan: scan()
        case .search: select(.search)
        case .manual:
            newDraft()
            path.append(.draft)
        }
    }
}

/// How the user adds a Disc from "+" or an empty state.
enum AddChoice: CaseIterable, Sendable {
    case scan, search, manual
}
