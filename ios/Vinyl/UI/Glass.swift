import SwiftUI

/// 48 pt round glass button with a 44 pt glyph (Android `GlassIconButton`).
struct GlassIconButton: View {
    let glyph: Glyph
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) { GlassIcon(glyph: glyph) }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            .accessibilityLabel(label)
    }
}

/// The glyph inside a round glass button, on its 48 pt hit area.
struct GlassIcon: View {
    let glyph: Glyph

    var body: some View {
        GlyphView(glyph: glyph)
            .frame(width: 48, height: 48)
            .contentShape(.circle)
    }
}

/// Vertical glass navigation pill, anchored right (Android `GlassNavPill`). Active tab: Accent fill + Ink outline.
struct GlassNavPill: View {
    let current: Tab
    let onSelect: (Tab) -> Void

    var body: some View {
        VStack(spacing: 2) {
            ForEach(Tab.allCases, id: \.self) { tab in
                let on = tab == current
                Button { onSelect(tab) } label: {
                    GlyphView(glyph: on ? tab.activeGlyph : tab.glyph)
                        .contentShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .frame(width: 52)
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
        .accessibilityElement(children: .contain)
    }
}

extension Tab {
    /// The VoiceOver label of the tab (Android `pillTabs`).
    var label: LocalizedStringKey {
        switch self {
        case .profile: "Profil"
        case .wishlist: "Wishlist"
        case .collection: "Collection"
        case .search: "Rechercher"
        case .home: "Accueil"
        }
    }

    var glyph: Glyph {
        switch self {
        case .profile: Glyphs.profileOff
        case .wishlist: Glyphs.heart
        case .collection: Glyphs.disc
        case .search: Glyphs.search
        case .home: Glyphs.home
        }
    }

    var activeGlyph: Glyph {
        switch self {
        case .profile: Glyphs.profileOn
        case .wishlist: Glyphs.heartOn
        case .collection: Glyphs.discOn
        case .search: Glyphs.searchOn
        case .home: Glyphs.homeOn
        }
    }
}
