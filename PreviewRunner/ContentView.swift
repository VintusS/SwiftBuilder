//
//  ContentView.swift
//  PreviewRunner
//
//  Created by Dragomir Mindrescu on 19.10.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var project: BuilderProject?
    @State private var blocks: [CanvasBlock] = []
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var alertMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading project...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Failed to Load Project")
                        .font(.title2.bold())
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        loadProject()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if blocks.isEmpty {
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
            } else {
                renderProject()
            }
        }
        .onAppear {
            loadProject()
        }
        .alert("Success", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK") {
                alertMessage = nil
            }
        } message: {
            if let message = alertMessage {
                Text(message)
            }
        }
    }
    
    private func renderProject() -> some View {
        let appearance = PreviewAppearance(rawValue: project?.appearance ?? "light") ?? .light
        
        return ZStack {
            appearance.canvasBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(blocks) { block in
                        CanvasBlockView(
                            block: block,
                            appearance: appearance,
                            isSelected: false,
                            onButtonTap: block.kind == .primaryButton ? {
                                alertMessage = "Button tapped successfully! 🎉"
                            } : nil
                        )
                        .padding(.top, CGFloat(block.spacingBefore))
                    }
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, safeAreaTop)
                .padding(.bottom, safeAreaBottom)
            }
        }
        .preferredColorScheme(appearance.colorScheme)
    }
    
    private var safeAreaTop: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top > 0 ? window.safeAreaInsets.top : 20
        }
        return 20
    }
    
    private var safeAreaBottom: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.bottom > 0 ? window.safeAreaInsets.bottom : 16
        }
        return 16
    }
    
    private func loadProject() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let loadedProject = try ProjectLoader.loadLatest()
                
                DispatchQueue.main.async {
                    self.project = loadedProject
                    self.blocks = loadedProject.blocks.map { CanvasBlock(from: $0) }
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct ProjectLoader {
    static func loadLatest() throws -> BuilderProject {
        // Try to load from Documents directory (where macOS builder exports)
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let exportDirectory = documentsURL.appendingPathComponent("SwiftUIBuilderProjects", isDirectory: true)
            
            if FileManager.default.fileExists(atPath: exportDirectory.path) {
                let files = try FileManager.default.contentsOfDirectory(at: exportDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
                
                // Find the most recently modified JSON file
                let jsonFiles = files.filter { $0.pathExtension == "json" }
                if let latestFile = jsonFiles.max(by: { file1, file2 in
                    let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                    let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                    return date1 < date2
                }) {
                    return try loadProject(from: latestFile)
                }
            }
        }
        
        // Fallback: try to load from app bundle (for testing)
        if let bundleURL = Bundle.main.url(forResource: "Prototype", withExtension: "json") {
            return try loadProject(from: bundleURL)
        }
        
        throw ProjectLoadError.noProjectFound
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
        switch self {
        case .noProjectFound:
            return """
No exported project found.

To load a project:
1. Export a project from the macOS builder (it saves to ~/Documents/SwiftUIBuilderProjects/)
2. Copy the JSON file to this app's Documents folder, or
3. Use Xcode's file sharing to add the file to this app

The app will automatically load the latest JSON file from its Documents directory.
"""
        }
    }
}

#Preview {
    ContentView()
}
