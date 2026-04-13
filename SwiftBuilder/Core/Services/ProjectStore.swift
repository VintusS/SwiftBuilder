//
//  ProjectStore.swift
//  SwiftBuilder
//

import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

@Observable
class ProjectStore {

    // MARK: - Project State

    var screens: [Screen]
    var selectedScreenID: UUID?
    var selectedBlockID: CanvasBlock.ID?

    // MARK: - Editor State

    var selectedDevice: DevicePreset = .iphone16Pro
    var appearance: PreviewAppearance = .light
    var zoomLevel: Double = 0.9
    var projectName: String = "Prototype"
    var alertInfo: AlertInfo?
    var isBuilding = false
    var showingTemplateGallery = false

    var undoManager: UndoManager?
    let launcher = SimulatorLauncher()

    // MARK: - Computed Helpers

    var currentScreenIndex: Int? {
        screens.firstIndex(where: { $0.id == selectedScreenID })
    }

    var currentScreen: Screen? {
        guard let idx = currentScreenIndex else { return nil }
        return screens[idx]
    }

    var currentBlocks: [CanvasBlock] {
        currentScreen?.blocks ?? []
    }

    // MARK: - Init

    init() {
        let starterScreen = Screen.starter()
        self.screens = [starterScreen]
        self.selectedScreenID = starterScreen.id
        self.selectedBlockID = starterScreen.blocks.first?.id
    }

    // MARK: - Undo Support

    private struct Snapshot {
        let screens: [Screen]
        let selectedScreenID: UUID?
        let selectedBlockID: UUID?
    }

    private func snapshot() -> Snapshot {
        Snapshot(screens: screens, selectedScreenID: selectedScreenID, selectedBlockID: selectedBlockID)
    }

    private func restore(_ s: Snapshot) {
        screens = s.screens
        selectedScreenID = s.selectedScreenID
        selectedBlockID = s.selectedBlockID
    }

    private func registerUndo(actionName: String, before: Snapshot) {
        guard let um = undoManager else { return }
        let beforeCopy = before
        um.registerUndo(withTarget: self) { store in
            let redo = store.snapshot()
            store.restore(beforeCopy)
            store.registerUndo(actionName: actionName, before: redo)
        }
        um.setActionName(actionName)
    }

    // MARK: - Screen Management

    func addScreen(name: String? = nil) {
        let before = snapshot()
        let screenName = name ?? "Screen \(screens.count + 1)"
        let newScreen = Screen(name: screenName, blocks: [])
        screens.append(newScreen)
        selectedScreenID = newScreen.id
        selectedBlockID = nil
        registerUndo(actionName: "Add Screen", before: before)
    }

    func deleteScreen(id: UUID) {
        guard screens.count > 1 else { return }
        let before = snapshot()
        screens.removeAll(where: { $0.id == id })
        if selectedScreenID == id {
            selectedScreenID = screens.first?.id
            selectedBlockID = screens.first?.blocks.first?.id
        }
        registerUndo(actionName: "Delete Screen", before: before)
    }

    func renameScreen(id: UUID, name: String) {
        guard let idx = screens.firstIndex(where: { $0.id == id }) else { return }
        let before = snapshot()
        screens[idx].name = name
        registerUndo(actionName: "Rename Screen", before: before)
    }

    func selectScreen(id: UUID) {
        selectedScreenID = id
        selectedBlockID = currentScreen?.blocks.first?.id
    }

    func addScreenFromTemplate(_ screen: Screen) {
        let before = snapshot()
        var newScreen = screen
        newScreen.id = UUID()
        for i in newScreen.blocks.indices { newScreen.blocks[i].id = UUID() }
        screens.append(newScreen)
        selectedScreenID = newScreen.id
        selectedBlockID = newScreen.blocks.first?.id
        showingTemplateGallery = false
        registerUndo(actionName: "Add Template", before: before)
    }

    // MARK: - Block Management

    func addBlock(for kind: CanvasBlock.Kind) {
        guard let screenIdx = currentScreenIndex else { return }
        let before = snapshot()
        let newBlock = CanvasBlock.template(for: kind)
        if let blockID = selectedBlockID,
           let blockIdx = screens[screenIdx].blocks.firstIndex(where: { $0.id == blockID }) {
            screens[screenIdx].blocks.insert(newBlock, at: blockIdx + 1)
        } else {
            screens[screenIdx].blocks.append(newBlock)
        }
        selectedBlockID = newBlock.id
        registerUndo(actionName: "Add \(kind.displayName)", before: before)
    }

    func duplicateSelectedBlock() {
        guard let screenIdx = currentScreenIndex,
              let blockID = selectedBlockID,
              let blockIdx = screens[screenIdx].blocks.firstIndex(where: { $0.id == blockID })
        else { return }
        let before = snapshot()
        var copy = screens[screenIdx].blocks[blockIdx]
        copy.id = UUID()
        screens[screenIdx].blocks.insert(copy, at: blockIdx + 1)
        selectedBlockID = copy.id
        registerUndo(actionName: "Duplicate", before: before)
    }

    func removeSelectedBlock() {
        guard let screenIdx = currentScreenIndex,
              let blockID = selectedBlockID,
              let blockIdx = screens[screenIdx].blocks.firstIndex(where: { $0.id == blockID })
        else { return }
        let before = snapshot()
        screens[screenIdx].blocks.remove(at: blockIdx)
        if screens[screenIdx].blocks.indices.contains(blockIdx) {
            selectedBlockID = screens[screenIdx].blocks[blockIdx].id
        } else {
            selectedBlockID = screens[screenIdx].blocks.last?.id
        }
        registerUndo(actionName: "Delete", before: before)
    }

    func resetSelectedBlock() {
        guard let screenIdx = currentScreenIndex,
              let blockID = selectedBlockID,
              let blockIdx = screens[screenIdx].blocks.firstIndex(where: { $0.id == blockID })
        else { return }
        let before = snapshot()
        var reset = CanvasBlock.template(for: screens[screenIdx].blocks[blockIdx].kind)
        reset.id = screens[screenIdx].blocks[blockIdx].id
        screens[screenIdx].blocks[blockIdx] = reset
        registerUndo(actionName: "Reset Component", before: before)
    }

    func resetCanvas() {
        let before = snapshot()
        let starterScreen = Screen.starter()
        screens = [starterScreen]
        selectedScreenID = starterScreen.id
        selectedBlockID = starterScreen.blocks.first?.id
        registerUndo(actionName: "Reset Canvas", before: before)
    }

    func moveBlock(from source: IndexSet, to destination: Int) {
        guard let screenIdx = currentScreenIndex else { return }
        let before = snapshot()
        screens[screenIdx].blocks.move(fromOffsets: source, toOffset: destination)
        registerUndo(actionName: "Move", before: before)
    }

    // MARK: - Row Grouping

    func canMergeIntoRow(blockID: UUID) -> Bool {
        guard let screenIdx = currentScreenIndex,
              let idx = screens[screenIdx].blocks.firstIndex(where: { $0.id == blockID }),
              idx + 1 < screens[screenIdx].blocks.count
        else { return false }

        let block = screens[screenIdx].blocks[idx]
        let next = screens[screenIdx].blocks[idx + 1]

        if let gid = block.rowGroupID {
            let groupCount = screens[screenIdx].blocks.filter { $0.rowGroupID == gid }.count
            if groupCount >= 3 { return false }
            if next.rowGroupID == gid { return false }
        }
        if let gid = next.rowGroupID {
            let groupCount = screens[screenIdx].blocks.filter { $0.rowGroupID == gid }.count
            if groupCount >= 3 { return false }
        }
        return true
    }

    func mergeIntoRow(blockID: UUID) {
        guard let screenIdx = currentScreenIndex,
              let idx = screens[screenIdx].blocks.firstIndex(where: { $0.id == blockID }),
              idx + 1 < screens[screenIdx].blocks.count
        else { return }
        let before = snapshot()

        let existingGroupID = screens[screenIdx].blocks[idx].rowGroupID
            ?? screens[screenIdx].blocks[idx + 1].rowGroupID
        let groupID = existingGroupID ?? UUID()

        screens[screenIdx].blocks[idx].rowGroupID = groupID
        screens[screenIdx].blocks[idx + 1].rowGroupID = groupID

        registerUndo(actionName: "Merge into Row", before: before)
    }

    func removeFromRow(blockID: UUID) {
        guard let screenIdx = currentScreenIndex,
              let idx = screens[screenIdx].blocks.firstIndex(where: { $0.id == blockID }),
              screens[screenIdx].blocks[idx].rowGroupID != nil
        else { return }
        let before = snapshot()

        let gid = screens[screenIdx].blocks[idx].rowGroupID!
        screens[screenIdx].blocks[idx].rowGroupID = nil

        let remaining = screens[screenIdx].blocks.filter { $0.rowGroupID == gid }
        if remaining.count == 1, let lastIdx = screens[screenIdx].blocks.firstIndex(where: { $0.rowGroupID == gid }) {
            screens[screenIdx].blocks[lastIdx].rowGroupID = nil
        }

        registerUndo(actionName: "Remove from Row", before: before)
    }

    // MARK: - Export

    func buildProject() -> BuilderProject {
        let exportedScreens = screens.map { $0.exportRepresentation() }
        let primaryBlocks = screens.first?.blocks.map { $0.exportRepresentation() } ?? []

        for (i, screen) in screens.enumerated() {
            let navBlocks = screen.blocks.filter { $0.navigationTarget != nil }
            print("[Builder] Screen[\(i)] '\(screen.name)' id=\(screen.id) blocks=\(screen.blocks.count) withNav=\(navBlocks.count)")
            for nb in navBlocks {
                print("[Builder]   \(nb.kind.rawValue) '\(nb.content)' navTarget=\(nb.navigationTarget!)")
            }
        }

        return BuilderProject(
            name: projectName.isEmpty ? "Prototype" : projectName,
            device: selectedDevice.rawValue,
            appearance: appearance.rawValue,
            blocks: primaryBlocks,
            screens: exportedScreens,
            exportedAt: Date()
        )
    }

    func saveProject() {
        let project = buildProject()
#if os(macOS)
        do {
            let directory = try ensureExportDirectory()
            let fileURL = directory.appendingPathComponent(sanitizedProjectFileName())
            try ProjectExporter().export(project, to: fileURL)
            mirrorToDocuments(fileURL)
        } catch {
            showAlert(title: "Save Failed", message: error.localizedDescription)
        }
#else
        showAlert(title: "Unavailable", message: "Project export requires the macOS build.")
#endif
    }

    func exportCode() {
        let code = CodeGenerator.generate(screens: screens, projectName: projectName, appearance: appearance)
#if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.swiftSource]
        panel.nameFieldStringValue = "\(projectName.isEmpty ? "Prototype" : projectName).swift"
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try code.write(to: url, atomically: true, encoding: .utf8)
                NSWorkspace.shared.activateFileViewerSelecting([url])
                showAlert(title: "Code Exported", message: "SwiftUI source saved to \(url.lastPathComponent).")
            } catch {
                showAlert(title: "Export Failed", message: error.localizedDescription)
            }
        }
#else
        showAlert(title: "Unavailable", message: "Code export requires the macOS build.")
#endif
    }

    func showRunGuide() {
        let saveDir = (getProjectPath() ?? "~") + "/SavedProjects/"
        showAlert(title: "Run on Simulator / Device", message: """
1. Save your project first using "Save Project" button.
2. Use "Run on Simulator" to automatically build and launch, or manually:
   - Run ./deploy_preview.sh from Terminal in the project folder
   - Or open Xcode, select PreviewRunner scheme, choose a simulator, press \u{2318}R

Projects are saved to: \(saveDir)
""")
    }

    func launchSimulator() {
        let project = buildProject()
        isBuilding = true

        launcher.launch(
            project: project,
            projectName: projectName,
            simulatorName: selectedDevice.displayName,
            onProgress: { _ in },
            onSuccess: { [weak self] _ in
                self?.isBuilding = false
            },
            onError: { [weak self] errorMessage in
                self?.isBuilding = false
                if errorMessage.contains("Build failed") {
                    self?.showAlert(title: "Build Failed", message: """
\(errorMessage)

Try building manually:
1. Open Xcode
2. Select PreviewRunner scheme
3. Choose your simulator
4. Press \u{2318}R to build and run
""")
                } else {
                    self?.showAlert(title: "Launch Failed", message: errorMessage)
                }
            }
        )
    }

    // MARK: - Helpers

    func showAlert(title: String, message: String) {
        alertInfo = AlertInfo(title: title, message: message)
    }

    private func sanitizedProjectFileName() -> String {
        let base = projectName.isEmpty ? "Prototype" : projectName
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = base
            .components(separatedBy: allowed.inverted)
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        return sanitized.isEmpty ? "Prototype.json" : "\(sanitized).json"
    }

    func getProjectPath() -> String? {
        let fileManager = FileManager.default
        let sourceFile = #file
        let sourceSubdir = (sourceFile as NSString).deletingLastPathComponent
        let candidateRoot = (sourceSubdir as NSString).deletingLastPathComponent
        if fileManager.fileExists(atPath: (candidateRoot as NSString).appendingPathComponent("SwiftBuilder.xcodeproj")) {
            return candidateRoot
        }
        var searchPath = fileManager.currentDirectoryPath
        for _ in 0..<10 {
            let projectPath = (searchPath as NSString).appendingPathComponent("SwiftBuilder.xcodeproj")
            if fileManager.fileExists(atPath: projectPath) { return searchPath }
            let parent = (searchPath as NSString).deletingLastPathComponent
            if parent == searchPath || parent == "/" { break }
            searchPath = parent
        }
        if let bundlePath = Bundle.main.bundlePath as String? {
            var checkPath = (bundlePath as NSString).deletingLastPathComponent
            for _ in 0..<5 {
                let projectPath = (checkPath as NSString).appendingPathComponent("SwiftBuilder.xcodeproj")
                if fileManager.fileExists(atPath: projectPath) { return checkPath }
                let parent = (checkPath as NSString).deletingLastPathComponent
                if parent == checkPath || parent == "/" { break }
                checkPath = parent
            }
        }
        let homeDir = NSHomeDirectory()
        let commonPaths = [
            (homeDir as NSString).appendingPathComponent("Desktop/University/Thesis/Old folder Thesis Project/SwiftBuilder"),
            homeDir,
            (homeDir as NSString).appendingPathComponent("Desktop"),
            (homeDir as NSString).appendingPathComponent("Documents")
        ]
        for basePath in commonPaths {
            let projectPath = (basePath as NSString).appendingPathComponent("SwiftBuilder.xcodeproj")
            if fileManager.fileExists(atPath: projectPath) { return basePath }
        }
        return nil
    }

#if os(macOS)
    private func ensureExportDirectory() throws -> URL {
        if let projectPath = getProjectPath() {
            let dir = URL(fileURLWithPath: projectPath).appendingPathComponent("SavedProjects", isDirectory: true)
            if !FileManager.default.fileExists(atPath: dir.path) {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            return dir
        }
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ExportError.unableToLocateDocumentsDirectory
        }
        let exportDirectory = documents.appendingPathComponent("SwiftUIBuilderProjects", isDirectory: true)
        if !FileManager.default.fileExists(atPath: exportDirectory.path) {
            try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
        }
        return exportDirectory
    }

    private func mirrorToDocuments(_ fileURL: URL) {
        do {
            guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let mirrorDir = documents.appendingPathComponent("SwiftUIBuilderProjects", isDirectory: true)
            if !FileManager.default.fileExists(atPath: mirrorDir.path) {
                try FileManager.default.createDirectory(at: mirrorDir, withIntermediateDirectories: true)
            }
            let dest = mirrorDir.appendingPathComponent(fileURL.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.copyItem(at: fileURL, to: dest)
        } catch {
            print("[ProjectStore] Mirror to Documents failed: \(error)")
        }
    }
#endif
}
