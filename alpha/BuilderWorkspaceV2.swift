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

enum LeftPanelTab: String, CaseIterable {
    case library = "Library"
    case outline = "Outline"
}

struct BuilderWorkspaceV2: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.undoManager) private var undoManager
    @Bindable var store: ProjectStore

    @State private var leftPanelTab: LeftPanelTab = .library

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
                leftPanel
                    .frame(width: 250)
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

    // MARK: - Left Panel

    private var leftPanel: some View {
        VStack(spacing: 0) {
            ScreenListView(store: store, theme: theme)
            Divider()
            leftPanelTabBar
            Divider()
            Group {
                switch leftPanelTab {
                case .library:
                    ComponentLibraryView(
                        theme: theme,
                        onAddBlock: { kind in store.addBlock(for: kind) }
                    )
                case .outline:
                    CanvasOutlineView(
                        theme: theme,
                        blocks: store.currentBlocks,
                        selectedBlockID: store.selectedBlockID,
                        onSelectBlock: { id in store.selectedBlockID = id },
                        onMoveBlock: { source, dest in store.moveBlock(from: source, to: dest) }
                    )
                }
            }
        }
    }

    private var leftPanelTabBar: some View {
        HStack(spacing: 0) {
            ForEach(LeftPanelTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        leftPanelTab = tab
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: tab == .library ? "square.grid.2x2" : "list.bullet.indent")
                            .font(.system(size: 10, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(leftPanelTab == tab ? theme.panelBackground : Color.clear)
                            .shadow(color: leftPanelTab == tab ? theme.cardShadowColor : .clear, radius: 2, y: 1)
                    )
                    .foregroundStyle(leftPanelTab == tab ? .primary : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(theme.workspaceBackground)
    }

    private var bindingForSelectedBlock: Binding<CanvasBlock>? {
        guard let screenIdx = store.currentScreenIndex,
              let blockID = store.selectedBlockID,
              let blockIdx = store.screens[screenIdx].blocks.firstIndex(where: { $0.id == blockID })
        else { return nil }
        return $store.screens[screenIdx].blocks[blockIdx]
    }
}
