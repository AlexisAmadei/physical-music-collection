import Foundation
import Testing
@testable import Vinyl

/// Port of the Android `PriceTest`, same cases and expected values (its Collection value case: `CollectionValueTests`).
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

    let french = Locale(identifier: "fr")
    let english = Locale(identifier: "en")

    /// Narrow no-break space (U+202F) between thousands, no-break space (U+00A0) before "€", as on Android.
    @Test func formatsFrench() {
        #expect(Price.format(2500, locale: french) == "25\u{A0}€")
        #expect(Price.format(1250, locale: french) == "12,50\u{A0}€")
        #expect(Price.format(5, locale: french) == "0,05\u{A0}€")
        #expect(Price.format(124000, locale: french) == "1\u{202F}240\u{A0}€")
        #expect(Price.format(124050, locale: french) == "1\u{202F}240,50\u{A0}€")
        #expect(Price.format(0, locale: french) == "0\u{A0}€")
    }

    @Test func formatsEnglish() {
        #expect(Price.format(2500, locale: english) == "€25")
        #expect(Price.format(1250, locale: english) == "€12.50")
        #expect(Price.format(5, locale: english) == "€0.05")
        #expect(Price.format(124000, locale: english) == "€1,240")
        #expect(Price.format(124050, locale: english) == "€1,240.50")
        #expect(Price.format(0, locale: english) == "€0")
    }

    /// The currency is euros whatever the device region says.
    @Test func currencyStaysEuroInAnyRegion() {
        #expect(Price.format(124050, locale: Locale(identifier: "en_US")) == "€1,240.50")
        #expect(Price.format(124050, locale: Locale(identifier: "fr_CA")).hasSuffix("€"))
    }

    @Test func inputRoundTrips() {
        for cents in [2500, 1250, 5, 124000] {
            #expect(Price.parse(Price.input(cents, locale: english)) == cents)
            #expect(Price.parse(Price.input(cents, locale: french)) == cents)
        }
        #expect(Price.input(nil, locale: Locale(identifier: "fr")) == "")
    }
}
