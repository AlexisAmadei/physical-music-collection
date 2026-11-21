import SwiftUI

/// The Collection header row: Format chips on the left, the sort toggle on the right.
/// The rules live in `CollectionFilter`; this view only shows them and forwards taps.
struct CollectionHeader: View {
    @Binding var filter: CollectionFilter
    let language: Language

    var body: some View {
        HStack {
            FormatChips(filter: $filter, language: language)
                .padding(.leading, 5)
            Spacer()
            SortToggle(sort: $filter.sort)
        }
        .frame(height: 38)
        .padding(.top, 16)
    }
}

/// CD / Vinyle chips. Tap selects; tapping the active chip goes back to every Format.
private struct FormatChips: View {
    @Binding var filter: CollectionFilter
    let language: Language

    var body: some View {
        HStack(spacing: 4) {
            chip(.cd)
            chip(.vinyl)
        }
    }

    /// The chip reads the Format's own label, like the Profile rows.
    private func chip(_ format: Format) -> some View {
        let on = filter.format == format
        return Button { filter.toggle(format) } label: {
            Text(verbatim: format.label(in: language))
                .textStyle(on ? Typography.chip.weight(.medium) : Typography.chip)
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 12)
                .frame(minWidth: 44, minHeight: 38)
                .background(on ? Palette.ink : .clear, in: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// "Date d’ajout" (default) / "Année". The active label is semibold, underlined 4 pt below the text.
private struct SortToggle: View {
    @Binding var sort: CollectionSort

    var body: some View {
        HStack(spacing: 4) {
            option(.added, "Date d’ajout")
            option(.year, "Année")
        }
    }

    private func option(_ value: CollectionSort, _ label: LocalizedStringKey) -> some View {
        let on = sort == value
        return Button { sort = value } label: {
            Text(label)
                .textStyle(on ? Typography.label.weight(.semibold) : Typography.label)
                .foregroundStyle(Palette.ink)
                .overlay(alignment: .bottom) {
                    if on {
                        Rectangle().fill(Palette.ink).frame(height: 1).offset(y: 4)
                    }
                }
                .padding(.leading, 8)
                .padding(.trailing, value == .year ? 0 : 8)
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

private extension TextStyle {
    func weight(_ weight: Weight) -> TextStyle {
        var style = self
        style.weight = weight
        return style
    }
}

#Preview {
    @Previewable @State var filter = CollectionFilter(format: .vinyl)
    CollectionHeader(filter: $filter, language: Language()).padding(.horizontal, 20)
}
