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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Components")
                        .font(.title3.weight(.semibold))
                    Text("Drop-in templates to compose the screen quickly.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(CanvasBlock.Kind.allCases) { kind in
                        Button {
                            onAddBlock(kind)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(kind.paletteColor.opacity(0.16))
                                    Image(systemName: kind.iconSystemName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(kind.paletteColor)
                                }
                                .frame(width: 44, height: 44)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(kind.displayName)
                                        .font(.headline)
                                    Text(kind.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(kind.paletteColor)
                                    .imageScale(.large)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(theme.panelBackground)
                                    .shadow(color: theme.cardShadowColor, radius: 6, x: 0, y: 3)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Canvas Outline")
                        .font(.title3.weight(.semibold))
                    Text("Select an item to adjust it in the inspector.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(blocks) { block in
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
                                    Text(block.outlineSummary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(theme.outlineFill(isActive: isActive))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(isActive ? Color.accentColor : theme.outlineStrokeColor, lineWidth: isActive ? 1.4 : 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if blocks.isEmpty {
                        Text("Add components from the library to begin.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(12)
                    }
                }
            }
            .padding(20)
        }
    }
}

