import SwiftUI

/// The Draft form's "In wishlist" switch and its one price field: "Prix vu" in the Wishlist,
/// "Prix payé" in the Collection. The rules live in `DraftPrice.swift`.
struct DraftPriceFields: View {
    @Binding var draft: Draft
    let language: Language

    var body: some View {
        Toggle("In wishlist", isOn: $draft.inWishlist)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(draft.priceLabel(in: language))
                TextField(String(), text: $draft.priceText) // no title: the label sits beside it
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("€")
                    .foregroundStyle(Palette.muted)
            }
            if let hint = draft.priceHint(in: language) {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }
}
