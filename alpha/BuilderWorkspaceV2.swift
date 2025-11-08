//
//  BuilderWorkspaceV2.swift
//  alpha
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct BuilderWorkspaceV2: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var blocks: [CanvasBlock]
    @State private var selectedBlockID: CanvasBlock.ID?
    @State private var selectedDevice: DevicePreset = .iphone15Pro
    @State private var appearance: PreviewAppearance = .light
    @State private var zoomLevel: Double = 0.9
    @State private var projectName: String = "Prototype"
    @State private var alertInfo: AlertInfo?
    @State private var isBuilding = false
    
    private let launcher = SimulatorLauncher()
    
    init() {
        let starter = CanvasBlock.starter()
        _blocks = State(initialValue: starter)
        _selectedBlockID = State(initialValue: starter.first?.id)
    }
    
    private var theme: WorkspaceTheme {
        WorkspaceTheme(colorScheme: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            WorkspaceToolbar(
                projectName: $projectName,
                selectedDevice: $selectedDevice,
                appearance: $appearance,
                zoomLevel: $zoomLevel,
                isBuilding: $isBuilding,
                alertInfo: $alertInfo,
                onReset: resetCanvas,
                onSave: saveProject,
                onShowRunGuide: showRunGuide,
                onLaunchSimulator: launchSimulator
            )
            Divider()
            HStack(spacing: 0) {
                ComponentLibraryView(
                    theme: theme,
                    blocks: blocks,
                    selectedBlockID: selectedBlockID,
                    onAddBlock: addBlock,
                    onSelectBlock: { id in
                        selectedBlockID = id
                    }
                )
                .frame(width: 240)
                .background(theme.workspaceBackground)
                Divider()
                CanvasColumnView(
                    theme: theme,
                    selectedDevice: selectedDevice,
                    appearance: appearance,
                    zoomLevel: zoomLevel,
                    blocks: blocks,
                    selectedBlockID: selectedBlockID,
                    onSelectBlock: { id in
                        selectedBlockID = id
                    }
                )
                .background(Color.white.opacity(0.001))
                Divider()
                InspectorView(
                    binding: bindingForSelectedBlock,
                    onDuplicate: duplicateSelectedBlock,
                    onReset: resetSelectedBlock,
                    onDelete: removeSelectedBlock
                )
                .frame(width: 300)
                .background(theme.workspaceBackground)
            }
            .background(theme.workspaceBackground)
        }
        .background(theme.workspaceBackground)
    }
    
    // MARK: - Computed Properties
    
    private var bindingForSelectedBlock: Binding<CanvasBlock>? {
        guard let id = selectedBlockID,
              let index = blocks.firstIndex(where: { $0.id == id })
        else { return nil }
        return $blocks[index]
    }
    
    // MARK: - Block Management
    
    private func addBlock(for kind: CanvasBlock.Kind) {
        let newBlock = CanvasBlock.template(for: kind)
        if let id = selectedBlockID,
           let index = blocks.firstIndex(where: { $0.id == id }) {
            blocks.insert(newBlock, at: index + 1)
        } else {
            blocks.append(newBlock)
        }
        selectedBlockID = newBlock.id
    }
    
    private func duplicateSelectedBlock() {
        guard let id = selectedBlockID,
              let index = blocks.firstIndex(where: { $0.id == id })
        else { return }
        var copy = blocks[index]
        copy.id = UUID()
        blocks.insert(copy, at: index + 1)
        selectedBlockID = copy.id
    }
    
    private func removeSelectedBlock() {
        guard let id = selectedBlockID,
              let index = blocks.firstIndex(where: { $0.id == id })
        else { return }
        blocks.remove(at: index)
        if blocks.indices.contains(index) {
            selectedBlockID = blocks[index].id
        } else {
            selectedBlockID = blocks.last?.id
        }
    }
    
    private func resetSelectedBlock() {
        guard let id = selectedBlockID,
              let index = blocks.firstIndex(where: { $0.id == id })
        else { return }
        var reset = CanvasBlock.template(for: blocks[index].kind)
        reset.id = blocks[index].id
        blocks[index] = reset
    }
    
    private func resetCanvas() {
        let starter = CanvasBlock.starter()
        blocks = starter
        selectedBlockID = starter.first?.id
    }
    
    // MARK: - Export & Launch
    
    @MainActor
    private func saveProject() {
        let project = BuilderProject(
            name: projectName.isEmpty ? "Prototype" : projectName,
            device: selectedDevice.rawValue,
            appearance: appearance.rawValue,
            blocks: blocks.map { $0.exportRepresentation() },
            exportedAt: Date()
        )
#if os(macOS)
        do {
            let directory = try ensureExportDirectory()
            let fileURL = directory.appendingPathComponent(sanitizedProjectFileName())
            try ProjectExporter().export(project, to: fileURL)
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
            showAlert(
                title: "Project Saved",
                message: """
Saved to \(fileURL.path).

Finder opened the export location. Load this JSON in the PreviewRunner iOS target to launch on a simulator or device.
"""
            )
        } catch {
            showAlert(title: "Save Failed", message: error.localizedDescription)
        }
#else
        showAlert(
            title: "Unavailable",
            message: "Project export requires the macOS build of SwiftUI Builder."
        )
#endif
    }
    
    private func showRunGuide() {
        let instructions = """
1. Save your project first using "Save Project" button.
2. Use "Run on Simulator" to automatically build and launch, or manually:
   - Open Xcode
   - Select PreviewRunner scheme
   - Choose a simulator destination
   - Press ⌘R to build and run

The PreviewRunner app will automatically load the latest exported project from ~/Documents/SwiftUIBuilderProjects/
"""
        showAlert(title: "Run on Simulator / Device", message: instructions)
    }
    
    @MainActor
    private func launchSimulator() {
        let project = BuilderProject(
            name: projectName.isEmpty ? "Prototype" : projectName,
            device: selectedDevice.rawValue,
            appearance: appearance.rawValue,
            blocks: blocks.map { $0.exportRepresentation() },
            exportedAt: Date()
        )
        
        isBuilding = true
        
        launcher.launch(
            project: project,
            projectName: projectName,
            simulatorName: selectedDevice.displayName,
            onProgress: { message in
                // Could show progress if needed
            },
            onSuccess: { message in
                isBuilding = false
                showAlert(title: "Success", message: message)
            },
            onError: { errorMessage in
                isBuilding = false
                if errorMessage.contains("Build failed") {
                    showAlert(
                        title: "Build Failed",
                        message: """
\(errorMessage)

Would you like to open Xcode to build manually?

Alternatively, you can:
1. Open Xcode
2. Select PreviewRunner scheme
3. Choose your simulator
4. Press ⌘R to build and run
"""
                    )
                } else {
                    showAlert(title: "Launch Failed", message: errorMessage)
                }
            }
        )
    }
    
    // MARK: - Helpers
    
    private func sanitizedProjectFileName() -> String {
        let base = projectName.isEmpty ? "Prototype" : projectName
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = base
            .components(separatedBy: allowed.inverted)
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        return sanitized.isEmpty ? "Prototype.json" : "\(sanitized).json"
    }
    
    private func showAlert(title: String, message: String) {
        alertInfo = AlertInfo(title: title, message: message)
    }
    
#if os(macOS)
    private func ensureExportDirectory() throws -> URL {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ExportError.unableToLocateDocumentsDirectory
        }
        let exportDirectory = documents.appendingPathComponent("SwiftUIBuilderProjects", isDirectory: true)
        if !FileManager.default.fileExists(atPath: exportDirectory.path) {
            try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
        }
        return exportDirectory
    }
#endif
}

