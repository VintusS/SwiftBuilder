import SwiftUI
import SwiftBuilderComponents

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
