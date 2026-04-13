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
    @State private var showDebug = false // shake device to toggle

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
                                      appearance: appearance, isRoot: true, alertMessage: $alertMessage)
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
                }
            } catch {
                DispatchQueue.main.async {
                    self.debugLog = "ERROR: \(error.localizedDescription)"
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
