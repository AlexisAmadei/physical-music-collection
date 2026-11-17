import Foundation

/// What the Scan screen shows: the camera, or "Looking up <code>…" once a barcode is read.
enum ScanState: Equatable, Sendable {
    case scanning
    case lookingUp(String)

    /// The barcode read, if any.
    var barcode: String? {
        if case .lookingUp(let code) = self { code } else { nil }
    }
}

extension AppModel {
    /// The scanner read a barcode. The first one stops scanning and is looked up in the Catalog; later reads are ignored.
    /// Hit: a Draft prefilled from the first result, with the barcode. Miss: Search, saying the barcode was not found.
    func scanned(_ code: String) async {
        guard scanState == .scanning else { return }
        scanState = .lookingUp(code)
        let results = await catalog.lookup(barcode: code)
        // The user left Scan meanwhile ("Enter manually", back): the answer no longer has a screen to replace.
        guard path.last == .scan, scanState == .lookingUp(code) else { return }
        guard var hit = results.first else {
            // Search replaces Scan, as a fresh search for this barcode.
            searchState = SearchState(notFound: code)
            tab = .search
            path = []
            return
        }
        hit.barcode = code
        draft = hit
        replaceScan(with: .draft)
    }

    /// "Enter manually" on the scanner: a new Draft, with the barcode if one was read.
    func enterManually() {
        draft = Draft(barcode: scanState.barcode)
        replaceScan(with: .draft)
    }

    /// Scan leaves the stack for the next screen, so Save or Delete there goes back where the user came from.
    private func replaceScan(with route: Route) {
        if path.last == .scan { path.removeLast() }
        path.append(route)
    }
}
