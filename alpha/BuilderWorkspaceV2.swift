//
//  BuilderWorkspaceV2.swift
//  alpha
//

import SwiftUI

struct FocusedStoreKey: FocusedValueKey {
    typealias Value = ProjectStore
}

extension FocusedValues {
    var store: ProjectStore? {
        get { self[FocusedStoreKey.self] }
        set { self[FocusedStoreKey.self] = newValue }
    }
}

struct BuilderWorkspaceV2: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.undoManager) private var undoManager
    @Bindable var store: ProjectStore

    private var theme: WorkspaceTheme {
        WorkspaceTheme(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            WorkspaceToolbar(
                projectName: $store.projectName,
                selectedDevice: $store.selectedDevice,
                appearance: $store.appearance,
                zoomLevel: $store.zoomLevel,
                isBuilding: $store.isBuilding,
                alertInfo: $store.alertInfo,
                onReset: { store.resetCanvas() },
                onSave: { store.saveProject() },
                onExportCode: { store.exportCode() },
                onShowRunGuide: { store.showRunGuide() },
                onLaunchSimulator: { store.launchSimulator() }
            )
            Divider()
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    ScreenListView(store: store, theme: theme)
                    Divider()
                    ComponentLibraryView(
                        theme: theme,
                        blocks: store.currentBlocks,
                        selectedBlockID: store.selectedBlockID,
                        onAddBlock: { kind in store.addBlock(for: kind) },
                        onSelectBlock: { id in store.selectedBlockID = id },
                        onMoveBlock: { source, dest in store.moveBlock(from: source, to: dest) }
                    )
                }
                .frame(width: 240)
                .background(theme.workspaceBackground)
                Divider()
                CanvasColumnView(
                    theme: theme,
                    selectedDevice: store.selectedDevice,
                    appearance: store.appearance,
                    zoomLevel: store.zoomLevel,
                    blocks: store.currentBlocks,
                    selectedBlockID: store.selectedBlockID,
                    screenName: store.currentScreen?.name ?? "Screen",
                    onSelectBlock: { id in store.selectedBlockID = id }
                )
                .background(Color.white.opacity(0.001))
                Divider()
                InspectorView(
                    binding: bindingForSelectedBlock,
                    screens: store.screens,
                    onDuplicate: { store.duplicateSelectedBlock() },
                    onReset: { store.resetSelectedBlock() },
                    onDelete: { store.removeSelectedBlock() }
                )
                .frame(width: 300)
                .background(theme.workspaceBackground)
            }
            .background(theme.workspaceBackground)
        }
        .background(theme.workspaceBackground)
        .focusedValue(\.store, store)
        .onAppear { store.undoManager = undoManager }
        .onChange(of: undoManager) { _, newValue in store.undoManager = newValue }
        .sheet(isPresented: $store.showingTemplateGallery) {
            TemplateGallery(
                onSelect: { screen in store.addScreenFromTemplate(screen) },
                onDismiss: { store.showingTemplateGallery = false }
            )
        }
    }

    private var bindingForSelectedBlock: Binding<CanvasBlock>? {
        guard let screenIdx = store.currentScreenIndex,
              let blockID = store.selectedBlockID,
              let blockIdx = store.screens[screenIdx].blocks.firstIndex(where: { $0.id == blockID })
        else { return nil }
        return $store.screens[screenIdx].blocks[blockIdx]
    }
}
