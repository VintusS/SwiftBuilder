//
//  ComponentLibraryView.swift
//  alpha
//

import SwiftUI

struct ComponentLibraryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let theme: WorkspaceTheme
    let blocks: [CanvasBlock]
    let selectedBlockID: CanvasBlock.ID?
    let onAddBlock: (CanvasBlock.Kind) -> Void
    let onSelectBlock: (CanvasBlock.ID) -> Void
    var onMoveBlock: (IndexSet, Int) -> Void = { _, _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                componentCatalog
                Divider()
                canvasOutline
            }
            .padding(20)
        }
    }

    // MARK: - Component Catalog (Categorized)

    private var componentCatalog: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Components")
                    .font(.title3.weight(.semibold))
                Text("Tap to add to the current screen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(CanvasBlock.Kind.categories) { category in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                        Text(category.name.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 4)

                    ForEach(category.kinds) { kind in
                        Button { onAddBlock(kind) } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(kind.paletteColor.opacity(0.14))
                                    Image(systemName: kind.iconSystemName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(kind.paletteColor)
                                }
                                .frame(width: 36, height: 36)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(kind.displayName)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(kind.description)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(kind.paletteColor.opacity(0.7))
                                    .imageScale(.medium)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(theme.panelBackground)
                                    .shadow(color: theme.cardShadowColor, radius: 4, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Canvas Outline

    private var canvasOutline: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Canvas Outline")
                    .font(.title3.weight(.semibold))
                Text("Select to edit in the inspector.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                    let isActive = block.id == selectedBlockID
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            onSelectBlock(block.id)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: block.kind.iconSystemName)
                                .foregroundColor(isActive ? .accentColor : .secondary)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(block.kind.displayName)
                                    .font(.callout.weight(.semibold))
                                HStack(spacing: 4) {
                                    Text(block.outlineSummary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    if block.navigationTarget != nil {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(theme.outlineFill(isActive: isActive))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isActive ? Color.accentColor : theme.outlineStrokeColor, lineWidth: isActive ? 1.4 : 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
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

                if blocks.isEmpty {
                    Text("Add components from the library above.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(12)
                }
            }
        }
    }
}
