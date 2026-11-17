import SwiftUI

/// The Draft form's "In wishlist" switch and its one price field: "Prix vu" in the Wishlist,
/// "Prix payé" in the Collection. The rules live in `DraftPrice.swift`.
struct DraftPriceFields: View {
    @Binding var draft: Draft

    var body: some View {
        Toggle("In wishlist", isOn: $draft.inWishlist)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(draft.priceLabel)
                TextField("", text: $draft.priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("€")
                    .foregroundStyle(Palette.muted)
            }
            if let hint = draft.priceHint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }
}
