import SwiftUI

/// Home: the cover wheel, or the empty state when the Collection is empty. "Welcome home..." at the bottom.
struct HomeScreen: View {
    let app: AppModel

    var body: some View {
        let discs = app.homeDiscs
        ZStack(alignment: .bottomTrailing) {
            Palette.surface.ignoresSafeArea()
            if discs.isEmpty {
                EmptyState(app: app)
                    .padding(.leading, 20)
                    .padding(.trailing, 72)
                    .frame(maxHeight: .infinity)
            } else {
                CoverWheel(discs: discs)
            }
            ChromeLayout { bottom in
                Text("Welcome home...")
                    .textStyle(Typography.welcome)
                    .foregroundStyle(Palette.ink)
                    .padding(.trailing, 20)
                    .padding(.bottom, bottom + 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .allowsHitTesting(false) // touches go through to the wheel
        }
    }
}

/// "Ma wishlist": wanted Discs as a two-column grid of covers.
struct WishlistScreen: View {
    let app: AppModel

    private let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                Section {
                    ForEach(app.wishlist) { disc in
                        Button { app.open(disc) } label: { CoverCard(disc: disc, showsRating: false) }
                            .buttonStyle(.plain)
                    }
                } header: {
                    ScreenTitle(text: "Ma wishlist")
                        .padding(.bottom, 21 - 12)
                } footer: {
                    // A footer spans both columns.
                    if app.wishlist.isEmpty {
                        EmptyState(hint: "Ajoute les disques que tu cherches.") {
                            Button { app.addToWishlist() } label: {
                                EmptyStateButtonLabel(text: "Ajouter à la wishlist")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 120 - 12)
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

/// "MON PROFIL". The Profile card and the value by Format come with the Profile ticket.
struct ProfileScreen: View {
    let app: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenTitle(text: "MON PROFIL")
                if app.collection.isEmpty {
                    EmptyState(app: app)
                        .padding(.top, 35)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 44)
            .padding(.bottom, 119)
        }
        .background(Palette.surface)
    }
}

/// Placeholder until the Scan ticket.
struct ScanScreen: View {
    var body: some View {
        Text("Scanner un code-barres")
            .textStyle(Typography.title)
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.surface)
    }
}

/// A main screen's uppercase title.
struct ScreenTitle: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .textCase(.uppercase)
            .textStyle(Typography.display)
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
