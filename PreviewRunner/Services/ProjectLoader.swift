//
//  ProjectLoader.swift
//  PreviewRunner
//
//  Created by Dragomir Mindrescu on 19.10.2025.
//

import SwiftUI

struct ProjectLoader {
    static func loadLatestWithSource() throws -> (BuilderProject, String) {
        // 1. Direct project path passed via SIMCTL_CHILD env var (highest priority)
        if let projectDir = ProcessInfo.processInfo.environment["ALPHA_PROJECT_DIR"] {
            let dir = URL(fileURLWithPath: projectDir)
            print("[PreviewRunner] Checking ALPHA_PROJECT_DIR: \(dir.path)")
            if let (project, file) = try? loadLatestFromDirectory(dir) {
                return (project, "PROJECT_DIR: \(file)")
            }
        }

        // 2. Host macOS Documents — has the mirrored export from the builder
        if let hostHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] {
            let hostDir = URL(fileURLWithPath: hostHome).appendingPathComponent("Documents/SwiftUIBuilderProjects")
            print("[PreviewRunner] Checking host docs: \(hostDir.path)")
            if let (project, file) = try? loadLatestFromDirectory(hostDir) {
                return (project, "HOST: \(file)")
            }
        } else {
            print("[PreviewRunner] SIMULATOR_HOST_HOME not available")
        }

        // 3. App sandboxed Documents (copied by SimulatorLauncher)
        if let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let appDir = docsURL.appendingPathComponent("SwiftUIBuilderProjects", isDirectory: true)
            print("[PreviewRunner] Checking app docs: \(appDir.path)")
            if let (project, file) = try? loadLatestFromDirectory(appDir) {
                return (project, "APP_DOCS: \(file)")
            }
        }

        // 4. Bundle resource (fallback, may be stale from last build)
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
