import Testing
@testable import Vinyl

/// Port of the Android `PriceTest`, same cases and expected values.
/// (Its Collection value case belongs to the Profile ticket.)
struct PriceTests {
    @Test func parsesCommaDotAndWhole() {
        #expect(Price.parse("12,50") == 1250)
        #expect(Price.parse("12.50") == 1250)
        #expect(Price.parse("12,5") == 1250)
        #expect(Price.parse("25") == 2500)
        #expect(Price.parse("1 240") == 124000)
    }

    @Test func blankIsNoPriceAndValid() {
        #expect(Price.parse("  ") == nil)
        #expect(Price.isValid(""))
    }

    @Test(arguments: ["abc", "12,", "12,505", "-3", "1,2,3", "12€"])
    func rejectsMalformed(_ text: String) {
        #expect(Price.parse(text) == nil)
        #expect(!Price.isValid(text))
    }

    /// Narrow no-break space (U+202F) between thousands, no-break space (U+00A0) before "€", as on Android.
    @Test func formatsFrench() {
        #expect(Price.format(2500) == "25\u{A0}€")
        #expect(Price.format(1250) == "12,50\u{A0}€")
        #expect(Price.format(5) == "0,05\u{A0}€")
        #expect(Price.format(124000) == "1\u{202F}240\u{A0}€")
        #expect(Price.format(0) == "0\u{A0}€")
    }

    @Test func inputRoundTrips() {
        for cents in [2500, 1250, 5, 124000] {
            #expect(Price.parse(Price.input(cents)) == cents)
        }
        #expect(Price.input(nil) == "")
    }
}
