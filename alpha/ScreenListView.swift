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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Screens")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        store.addScreen()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .help("Add a new screen")
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(store.screens) { screen in
                    screenRow(screen)
                }
            }
        }
        .padding(20)
    }

    @ViewBuilder
    private func screenRow(_ screen: Screen) -> some View {
        let isActive = screen.id == store.selectedScreenID

        if editingScreenID == screen.id {
            TextField("Screen name", text: $editingName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    if !editingName.trimmingCharacters(in: .whitespaces).isEmpty {
                        store.renameScreen(id: screen.id, name: editingName)
                    }
                    editingScreenID = nil
                }
        } else {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    store.selectScreen(id: screen.id)
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isActive ? "rectangle.portrait.fill" : "rectangle.portrait")
                        .foregroundColor(isActive ? .accentColor : .secondary)
                        .frame(width: 18)
                    Text(screen.name)
                        .font(.callout.weight(isActive ? .semibold : .regular))
                        .lineLimit(1)
                    Spacer()
                    Text("\(screen.blocks.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(theme.outlineFill(isActive: isActive))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isActive ? Color.accentColor : theme.outlineStrokeColor,
                                        lineWidth: isActive ? 1.4 : 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Rename") {
                    editingName = screen.name
                    editingScreenID = screen.id
                }
                Button("Duplicate") {
                    duplicateScreen(screen)
                }
                Divider()
                Button("Delete", role: .destructive) {
                    withAnimation { store.deleteScreen(id: screen.id) }
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
