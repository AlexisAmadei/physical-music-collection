import Foundation

/// Prices are euro cents (`Int`). Euros only, no conversion. Port of the Android `Price`.
enum Price {
    /// "12,50", "12.50", "25" → cents. Blank or malformed → nil; check `isValid` to tell them apart.
    static func parse(_ text: String) -> Int? {
        // Whitespace includes the no-break spaces (U+00A0, U+202F) that `format` writes.
        let t = text.filter { !$0.isWhitespace }
        let parts = t.split(separator: /[.,]/, omittingEmptySubsequences: false)
        guard parts.count <= 2,
              let euros = parts.first, isDigits(euros),
              let wholeEuros = Int(euros) else { return nil }
        let cents = parts.count == 2 ? parts[1] : ""
        guard parts.count == 1 || (1...2).contains(cents.count) && isDigits(cents) else { return nil }
        let (total, overflow) = wholeEuros.multipliedReportingOverflow(by: 100)
        guard !overflow else { return nil }
        return total + (Int(cents.padding(toLength: 2, withPad: "0", startingAt: 0)) ?? 0)
    }

    /// Blank means "no price", which is allowed.
    static func isValid(_ text: String) -> Bool {
        isBlank(text) || parse(text) != nil
    }

    static func isBlank(_ text: String) -> Bool {
        text.allSatisfy(\.isWhitespace)
    }

    /// French display: "25 €", "12,50 €", "1 240 €" (narrow no-break space between thousands,
    /// no-break space before "€").
    static func format(_ cents: Int) -> String {
        var euros = String(cents / 100)
        var groups: [Substring] = []
        while euros.count > 3 {
            groups.insert(Substring(euros.suffix(3)), at: 0)
            euros.removeLast(3)
        }
        groups.insert(Substring(euros), at: 0)
        let whole = groups.joined(separator: "\u{202F}")
        let rest = cents % 100
        return (rest == 0 ? whole : whole + "," + twoDigits(rest)) + "\u{A0}€"
    }

    /// What the edit field shows for an existing price: "25", "12,50". No price → "".
    static func input(_ cents: Int?) -> String {
        guard let cents else { return "" }
        return cents % 100 == 0 ? "\(cents / 100)" : "\(cents / 100),\(twoDigits(cents % 100))"
    }

    private static func twoDigits(_ n: Int) -> String {
        n < 10 ? "0\(n)" : "\(n)"
    }

    private static func isDigits(_ s: Substring) -> Bool {
        !s.isEmpty && s.allSatisfy { $0.isASCII && $0.isNumber }
    }
}
