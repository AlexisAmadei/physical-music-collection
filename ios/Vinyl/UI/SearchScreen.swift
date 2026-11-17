import SwiftUI

/// Search (Android `SearchScreen`): "My discs" whose title or artist contains the text, then "Search catalog" and
/// its results. Tapping one of my Discs opens its Draft; tapping a Catalog result opens a prefilled Draft.
/// The words are still English, as on Android.
struct SearchScreen: View {
    @Bindable var app: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let code = app.searchState.notFoundBarcode {
                    Text("Barcode \(code) not found. Search by name.")
                        .textStyle(Typography.body)
                        .foregroundStyle(Palette.error)
                }
                TextField("Looking for something?", text: $app.searchState.text)
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.ink)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.muted))
                Text("My discs")
                    .textStyle(Typography.title)
                    .foregroundStyle(Palette.ink)
                ForEach(app.myDiscs) { disc in
                    Button { app.open(disc) } label: {
                        SearchRow(title: disc.title, artist: disc.artist, year: disc.year, format: disc.format) {
                            Cover(url: disc.coverURL)
                                .colorSticker(disc.shownVinylColor)
                                .accessibilityElement()
                                .accessibilityLabel(disc.coverLabel)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Button { Task { await app.searchCatalog() } } label: {
                    EmptyStateButtonLabel(text: app.searchState.isSearchingCatalog ? "Searching…" : "Search catalog")
                        .opacity(app.searchState.canSearchCatalog ? 1 : 0.4)
                }
                .buttonStyle(.plain)
                .disabled(!app.searchState.canSearchCatalog)
                ForEach(Array(app.searchState.catalogResults.enumerated()), id: \.offset) { _, result in
                    Button { app.pick(result) } label: {
                        SearchRow(title: result.title, artist: result.artist, year: result.year, format: result.format) {
                            Cover(url: result.coverURL)
                        }
                    }
                    .buttonStyle(.plain)
                }
                if app.searchState.notFoundBarcode != nil {
                    Button { app.addManually() } label: { OutlinedButtonLabel(text: "Add manually") }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 44)
            // The floating nav chrome stays visible here: keep the last rows clear of it.
            .padding(.bottom, 124)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.surface)
    }
}

/// A 56 pt cover, the title, then artist, year and Format (Android `DiscRow`).
private struct SearchRow<Thumbnail: View>: View {
    let title: String
    let artist: String
    let year: Int?
    let format: Format
    @ViewBuilder var thumbnail: Thumbnail

    var body: some View {
        HStack(spacing: 16) {
            thumbnail
                .frame(width: 56, height: 56)
                .clipShape(.rect(cornerRadius: 4))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                Text(([artist, year.map(String.init), format.rawValue] as [String?]).compactMap(\.self).joined(separator: " · "))
                    .textStyle(Typography.chip)
                    .foregroundStyle(Palette.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
