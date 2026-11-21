import SwiftUI

/// "Ma collection": owned Discs as a two-column grid of cover cards. Tapping one opens its Draft.
struct CollectionScreen: View {
    let app: AppModel

    private let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 28) {
                Section {
                    ForEach(app.shownCollection) { disc in
                        Button { app.open(disc) } label: { CoverCard(disc: disc, language: app.language) }
                            .buttonStyle(.plain)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Ma collection")
                            .textCase(.uppercase)
                            .textStyle(Typography.display)
                            .foregroundStyle(Palette.ink)
                        CollectionHeader(filter: Bindable(app).collectionFilter, language: app.language)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 35 - 28)
                } footer: {
                    // A footer spans both columns.
                    if app.shownCollection.isEmpty {
                        EmptyState(app: app)
                            .padding(.top, 120 - 28)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 44)
            .padding(.bottom, 119)
        }
        .background(Palette.surface)
    }
}

/// A cover with its caption under it (`CoverCaption`): title, artist and rating in the Collection,
/// the title only in the Wishlist.
struct CoverCard: View {
    let disc: Disc
    let language: Language

    var body: some View {
        let caption = CoverCaption(disc, language: language)
        VStack(alignment: .leading, spacing: 0) {
            Cover(url: disc.coverURL)
                .aspectRatio(176 / 177, contentMode: .fit)
                .colorBand(disc.shownVinylColor)
                .accessibilityElement()
                .accessibilityLabel(disc.coverLabel(in: language))
            HStack(spacing: 6) {
                Text(caption.title)
                    .textStyle(Typography.title)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
                if caption.showsRating { StarRating(rating: disc.rating) }
            }
            .padding(.top, 8)
            if let artist = caption.artist {
                Text(artist)
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.muted)
                    .lineLimit(1)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Cover art, or a neutral disc placeholder when there is none or it fails to load.
struct Cover: View {
    let url: URL?

    var body: some View {
        Rectangle()
            .fill(Palette.placeholder)
            .overlay {
                Image(systemName: "opticaldisc")
                    .font(.system(size: 24))
                    .foregroundStyle(Palette.line)
            }
            .overlay {
                if let url {
                    AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { Color.clear }
                }
            }
            .clipped()
    }
}
