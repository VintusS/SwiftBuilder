//
//  ComponentLibraryView.swift
//  alpha
//

import SwiftUI

// MARK: - Component Library (with search)

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

// MARK: - Canvas Outline (separate view)

struct CanvasOutlineView: View {
    let theme: WorkspaceTheme
    let blocks: [CanvasBlock]
    let selectedBlockID: CanvasBlock.ID?
    let onSelectBlock: (CanvasBlock.ID) -> Void
    var onMoveBlock: (IndexSet, Int) -> Void = { _, _ in }

    @State private var draggedBlockID: CanvasBlock.ID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if blocks.isEmpty {
                    emptyOutline
                } else {
                    ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                        outlineRow(block: block, index: index)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
        }
    }

    private func outlineRow(block: CanvasBlock, index: Int) -> some View {
        let isActive = block.id == selectedBlockID
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                onSelectBlock(block.id)
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: block.kind.iconSystemName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isActive ? .accentColor : .secondary)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(block.kind.displayName)
                        .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                    HStack(spacing: Spacing.xs) {
                        Text(block.outlineSummary)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if block.navigationTarget != nil {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isActive ? theme.outlineFill(isActive: true) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isActive ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(draggedBlockID == block.id ? 0.4 : 1)
        .draggable(block.id.uuidString) {
            HStack(spacing: 6) {
                Image(systemName: block.kind.iconSystemName)
                    .font(.system(size: 11))
                Text(block.kind.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.regularMaterial)
            )
            .onAppear { draggedBlockID = block.id }
        }
        .dropDestination(for: String.self) { items, _ in
            guard let droppedString = items.first,
                  let droppedID = UUID(uuidString: droppedString),
                  let fromIndex = blocks.firstIndex(where: { $0.id == droppedID }),
                  fromIndex != index else { return false }
            let destination = fromIndex < index ? index + 1 : index
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                onMoveBlock(IndexSet(integer: fromIndex), destination)
            }
            draggedBlockID = nil
            return true
        } isTargeted: { targeted in
            if !targeted { draggedBlockID = nil }
        }
        .contextMenu {
            Button("Move Up") {
                withAnimation { onMoveBlock(IndexSet(integer: index), index - 1) }
            }
            .disabled(index == 0)
            Button("Move Down") {
                withAnimation { onMoveBlock(IndexSet(integer: index), index + 2) }
            }
            .disabled(index >= blocks.count - 1)
        }
    }

    private var emptyOutline: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "square.stack")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.quaternary)
            Text("No components yet")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text("Add from the Library tab.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
