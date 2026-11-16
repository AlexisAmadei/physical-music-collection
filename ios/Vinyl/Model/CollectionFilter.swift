import Foundation

/// How "Ma collection" is ordered: "Date d’ajout" (the default) or "Année".
enum CollectionSort: Sendable {
    case added, year
}

/// The Collection screen's Format filter and sort, as a pure rule over the Collection.
/// Kept in the app model so it survives switching screens.
struct CollectionFilter: Equatable, Sendable {
    /// nil = every Format.
    var format: Format?
    var sort = CollectionSort.added

    /// A Format chip tap: selects that Format, or goes back to every Format if it was already selected.
    mutating func toggle(_ tapped: Format) {
        format = format == tapped ? nil : tapped
    }

    /// The Discs to show.
    func apply(to discs: [Disc]) -> [Disc] {
        discs
            .filter { format == nil || $0.format == format }
            .sorted(by: sort == .year ? Self.byYearThenAdded : Self.byAdded)
    }

    // Android: `compareByDescending { addedAt }`.
    private static func byAdded(_ a: Disc, _ b: Disc) -> Bool {
        a.addedAt > b.addedAt
    }

    // Android: `compareByDescending { year ?: Int.MIN_VALUE }.thenByDescending { addedAt }`.
    private static func byYearThenAdded(_ a: Disc, _ b: Disc) -> Bool {
        let (ya, yb) = (a.year ?? .min, b.year ?? .min)
        return ya != yb ? ya > yb : byAdded(a, b)
    }
}
