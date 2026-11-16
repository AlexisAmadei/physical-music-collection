import Foundation

/// Field rules of the Draft form (barcode, year, rating), kept out of the views.
extension Draft {
    /// Tapping star `n` (1 to 5) rates the Draft n; tapping the current star clears the rating.
    mutating func tapStar(_ star: Int) {
        rating = rating == star ? 0 : star
    }

    /// The year as typed: only digits are kept, no digits means no year.
    var yearText: String {
        get { year.map(String.init) ?? "" }
        set { year = Int(newValue.filter { $0.isASCII && $0.isNumber }) }
    }

    /// The barcode as typed: blank means no barcode.
    var barcodeText: String {
        get { barcode ?? "" }
        set { barcode = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newValue }
    }
}
