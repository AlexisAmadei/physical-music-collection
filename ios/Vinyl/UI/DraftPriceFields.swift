import SwiftUI

/// The Draft form's "In wishlist" switch and its one price field: "Prix vu" in the Wishlist,
/// "Prix payé" in the Collection. The rules live in `DraftPrice.swift`.
struct DraftPriceFields: View {
    @Binding var draft: Draft

    var body: some View {
        Toggle("In wishlist", isOn: $draft.inWishlist)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(draft.wishlist ? LocalizedStringKey("Prix vu") : LocalizedStringKey("Prix payé"))
                TextField("", text: $draft.priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("€")
                    .foregroundStyle(Palette.muted)
            }
            if !Price.isValid(draft.priceText) {
                Text("Exemple : 12,50")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }
}
