import SwiftUI

/// The current main screen with the floating glass chrome, and the screens pushed over it.
/// A custom nav pill, not a TabView: switching screens always lands on a single level.
struct RootView: View {
    @Bindable var app: AppModel

    var body: some View {
        NavigationStack(path: $app.path) {
            main
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .scan: ScanScreen()
                    case .draft: DraftScreen(app: app) { app.back() }
                    }
                }
        }
        .overlay {
            if app.showsChrome { Chrome(app: app) }
        }
    }

    @ViewBuilder private var main: some View {
        switch app.tab {
        case .home: HomeScreen(app: app)
        case .collection: CollectionScreen(app: app)
        case .wishlist: WishlistScreen(app: app)
        case .search: SearchScreen()
        case .profile: ProfileScreen(app: app)
        }
    }
}

/// Glass pill on the right, Scan and "+" bottom-left; positions from the 412 × 917 pt frame (Android `Chrome`).
private struct Chrome: View {
    let app: AppModel

    var body: some View {
        ChromeLayout { bottom in
            ZStack {
                GlassNavPill(current: app.tab) { app.select($0) }
                    .padding(.trailing, 14)
                    .padding(.bottom, bottom + 50)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                GlassEffectContainer(spacing: 11) {
                    HStack(spacing: 11) {
                        GlassIconButton(glyph: Glyphs.scan, label: "Scanner un code-barres") { app.scan() }
                        plus
                    }
                }
                .padding(.leading, 21)
                .padding(.bottom, bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }

    @ViewBuilder private var plus: some View {
        if app.plusOffersChoices {
            AddChoicesMenu(app: app) { GlassIcon(glyph: Glyphs.plus) }
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("Ajouter un disque")
        } else {
            GlassIconButton(glyph: Glyphs.plus, label: "Ajouter à la wishlist") { app.addToWishlist() }
        }
    }
}

/// Full-screen layer that hands its content the chrome's bottom inset:
/// 21 pt from the screen's bottom, but never under the home indicator (Android `chromeBottom`).
struct ChromeLayout<Content: View>: View {
    @ViewBuilder var content: (CGFloat) -> Content

    var body: some View {
        GeometryReader { proxy in
            content(max(21, proxy.safeAreaInsets.bottom))
        }
        .ignoresSafeArea()
    }
}

#Preview {
    RootView(app: AppModel(container: try! DiscStore.inMemoryContainer()))
}
