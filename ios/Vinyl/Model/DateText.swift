import Foundation

/// How a date reads on screen, in the Language's locale: "3 nov. 2024" in French, "Nov 3, 2024" in English.
enum DateText {
    static func format(_ date: Date, locale: Locale, timeZone: TimeZone) -> String {
        var style = Date.FormatStyle(locale: locale, timeZone: timeZone)
            .day().month(.abbreviated).year()
        style.calendar = locale.calendar
        return date.formatted(style)
    }
}
