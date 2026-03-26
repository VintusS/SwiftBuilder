//
//  ContentView.swift
//  PreviewRunner
//
//  Created by Dragomir Mindrescu on 19.10.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var project: BuilderProject?
    @State private var screens: [Screen] = []
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var alertMessage: String?
    @State private var debugLog: String = ""
    @State private var showDebug = false

    private var appearance: PreviewAppearance {
        PreviewAppearance(rawValue: project?.appearance ?? "light") ?? .light
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if isLoading {
                    ProgressView("Loading project...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    errorView(errorMessage)
                } else if screens.isEmpty {
                    emptyView
            } else {
                NavigationStack {
                    ScreenContentView(screen: screens[0], allScreens: screens,
                                      appearance: appearance, alertMessage: $alertMessage)
                    .navigationDestination(for: UUID.self) { screenID in
                        if let target = screens.first(where: { $0.id == screenID }) {
                            ScreenContentView(screen: target, allScreens: screens,
                                              appearance: appearance, alertMessage: $alertMessage)
                        }
                    }
                }
            }
            }

            if showDebug {
                debugOverlay
            }
        }
        .onAppear { loadProject() }
        .alert("Action", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK") { alertMessage = nil }
        } message: {
            if let message = alertMessage { Text(message) }
        }
        .onShakeGesture { showDebug.toggle() }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Failed to Load Project")
                .font(.title2.bold())
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry") { loadProject() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Project Found")
                .font(.title2.bold())
            Text("Export a project from the macOS builder first.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var debugOverlay: some View {
        ScrollView {
            Text(debugLog)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
        }
        .frame(maxHeight: 200)
        .background(.black.opacity(0.85))
        .cornerRadius(12)
        .padding(8)
    }

    private func log(_ msg: String) {
        print("[PreviewRunner] \(msg)")
        debugLog += msg + "\n"
    }

    private func loadProject() {
        isLoading = true
        errorMessage = nil
        debugLog = ""

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let (loadedProject, source) = try ProjectLoader.loadLatestWithSource()
                let loadedScreens: [Screen]

                DispatchQueue.main.async { log("Source: \(source)") }

                if let exportedScreens = loadedProject.screens, !exportedScreens.isEmpty {
                    loadedScreens = exportedScreens.map { Screen(from: $0) }
                    DispatchQueue.main.async {
                        log("\(loadedScreens.count) screens loaded")
                        for (i, scr) in loadedScreens.enumerated() {
                            let navBlocks = scr.blocks.filter { $0.navigationTarget != nil }
                            log("  [\(i)] '\(scr.name)' blocks=\(scr.blocks.count) nav=\(navBlocks.count)")
                            for nb in navBlocks {
                                log("    \(nb.kind.rawValue) -> \(nb.navigationTarget!)")
                            }
                        }
                    }
                } else {
                    loadedScreens = [Screen(name: "Main",
                                            blocks: loadedProject.blocks.map { CanvasBlock(from: $0) })]
                    DispatchQueue.main.async { log("WARN: No screens array, using legacy blocks") }
                }

                DispatchQueue.main.async {
                    self.project = loadedProject
                    self.screens = loadedScreens
                    self.isLoading = false
                    self.showDebug = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.debugLog = "ERROR: \(error.localizedDescription)"
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.showDebug = true
                }
            }
        }
    }
}

// MARK: - Screen Rendering

struct ScreenContentView: View {
    let screen: Screen
    let allScreens: [Screen]
    let appearance: PreviewAppearance
    @Binding var alertMessage: String?

    var body: some View {
        ZStack {
            appearance.canvasBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(screen.blocks) { block in
                        blockRow(block)
                    }
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(appearance.colorScheme)
        .navigationTitle(screen.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func blockRow(_ block: CanvasBlock) -> some View {
        let isButton = [CanvasBlock.Kind.primaryButton, .secondaryButton, .linkButton].contains(block.kind)
        let targetScreen = block.navigationTarget.flatMap { tid in
            allScreens.first(where: { $0.id == tid })
        }

        let view = CanvasBlockView(
            block: block,
            appearance: appearance,
            isSelected: false,
            onButtonTap: isButton && targetScreen == nil
                ? { alertMessage = "\(block.content.isEmpty ? "Button" : block.content) tapped (no nav target set)" }
                : nil
        )
        .padding(.top, CGFloat(block.spacingBefore))

        if let target = targetScreen {
            NavigationLink(value: target.id) {
                view
            }
            .buttonStyle(.plain)
        } else if block.navigationTarget != nil {
            view.overlay(alignment: .topTrailing) {
                Text("nav target not found")
                    .font(.system(size: 8))
                    .foregroundColor(.red)
                    .padding(2)
                    .background(.red.opacity(0.15))
            }
        } else {
            view
        }
    }
}

// MARK: - Project Loader

struct ProjectLoader {
    static func loadLatestWithSource() throws -> (BuilderProject, String) {
        // 1. Host macOS Documents — always has the latest export from the builder
        if let hostHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] {
            let hostDir = URL(fileURLWithPath: hostHome).appendingPathComponent("Documents/SwiftUIBuilderProjects")
            print("[PreviewRunner] Checking host docs: \(hostDir.path)")
            if let (project, file) = try? loadLatestFromDirectory(hostDir) {
                return (project, "HOST: \(file)")
            }
        } else {
            print("[PreviewRunner] SIMULATOR_HOST_HOME not available")
        }

        // 2. App sandboxed Documents (copied by SimulatorLauncher)
        if let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let appDir = docsURL.appendingPathComponent("SwiftUIBuilderProjects", isDirectory: true)
            print("[PreviewRunner] Checking app docs: \(appDir.path)")
            if let (project, file) = try? loadLatestFromDirectory(appDir) {
                return (project, "APP_DOCS: \(file)")
            }
        }

        // 3. Bundle resource (fallback, may be stale from last build)
        if let bundleURL = Bundle.main.url(forResource: "Prototype", withExtension: "json") {
            print("[PreviewRunner] Falling back to bundle: \(bundleURL.path)")
            let project = try loadProject(from: bundleURL)
            return (project, "BUNDLE (fallback)")
        }

        throw ProjectLoadError.noProjectFound
    }

    static func loadLatest() throws -> BuilderProject {
        try loadLatestWithSource().0
    }

    private static func loadLatestFromDirectory(_ dir: URL) throws -> (BuilderProject, String)? {
        guard FileManager.default.fileExists(atPath: dir.path) else { return nil }
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey])
        let jsonFiles = files.filter { $0.pathExtension == "json" }
        guard let latest = jsonFiles.max(by: { f1, f2 in
            let d1 = (try? f1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let d2 = (try? f2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return d1 < d2
        }) else { return nil }
        return (try loadProject(from: latest), latest.lastPathComponent)
    }

    static func loadProject(from url: URL) throws -> BuilderProject {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BuilderProject.self, from: data)
    }
}

enum ProjectLoadError: LocalizedError {
    case noProjectFound
    var errorDescription: String? {
        "No exported project found. Use 'Run on Simulator' from the builder app."
    }
}

// MARK: - Shake Gesture

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}

extension View {
    func onShakeGesture(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in action() }
    }
}

#Preview {
    ContentView()
}
