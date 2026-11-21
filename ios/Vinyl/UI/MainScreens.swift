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
                CoverWheel(discs: discs) { app.open($0) }
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
                        Button { app.open(disc) } label: { CoverCard(disc: disc) }
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

/// "MON PROFIL": the Profile card, then the Collection value by Format (or the empty state).
struct ProfileScreen: View {
    let app: AppModel
    @State private var editingName = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenTitle(text: "MON PROFIL")
                ProfileCard(
                    name: app.profileName, value: app.collectionValue.total, discs: app.collection.count,
                    onEditName: { editingName = true }
                )
                .padding(.top, 24)
                if app.collection.isEmpty {
                    EmptyState(app: app)
                        .padding(.top, 35)
                } else {
                    ValueByFormat(value: app.collectionValue)
                        .padding(.top, 35)
                }
                LanguagePicker(language: app.language)
                    .padding(.top, 35)
            }
            .sheet(isPresented: $editingName) {
                ProfileNameSheet(current: app.profileName) { name in
                    app.setProfileName(name)
                    editingName = false
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 44)
            .padding(.bottom, 119)
        }
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
