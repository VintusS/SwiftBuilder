import SwiftUI

struct ComponentLibraryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let theme: WorkspaceTheme
    let onAddBlock: (CanvasBlock.Kind) -> Void

    @State private var searchQuery: String = ""

    private var filteredCategories: [CanvasBlock.Kind.Category] {
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return CanvasBlock.Kind.categories
        }
        let query = searchQuery.lowercased()
        return CanvasBlock.Kind.categories.compactMap { category in
            let matchingKinds = category.kinds.filter {
                $0.displayName.lowercased().contains(query) ||
                $0.description.lowercased().contains(query)
            }
            if matchingKinds.isEmpty { return nil }
            return CanvasBlock.Kind.Category(
                id: category.id, name: category.name,
                icon: category.icon, kinds: matchingKinds
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchBar
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.sm)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                    if filteredCategories.isEmpty {
                        noResultsView
                    } else {
                        ForEach(filteredCategories) { category in
                            categorySection(category)
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)
            TextField("Search components...", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(theme.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(theme.outlineStrokeColor, lineWidth: 1)
        )
    }

    private func categorySection(_ category: CanvasBlock.Kind.Category) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text(category.name.uppercased())
                    .font(TypographyPreset.sectionHeader)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, Spacing.xs)

            ForEach(category.kinds) { kind in
                Button { onAddBlock(kind) } label: {
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(kind.paletteColor.opacity(0.14))
                            Image(systemName: kind.iconSystemName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(kind.paletteColor)
                        }
                        .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(kind.displayName)
                                .font(.system(size: 12, weight: .semibold))
                            Text(kind.description)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(kind.paletteColor.opacity(0.5))
                            .font(.system(size: 14))
                    }
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(theme.panelBackground)
                            .shadow(color: theme.cardShadowColor, radius: 3, x: 0, y: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var noResultsView: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(.quaternary)
            Text("No components match \"\(searchQuery)\"")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
