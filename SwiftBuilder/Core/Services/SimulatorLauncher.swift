//
//  SimulatorLauncher.swift
//  SwiftBuilder
//
//  Handles building and launching the PreviewRunner app on iOS Simulator or a connected iPhone
//

import Foundation
import SwiftBuilderComponents
#if os(macOS)
import AppKit
#endif

enum LaunchError: LocalizedError {
    case simulatorBootFailed
    case simulatorNotFound(String)
    case deviceNotFound(String)
    case deviceDiscoveryFailed(String)
    case developerToolsUnavailable(String)
    case buildFailed(String)
    case appNotFound
    case appIconFailed(String)
    case installFailed(String)
    case copyFailed(String)
    case launchFailed(String)
    case projectNotFound
    
    var errorDescription: String? {
        switch self {
        case .simulatorBootFailed:
            return "Could not boot simulator. Please ensure Xcode Command Line Tools are installed."
        case .simulatorNotFound(let message):
            return message
        case .deviceNotFound(let message):
            return message
        case .deviceDiscoveryFailed(let output):
            return """
            Could not discover connected iPhones:
            \(output.prefix(800))

            Check that your iPhone is connected, unlocked, trusted by this Mac, and has Developer Mode enabled.
            """
        case .developerToolsUnavailable(let message):
            return message
        case .buildFailed(let output):
            let truncated = output.count > 1000 ? String(output.prefix(1000)) + "\n\n... (truncated)" : output
            let signingTip = output.localizedCaseInsensitiveContains("sign")
                || output.localizedCaseInsensitiveContains("provision")
                || output.localizedCaseInsensitiveContains("development team")
            let tip = signingTip
                ? "Tip: Open Xcode, select the PreviewRunner target, and check Signing & Capabilities for your Apple team."
                : "Tip: Try building manually in Xcode (⌘R) or check if the PreviewRunner scheme builds successfully."
            return "Build failed:\n\n\(truncated)\n\n\(tip)"
        case .appNotFound:
            return "Could not find the built app. The build may have failed."
        case .appIconFailed(let message):
            return "Could not prepare the app icon:\n\(message)"
        case .installFailed(let output):
            return "Install failed:\n\(output.prefix(500))"
        case .copyFailed(let output):
            return "Project transfer failed:\n\(output.prefix(700))"
        case .launchFailed(let output):
            return "Launch failed:\n\(output.prefix(500))"
        case .projectNotFound:
            return "Could not locate Xcode project."
        }
    }
}

class SimulatorLauncher {
    private let bundleID = "com.vintuss.PreviewRunner"
    
    func launch(
        project: BuilderProject,
        projectName: String,
        target: RunTarget,
        simulatorName: String,
        physicalDeviceID: String?,
        appIconURL: URL?,
        onProgress: @escaping @Sendable (String) -> Void,
        onSuccess: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (String) -> Void
    ) {
        Task.detached { [self] in
            do {
                guard let projectPath = self.getProjectPath() else {
                    await MainActor.run { onError("Could not locate Xcode project.") }
                    return
                }
                
                let projectFileURL = try self.prepareProjectPayload(
                    project: project,
                    projectName: projectName,
                    projectPath: projectPath
                )
                let previewAppIconName = try await MainActor.run {
                    try self.preparePreviewRunnerAppIcon(appIconURL: appIconURL, projectPath: projectPath)
                }

                switch target {
                case .simulator:
                    try await self.launchOnSimulator(
                        projectPath: projectPath,
                        projectName: projectName,
                        projectFileURL: projectFileURL,
                        simulatorName: simulatorName,
                        appIconName: previewAppIconName,
                        onProgress: onProgress,
                        onSuccess: onSuccess,
                        onError: onError
                    )
                case .physicalDevice:
                    try await self.launchOnPhysicalDevice(
                        projectPath: projectPath,
                        projectName: projectName,
                        projectFileURL: projectFileURL,
                        physicalDeviceID: physicalDeviceID,
                        appIconName: previewAppIconName,
                        onProgress: onProgress,
                        onSuccess: onSuccess
                    )
                }
            } catch {
                let msg = error.localizedDescription
                await MainActor.run { onError(msg) }
            }
        }
    }

    func launch(
        project: BuilderProject,
        projectName: String,
        simulatorName: String,
        onProgress: @escaping @Sendable (String) -> Void,
        onSuccess: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (String) -> Void
    ) {
        launch(
            project: project,
            projectName: projectName,
            target: .simulator,
            simulatorName: simulatorName,
            physicalDeviceID: nil,
            appIconURL: nil,
            onProgress: onProgress,
            onSuccess: onSuccess,
            onError: onError
        )
    }

    nonisolated private func prepareProjectPayload(
        project: BuilderProject,
        projectName: String,
        projectPath: String
    ) throws -> URL {
        let savedProjectsDir = URL(fileURLWithPath: (projectPath as NSString).appendingPathComponent("SavedProjects"))
        if !FileManager.default.fileExists(atPath: savedProjectsDir.path) {
            try FileManager.default.createDirectory(at: savedProjectsDir, withIntermediateDirectories: true)
        }

        let fileURL = savedProjectsDir.appendingPathComponent(sanitizedProjectFileName(projectName))
        try ProjectExporter().export(project, to: fileURL)
        print("[Launcher] Saved JSON to \(fileURL.path)")

        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let mirrorDir = documents.appendingPathComponent("SwiftUIBuilderProjects", isDirectory: true)
            if !FileManager.default.fileExists(atPath: mirrorDir.path) {
                try? FileManager.default.createDirectory(at: mirrorDir, withIntermediateDirectories: true)
            }
            let mirrorURL = mirrorDir.appendingPathComponent(fileURL.lastPathComponent)
            try? FileManager.default.removeItem(at: mirrorURL)
            try? FileManager.default.copyItem(at: fileURL, to: mirrorURL)
        }

        let previewRunnerDir = (projectPath as NSString).appendingPathComponent("PreviewRunner")
        let embeddedJSON = (previewRunnerDir as NSString).appendingPathComponent("Prototype.json")
        try FileManager.default.createDirectory(atPath: previewRunnerDir, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: embeddedJSON) {
            try FileManager.default.removeItem(atPath: embeddedJSON)
        }
        try FileManager.default.copyItem(atPath: fileURL.path, toPath: embeddedJSON)
        print("[Launcher] Embedded JSON at \(embeddedJSON)")

        return fileURL
    }

    @MainActor
    private func preparePreviewRunnerAppIcon(appIconURL: URL?, projectPath: String) throws -> String? {
        do {
            if let appIconURL {
                try AppIconGenerator.installPreviewRunnerIcon(from: appIconURL, projectPath: projectPath)
                print("[Launcher] Prepared custom PreviewRunner app icon from \(appIconURL.path)")
                return AppIconGenerator.generatedAppIconName
            } else {
                try AppIconGenerator.resetPreviewRunnerIcon(projectPath: projectPath)
                return nil
            }
        } catch {
            throw LaunchError.appIconFailed(error.localizedDescription)
        }
    }

    private func launchOnSimulator(
        projectPath: String,
        projectName: String,
        projectFileURL: URL,
        simulatorName: String,
        appIconName: String?,
        onProgress: @escaping @Sendable (String) -> Void,
        onSuccess: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (String) -> Void
    ) async throws {
        try await bootSimulator(name: simulatorName)
        let (udid, actualName) = try await findSimulator(preferredName: simulatorName)

        guard let simulatorUDID = udid else {
            let availableSimulators = try await getAllAvailableSimulators()
            let simulatorList = availableSimulators.isEmpty
                ? "No simulators found."
                : "Available simulators:\n" + availableSimulators.joined(separator: "\n")

            await MainActor.run {
                onError("\(simulatorName) not found.\n\n\(simulatorList)\n\nTip: Make sure a simulator is running or available in Xcode.")
            }
            return
        }

        if try await !isSimulatorBooted(udid: simulatorUDID) {
            try await bootSimulatorDevice(simulatorUDID: simulatorUDID)
        }

        await MainActor.run { onProgress("Building PreviewRunner for simulator...") }
        let appPath = try await buildApp(
            projectPath: projectPath,
            sdk: "iphonesimulator",
            destination: nil,
            outputName: "SwiftBuilderPreviewRunnerBuild",
            projectName: projectName,
            appIconName: appIconName
        )

        await MainActor.run { onProgress("Installing app on simulator...") }
        try await installApp(simulatorUDID: simulatorUDID, appPath: appPath)

        await MainActor.run { onProgress("Launching app on simulator...") }
        let savedDir = projectFileURL.deletingLastPathComponent().path
        try await launchApp(simulatorUDID: simulatorUDID, savedProjectsPath: savedDir)

        let displayName = actualName ?? simulatorName
        await MainActor.run { onSuccess("PreviewRunner is launching on \(displayName) simulator!") }
    }

    private func launchOnPhysicalDevice(
        projectPath: String,
        projectName: String,
        projectFileURL: URL,
        physicalDeviceID: String?,
        appIconName: String?,
        onProgress: @escaping @Sendable (String) -> Void,
        onSuccess: @escaping @Sendable (String) -> Void
    ) async throws {
        guard let deviceID = physicalDeviceID, !deviceID.isEmpty else {
            throw LaunchError.deviceNotFound("""
            No iPhone is selected.

            Connect an iPhone, unlock it, trust this Mac, enable Developer Mode, then refresh the device list.
            """)
        }

        await MainActor.run { onProgress("Building PreviewRunner for iPhone...") }
        let appPath = try await buildApp(
            projectPath: projectPath,
            sdk: "iphoneos",
            destination: "id=\(deviceID)",
            outputName: "SwiftBuilderPreviewRunnerDeviceBuild",
            projectName: projectName,
            appIconName: appIconName
        )

        await MainActor.run { onProgress("Installing app on iPhone...") }
        try await installAppOnPhysicalDevice(deviceID: deviceID, appPath: appPath)

        await MainActor.run { onProgress("Copying project to iPhone...") }
        try await copyProjectToPhysicalDevice(deviceID: deviceID, jsonFileURL: projectFileURL)

        await MainActor.run { onProgress("Launching app on iPhone...") }
        try await launchAppOnPhysicalDevice(deviceID: deviceID)

        await MainActor.run { onSuccess("PreviewRunner is launching on your iPhone!") }
    }
    
    // MARK: - Project Path
    
    nonisolated private func getProjectPath() -> String? {
        let fileManager = FileManager.default
        
        // Strategy 0: Use compile-time source file path (most reliable)
        let sourceFile = #file
        let sourceSubdir = (sourceFile as NSString).deletingLastPathComponent
        let candidateRoot = (sourceSubdir as NSString).deletingLastPathComponent
        if fileManager.fileExists(atPath: (candidateRoot as NSString).appendingPathComponent("SwiftBuilder.xcodeproj")) {
            return candidateRoot
        }
        
        // Strategy 1: Check current working directory
        var searchPath = fileManager.currentDirectoryPath
        for _ in 0..<10 {
            let projectPath = (searchPath as NSString).appendingPathComponent("SwiftBuilder.xcodeproj")
            if fileManager.fileExists(atPath: projectPath) {
                return searchPath
            }
            let parent = (searchPath as NSString).deletingLastPathComponent
            if parent == searchPath || parent == "/" { break }
            searchPath = parent
        }
        
        // Strategy 2: Check relative to app bundle
        if let bundlePath = Bundle.main.bundlePath as String? {
            var checkPath = (bundlePath as NSString).deletingLastPathComponent
            for _ in 0..<5 {
                let projectPath = (checkPath as NSString).appendingPathComponent("SwiftBuilder.xcodeproj")
                if fileManager.fileExists(atPath: projectPath) {
                    return checkPath
                }
                let parent = (checkPath as NSString).deletingLastPathComponent
                if parent == checkPath || parent == "/" { break }
                checkPath = parent
            }
        }
        
        // Strategy 3: Check common locations
        let homeDir = NSHomeDirectory()
        let commonPaths = [
            (homeDir as NSString).appendingPathComponent("Desktop/University/Thesis/Old folder Thesis Project/SwiftBuilder"),
            homeDir,
            (homeDir as NSString).appendingPathComponent("Desktop"),
            (homeDir as NSString).appendingPathComponent("Documents")
        ]
        
        for basePath in commonPaths {
            if fileManager.fileExists(atPath: basePath) {
                let projectPath = (basePath as NSString).appendingPathComponent("SwiftBuilder.xcodeproj")
                if fileManager.fileExists(atPath: projectPath) {
                    return basePath
                }
            }
        }
        
        return nil
    }

    // MARK: - Physical Device Discovery

    func discoverPhysicalDevices() async throws -> [PhysicalDevice] {
        try ensureFullXcodeIsAvailable()

        let jsonURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("SwiftBuilderDevices-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: jsonURL) }

        let devicectlPath = findDevicectlPath()
        var env = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            env["DEVELOPER_DIR"] = developerDir
        }

        let result = try runProcess(
            executable: devicectlPath.executable,
            arguments: devicectlPath.arguments + [
                "--quiet",
                "--json-output", jsonURL.path,
                "list", "devices"
            ],
            environment: env
        )

        guard result.status == 0 else {
            throw LaunchError.deviceDiscoveryFailed(result.output + developerDirectoryTip())
        }

        guard FileManager.default.fileExists(atPath: jsonURL.path),
              let data = try? Data(contentsOf: jsonURL),
              let json = try? JSONSerialization.jsonObject(with: data) else {
            throw LaunchError.deviceDiscoveryFailed("devicectl did not produce a readable device list." + developerDirectoryTip())
        }

        return parsePhysicalDevices(from: json)
    }
    
    // MARK: - Simulator Management
    
    private func bootSimulator(name: String) async throws {
        let openProcess = Process()
        openProcess.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        openProcess.arguments = ["-a", "Simulator"]
        try openProcess.run()
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private func isSimulatorBooted(udid: String) async throws -> Bool {
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["list", "devices", "--json"]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else { return false }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]] else {
            return false
        }
        
        for (_, deviceList) in devices {
            for device in deviceList {
                if let deviceUDID = device["udid"] as? String,
                   deviceUDID == udid,
                   let state = device["state"] as? String {
                    return state == "Booted"
                }
            }
        }
        
        return false
    }
    
    private func bootSimulatorDevice(simulatorUDID: String) async throws {
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["boot", simulatorUDID]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 && process.terminationStatus != 23 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            print("Boot warning: \(errorOutput)")
            if try await isSimulatorBooted(udid: simulatorUDID) {
                return
            }
            throw LaunchError.simulatorBootFailed
        }
        
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    private func findSimulator(preferredName: String) async throws -> (udid: String?, actualName: String?) {
        // Strategy 1: Find any booted iPhone simulator
        if let booted = try await getBootedSimulator() {
            return (booted.udid, booted.name)
        }
        
        // Strategy 2: Exact name match
        if let exact = try await getSimulatorUDID(name: preferredName) {
            return (exact, preferredName)
        }
        
        // Strategy 3: Fuzzy matching
        if let fuzzy = try await findSimulatorFuzzy(name: preferredName) {
            return (fuzzy.udid, fuzzy.name)
        }
        
        // Strategy 4: Any iPhone simulator
        if let anyiPhone = try await getAnyiPhoneSimulator() {
            return (anyiPhone.udid, anyiPhone.name)
        }
        
        return (nil, nil)
    }
    
    private func getBootedSimulator() async throws -> (udid: String, name: String)? {
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["list", "devices", "booted", "--json"]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                var devices: [String: [[String: Any]]] = [:]
                
                if let devicesDict = json["devices"] as? [String: [[String: Any]]] {
                    devices = devicesDict
                } else if let devicesArray = json["devices"] as? [[String: Any]] {
                    devices = ["iOS": devicesArray]
                }
                
                for (runtime, deviceList) in devices {
                    if runtime.contains("iOS") || runtime.contains("iphone") || runtime.contains("iPhone") {
                        for device in deviceList {
                            if let deviceName = device["name"] as? String,
                               deviceName.contains("iPhone"),
                               let udid = device["udid"] as? String {
                                return (udid, deviceName)
                            }
                        }
                    }
                }
            }
        }
        
        return try await getBootedSimulatorFromAll()
    }
    
    private func getBootedSimulatorFromAll() async throws -> (udid: String, name: String)? {
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["list", "devices", "--json"]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else { return nil }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]] else {
            return nil
        }
        
        for (runtime, deviceList) in devices {
            if runtime.contains("iOS") {
                for device in deviceList {
                    if let deviceName = device["name"] as? String,
                       deviceName.contains("iPhone"),
                       let udid = device["udid"] as? String,
                       let state = device["state"] as? String,
                       state == "Booted" {
                        return (udid, deviceName)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func findSimulatorFuzzy(name: String) async throws -> (udid: String, name: String)? {
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["list", "devices", "available", "--json"]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else { return nil }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]] else {
            return nil
        }
        
        let preferredParts = name.components(separatedBy: " ").filter { !$0.isEmpty }
        
        for (_, deviceList) in devices {
            for device in deviceList {
                if let deviceName = device["name"] as? String,
                   deviceName.contains("iPhone"),
                   let udid = device["udid"] as? String {
                    let deviceParts = deviceName.components(separatedBy: " ").filter { !$0.isEmpty }
                    let matchingParts = preferredParts.filter { part in
                        deviceParts.contains { $0.localizedCaseInsensitiveContains(part) }
                    }
                    
                    let hasiPhone = matchingParts.contains { $0.localizedCaseInsensitiveContains("iPhone") }
                    if hasiPhone && matchingParts.count >= 1 {
                        return (udid, deviceName)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func getAnyiPhoneSimulator() async throws -> (udid: String, name: String)? {
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["list", "devices", "available", "--json"]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else { return nil }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]] else {
            return nil
        }
        
        for (runtime, deviceList) in devices {
            if runtime.contains("iOS") {
                for device in deviceList {
                    if let deviceName = device["name"] as? String,
                       deviceName.contains("iPhone"),
                       let udid = device["udid"] as? String {
                        return (udid, deviceName)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func getSimulatorUDID(name: String) async throws -> String? {
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["list", "devices", "available", "--json"]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else { return nil }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]] else {
            return nil
        }
        
        for (_, deviceList) in devices {
            for device in deviceList {
                if let deviceName = device["name"] as? String,
                   deviceName == name,
                   let udid = device["udid"] as? String {
                    return udid
                }
            }
        }
        
        return nil
    }
    
    private func getAllAvailableSimulators() async throws -> [String] {
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["list", "devices", "available", "--json"]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            return []
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]] else {
            return []
        }
        
        var simulatorNames: [String] = []
        for (runtime, deviceList) in devices {
            if runtime.contains("iOS") {
                for device in deviceList {
                    if let deviceName = device["name"] as? String,
                       deviceName.contains("iPhone") {
                        simulatorNames.append(deviceName)
                    }
                }
            }
        }
        
        return simulatorNames.sorted()
    }
    
    // MARK: - Build & Install
    
    private func buildApp(
        projectPath: String,
        sdk: String,
        destination: String?,
        outputName: String,
        projectName: String,
        appIconName: String?
    ) async throws -> String {
        try ensureFullXcodeIsAvailable()

        let outputDir = NSTemporaryDirectory() + outputName
        let expectedApp = "\(outputDir)/PreviewRunner.app"
        let logFile = NSTemporaryDirectory() + "\(outputName).log"
        let developerDir = getDeveloperDirectory() ?? "/Applications/Xcode.app/Contents/Developer"
        let xcodebuildPath = findXcodebuildPath()
        let destinationLine = destination.map { "            -destination \"\($0)\" \\\n" } ?? ""
        let appIconLine = appIconName.map {
            "            \"ASSETCATALOG_COMPILER_APPICON_NAME=\($0)\" \\\n"
        } ?? ""
        
        let sanitizedDisplayName = projectName.replacingOccurrences(of: "\"", with: "")
        let scriptPath = (projectPath as NSString).appendingPathComponent("_build_preview.sh")
        let script = """
        #!/bin/bash
        export DEVELOPER_DIR="\(developerDir)"
        OUTPUT_DIR="\(outputDir)"
        rm -rf "$OUTPUT_DIR"
        mkdir -p "$OUTPUT_DIR"
        "\(xcodebuildPath)" \
            -project "\(projectPath)/SwiftBuilder.xcodeproj" \
            -target PreviewRunner \
            -sdk \(sdk) \
        \(destinationLine)            -configuration Debug \
            "CONFIGURATION_BUILD_DIR=$OUTPUT_DIR" \
            "OBJROOT=$OUTPUT_DIR/Intermediates" \
            "SYMROOT=$OUTPUT_DIR/Products" \
            "INFOPLIST_KEY_CFBundleDisplayName=\(sanitizedDisplayName)" \
        \(appIconLine)            clean build > "\(logFile)" 2>&1
        if [ -d "$OUTPUT_DIR/PreviewRunner.app" ]; then
            exit 0
        else
            exit 1
        fi
        """
        
        try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptPath]
        process.currentDirectoryPath = projectPath
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        
        try process.run()
        process.waitUntilExit()
        
        try? FileManager.default.removeItem(atPath: scriptPath)
        
        if process.terminationStatus != 0 {
            let log = (try? String(contentsOfFile: logFile, encoding: .utf8)) ?? "Build failed (no log)"
            let tail = log.suffix(2000)
            throw LaunchError.buildFailed(String(tail))
        }
        
        guard FileManager.default.fileExists(atPath: expectedApp) else {
            throw LaunchError.appNotFound
        }
        
        print("[Launcher] Built app at: \(expectedApp)")
        return expectedApp
    }
    
    private func runProcess(executable: String, arguments: [String], environment: [String: String]? = nil) throws -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        if let env = environment { process.environment = env }
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        var outputData = Data()
        pipe.fileHandleForReading.readabilityHandler = { handle in
            outputData.append(handle.availableData)
        }
        
        try process.run()
        process.waitUntilExit()
        pipe.fileHandleForReading.readabilityHandler = nil
        outputData.append(pipe.fileHandleForReading.readDataToEndOfFile())
        
        let output = String(data: outputData, encoding: .utf8) ?? ""
        return (process.terminationStatus, output)
    }
    
    private func installApp(simulatorUDID: String, appPath: String) async throws {
        let simctlPath = findSimctlPath()
        var env = ProcessInfo.processInfo.environment
        if let dev = getDeveloperDirectory() { env["DEVELOPER_DIR"] = dev }
        
        let result = try runProcess(
            executable: simctlPath.executable,
            arguments: simctlPath.arguments + ["install", simulatorUDID, appPath],
            environment: env
        )
        if result.status != 0 {
            throw LaunchError.installFailed(result.output)
        }
    }
    
    private func launchApp(simulatorUDID: String, savedProjectsPath: String? = nil) async throws {
        let simctlPath = findSimctlPath()
        var env = ProcessInfo.processInfo.environment
        if let dev = getDeveloperDirectory() { env["DEVELOPER_DIR"] = dev }
        if let savedPath = savedProjectsPath {
            env["SIMCTL_CHILD_SWIFTBUILDER_PROJECT_DIR"] = savedPath
            env["SIMCTL_CHILD_ALPHA_PROJECT_DIR"] = savedPath
        }
        
        let result = try runProcess(
            executable: simctlPath.executable,
            arguments: simctlPath.arguments + ["launch", simulatorUDID, bundleID],
            environment: env
        )
        if result.status != 0 {
            throw LaunchError.launchFailed(result.output)
        }
    }

    private func installAppOnPhysicalDevice(deviceID: String, appPath: String) async throws {
        let devicectlPath = findDevicectlPath()
        var env = ProcessInfo.processInfo.environment
        if let dev = getDeveloperDirectory() { env["DEVELOPER_DIR"] = dev }

        let result = try runProcess(
            executable: devicectlPath.executable,
            arguments: devicectlPath.arguments + [
                "--quiet",
                "device", "install", "app",
                "--device", deviceID,
                appPath
            ],
            environment: env
        )

        if result.status != 0 {
            throw LaunchError.installFailed(result.output + physicalDeviceReadinessTip())
        }
    }

    private func copyProjectToPhysicalDevice(deviceID: String, jsonFileURL: URL) async throws {
        let payloadRoot = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("SwiftBuilderDevicePayload-\(UUID().uuidString)", isDirectory: true)
        let payloadProjectDir = payloadRoot.appendingPathComponent("SwiftUIBuilderProjects", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: payloadRoot) }

        try FileManager.default.createDirectory(at: payloadProjectDir, withIntermediateDirectories: true)
        let payloadJSON = payloadProjectDir.appendingPathComponent(jsonFileURL.lastPathComponent)
        try FileManager.default.copyItem(at: jsonFileURL, to: payloadJSON)

        let devicectlPath = findDevicectlPath()
        var env = ProcessInfo.processInfo.environment
        if let dev = getDeveloperDirectory() { env["DEVELOPER_DIR"] = dev }

        let result = try runProcess(
            executable: devicectlPath.executable,
            arguments: devicectlPath.arguments + [
                "--quiet",
                "device", "copy", "to",
                "--device", deviceID,
                "--source", payloadProjectDir.path,
                "--destination", "Documents",
                "--domain-type", "appDataContainer",
                "--domain-identifier", bundleID
            ],
            environment: env
        )

        if result.status != 0 {
            throw LaunchError.copyFailed(result.output + physicalDeviceReadinessTip())
        }
    }

    private func launchAppOnPhysicalDevice(deviceID: String) async throws {
        let devicectlPath = findDevicectlPath()
        var env = ProcessInfo.processInfo.environment
        if let dev = getDeveloperDirectory() { env["DEVELOPER_DIR"] = dev }

        let result = try runProcess(
            executable: devicectlPath.executable,
            arguments: devicectlPath.arguments + [
                "--quiet",
                "device", "process", "launch",
                "--device", deviceID,
                "--terminate-existing",
                bundleID
            ],
            environment: env
        )

        if result.status != 0 {
            throw LaunchError.launchFailed(result.output + physicalDeviceReadinessTip())
        }
    }
    
    private func terminateApp(simulatorUDID: String) async throws {
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["terminate", simulatorUDID, bundleID]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
    }
    
    private func copyProjectToSimulator(simulatorUDID: String, jsonFileURL: URL) async throws {
        let fileManager = FileManager.default
        
        // Primary: use simctl get_app_container with "data" to get the data container path
        var containerPath: String?
        
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["get_app_container", simulatorUDID, bundleID, "data"]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus == 0 {
            let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty, fileManager.fileExists(atPath: path) {
                containerPath = path
            }
        }
        
        // Fallback: scan the simulator device directory for the matching bundle ID
        if containerPath == nil {
            let homeDir = NSHomeDirectory()
            let appsPath = (homeDir as NSString).appendingPathComponent(
                "Library/Developer/CoreSimulator/Devices/\(simulatorUDID)/data/Containers/Data/Application")
            
            if let appDirs = try? fileManager.contentsOfDirectory(atPath: appsPath) {
                for dir in appDirs {
                    let appPath = (appsPath as NSString).appendingPathComponent(dir)
                    let metadataPath = (appPath as NSString).appendingPathComponent(
                        ".com.apple.mobile_container_manager.metadata.plist")
                    
                    if fileManager.fileExists(atPath: metadataPath),
                       let plistData = try? Data(contentsOf: URL(fileURLWithPath: metadataPath)),
                       let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
                       let identifier = plist["MCMMetadataIdentifier"] as? String,
                       identifier == bundleID {
                        containerPath = appPath
                        break
                    }
                }
            }
        }
        
        guard let container = containerPath else {
            throw LaunchError.launchFailed(
                "Could not find PreviewRunner data container on simulator.\n\nTry running PreviewRunner once from Xcode (⌘R with PreviewRunner scheme), then use Run Preview again.")
        }
        
        let exportDir = (container as NSString).appendingPathComponent("Documents/SwiftUIBuilderProjects")
        if !fileManager.fileExists(atPath: exportDir) {
            try fileManager.createDirectory(atPath: exportDir, withIntermediateDirectories: true)
        }
        
        let destURL = URL(fileURLWithPath: (exportDir as NSString).appendingPathComponent(jsonFileURL.lastPathComponent))
        if fileManager.fileExists(atPath: destURL.path) {
            try fileManager.removeItem(at: destURL)
        }
        try fileManager.copyItem(at: jsonFileURL, to: destURL)
    }

    // MARK: - Device JSON Parsing

    private func parsePhysicalDevices(from json: Any) -> [PhysicalDevice] {
        var parsed: [PhysicalDevice] = []
        collectPhysicalDevices(from: json, into: &parsed)

        var unique: [String: PhysicalDevice] = [:]
        for device in parsed {
            unique[device.id] = device
        }

        return unique.values.sorted {
            if $0.isAvailable != $1.isAvailable {
                return $0.isAvailable && !$1.isAvailable
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func collectPhysicalDevices(from value: Any, into devices: inout [PhysicalDevice]) {
        if let dictionary = value as? [String: Any] {
            if let device = physicalDevice(from: dictionary) {
                devices.append(device)
            }
            for nested in dictionary.values {
                collectPhysicalDevices(from: nested, into: &devices)
            }
        } else if let array = value as? [Any] {
            for nested in array {
                collectPhysicalDevices(from: nested, into: &devices)
            }
        }
    }

    private func physicalDevice(from dictionary: [String: Any]) -> PhysicalDevice? {
        guard recursiveStringContains(dictionary, needle: "iphone"),
              let id = firstString(
                in: dictionary,
                keyPaths: [
                    ["hardwareProperties", "udid"],
                    ["udid"],
                    ["UDID"],
                    ["identifier"],
                    ["uuid"],
                    ["deviceIdentifier"],
                    ["deviceProperties", "identifier"],
                    ["connectionProperties", "deviceIdentifier"],
                    ["hardwareProperties", "udid"],
                    ["hardwareProperties", "serialNumber"]
                ]
              ),
              let name = firstString(
                in: dictionary,
                keyPaths: [
                    ["name"],
                    ["deviceName"],
                    ["deviceProperties", "name"],
                    ["properties", "name"],
                    ["hardwareProperties", "name"]
                ]
              )
        else { return nil }

        let tunnelState = firstString(
            in: dictionary,
            keyPaths: [
                ["connectionProperties", "tunnelState"]
            ]
        )
        let hasInstallCapability = recursiveStringContains(dictionary, needle: "com.apple.coredevice.feature.installapp")
        let hasLaunchCapability = recursiveStringContains(dictionary, needle: "com.apple.coredevice.feature.launchapplication")
        let isUnavailable = recursiveStringContains(dictionary, needle: "unavailable")
            || tunnelState?.localizedCaseInsensitiveContains("disconnected") == true

        let isAvailable = firstBool(
            in: dictionary,
            keyPaths: [
                ["isAvailable"],
                ["available"],
                ["availability", "isAvailable"],
                ["connectionProperties", "isAvailable"]
            ]
        ) ?? (hasInstallCapability && hasLaunchCapability && !isUnavailable)

        return PhysicalDevice(id: id, name: name, isAvailable: isAvailable)
    }

    private func firstString(in dictionary: [String: Any], keyPaths: [[String]]) -> String? {
        for keyPath in keyPaths {
            if let value = value(in: dictionary, keyPath: keyPath) as? String,
               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }

    private func firstBool(in dictionary: [String: Any], keyPaths: [[String]]) -> Bool? {
        for keyPath in keyPaths {
            if let value = value(in: dictionary, keyPath: keyPath) as? Bool {
                return value
            }
        }
        return nil
    }

    private func value(in dictionary: [String: Any], keyPath: [String]) -> Any? {
        var current: Any = dictionary
        for key in keyPath {
            guard let dict = current as? [String: Any],
                  let next = dict[key] else {
                return nil
            }
            current = next
        }
        return current
    }

    private func recursiveStringContains(_ value: Any, needle: String) -> Bool {
        if let string = value as? String {
            return string.localizedCaseInsensitiveContains(needle)
        }
        if let dictionary = value as? [String: Any] {
            return dictionary.values.contains { recursiveStringContains($0, needle: needle) }
        }
        if let array = value as? [Any] {
            return array.contains { recursiveStringContains($0, needle: needle) }
        }
        return false
    }
    
    // MARK: - Helper Functions

    private func ensureFullXcodeIsAvailable() throws {
        let xcodeDeveloperDir = "/Applications/Xcode.app/Contents/Developer"
        let betaDeveloperDir = "/Applications/Xcode-beta.app/Contents/Developer"
        if FileManager.default.fileExists(atPath: xcodeDeveloperDir)
            || FileManager.default.fileExists(atPath: betaDeveloperDir) {
            return
        }

        throw LaunchError.developerToolsUnavailable("""
        A full Xcode installation is required to build and run PreviewRunner.

        Install Xcode, then run:
        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
        """)
    }

    private func physicalDeviceReadinessTip() -> String {
        """

        Check that your iPhone is connected, unlocked, trusted by this Mac, and has Developer Mode enabled.
        If this is a signing issue, open Xcode, select the PreviewRunner target, and review Signing & Capabilities.
        """
    }

    private func developerDirectoryTip() -> String {
        let activeDeveloperDir = activeDeveloperDirectory() ?? ""
        guard activeDeveloperDir.contains("CommandLineTools") else { return "" }
        return """

        Active developer directory is Command Line Tools. Use full Xcode:
        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
        """
    }

    private func activeDeveloperDirectory() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
        process.arguments = ["-p"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
    
    private func findSimctlPath() -> (executable: String, arguments: [String]) {
        let possiblePaths = [
            "/Applications/Xcode.app/Contents/Developer/usr/bin/simctl",
            "/Applications/Xcode-beta.app/Contents/Developer/usr/bin/simctl"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return (path, [])
            }
        }
        
        return ("/usr/bin/xcrun", ["simctl"])
    }

    private func findDevicectlPath() -> (executable: String, arguments: [String]) {
        let possiblePaths = [
            "/Applications/Xcode.app/Contents/Developer/usr/bin/devicectl",
            "/Applications/Xcode-beta.app/Contents/Developer/usr/bin/devicectl"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return (path, [])
            }
        }

        return ("/usr/bin/xcrun", ["devicectl"])
    }
    
    private func findXcodebuildPath() -> String {
        let possiblePaths = [
            "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild",
            "/Applications/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return "/usr/bin/xcodebuild"
    }
    
    private func getDeveloperDirectory() -> String? {
        let possibleDirs = [
            "/Applications/Xcode.app/Contents/Developer",
            "/Applications/Xcode-beta.app/Contents/Developer"
        ]
        
        for dir in possibleDirs {
            if FileManager.default.fileExists(atPath: dir) {
                return dir
            }
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
        process.arguments = ["-p"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    nonisolated private func sanitizedProjectFileName(_ projectName: String) -> String {
        let base = projectName.isEmpty ? "Prototype" : projectName
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = base
            .components(separatedBy: allowed.inverted)
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        return sanitized.isEmpty ? "Prototype.json" : "\(sanitized).json"
    }
    
    // ensureExportDirectory removed — launch() now saves directly to <projectPath>/SavedProjects/
}
