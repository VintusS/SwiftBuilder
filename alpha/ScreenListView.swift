//
//  ScreenListView.swift
//  alpha
//

import SwiftUI

struct ScreenListView: View {
    @Bindable var store: ProjectStore
    let theme: WorkspaceTheme

    @State private var editingScreenID: UUID?
    @State private var editingName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                PanelHeader("Screens", icon: "rectangle.stack", theme: theme)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        store.addScreen()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Add a new screen")
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(store.screens) { screen in
                    screenRow(screen)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.screens.map(\.id))
        }
        .padding(Spacing.xl)
    }

    @ViewBuilder
    private func screenRow(_ screen: Screen) -> some View {
        let isActive = screen.id == store.selectedScreenID

        if editingScreenID == screen.id {
            TextField("Screen name", text: $editingName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
                .onSubmit {
                    if !editingName.trimmingCharacters(in: .whitespaces).isEmpty {
                        store.renameScreen(id: screen.id, name: editingName)
                    }
                    editingScreenID = nil
                }
        } else {
            ScreenRow(
                screen: screen,
                isActive: isActive,
                theme: theme,
                onSelect: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        store.selectScreen(id: screen.id)
                    }
                }
            )
            .contextMenu {
                Button {
                    editingName = screen.name
                    editingScreenID = screen.id
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Button {
                    duplicateScreen(screen)
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                Divider()
                Button(role: .destructive) {
                    withAnimation { store.deleteScreen(id: screen.id) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(store.screens.count <= 1)
            }
        }
    }

    private func duplicateScreen(_ screen: Screen) {
        var copy = screen
        copy.id = UUID()
        copy.name = screen.name + " Copy"
        for i in copy.blocks.indices { copy.blocks[i].id = UUID() }
        store.screens.append(copy)
        store.selectScreen(id: copy.id)
    }
}

// MARK: - Screen Row with Hover

private struct ScreenRow: View {
    let screen: Screen
    let isActive: Bool
    let theme: WorkspaceTheme
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isActive ? "rectangle.portrait.fill" : "rectangle.portrait")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isActive ? .accentColor : .secondary)
                    .frame(width: 16)
                Text(screen.name)
                    .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                    .lineLimit(1)
                Spacer()
                Text("\(screen.blocks.count)")
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.secondary.opacity(0.10)))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isActive ? theme.outlineFill(isActive: true)
                          : isHovered ? theme.hoverOverlay : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isActive ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}
