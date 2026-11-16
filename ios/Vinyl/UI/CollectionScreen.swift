import SwiftUI

/// "Ma collection": owned Discs as a two-column grid of cover cards.
struct CollectionScreen: View {
    let app: AppModel
    var onEdit: (Disc) -> Void = { _ in }

    private let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 28) {
                Section {
                    ForEach(app.shownCollection) { disc in
                        Button { onEdit(disc) } label: { CoverCard(disc: disc) }
                            .buttonStyle(.plain)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Ma collection")
                            .textCase(.uppercase)
                            .textStyle(Typography.display)
                            .foregroundStyle(Palette.ink)
                        CollectionHeader(filter: Bindable(app).collectionFilter)
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

/// A cover with the Disc's title and artist under it.
struct CoverCard: View {
    let disc: Disc

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Cover(url: disc.coverURL)
                .aspectRatio(176 / 177, contentMode: .fit)
            HStack(spacing: 6) {
                Text(disc.title.isEmpty ? "Sans titre" : disc.title)
                    .textStyle(Typography.title)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                StarRating(rating: disc.rating)
            }
            .padding(.top, 8)
            if !disc.artist.isEmpty {
                Text(disc.artist)
                    .textStyle(Typography.body)
                    .foregroundStyle(Palette.muted)
                    .lineLimit(1)
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
