import Foundation
import Testing
@testable import Vinyl

/// Dates shown to the user follow the Language's locale.
struct DateTextTests {
    let paris = TimeZone(identifier: "Europe/Paris")!

    /// 2024-11-03 12:00 in Paris.
    let november3 = Date(timeIntervalSince1970: 1_730_631_600)

    @Test func frenchReadsDayMonthYear() {
        #expect(DateText.format(november3, locale: Locale(identifier: "fr"), timeZone: paris) == "3 nov. 2024")
    }

    @Test func englishReadsMonthDayYear() {
        #expect(DateText.format(november3, locale: Locale(identifier: "en"), timeZone: paris) == "Nov 3, 2024")
    }

    @Test func theDayIsTheOneInTheGivenTimeZone() {
        // 2024-11-03 23:30 in Paris is already November 4 in Auckland.
        let lateEvening = Date(timeIntervalSince1970: 1_730_673_000)
        let auckland = TimeZone(identifier: "Pacific/Auckland")!
        #expect(DateText.format(lateEvening, locale: Locale(identifier: "en"), timeZone: paris) == "Nov 3, 2024")
        #expect(DateText.format(lateEvening, locale: Locale(identifier: "en"), timeZone: auckland) == "Nov 4, 2024")
    }
}
