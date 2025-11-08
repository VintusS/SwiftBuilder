//
//  SimulatorLauncher.swift
//  alpha
//
//  Handles building and launching the PreviewRunner app on iOS Simulator
//

import Foundation
#if os(macOS)
import AppKit
#endif

enum LaunchError: LocalizedError {
    case simulatorBootFailed
    case simulatorNotFound(String)
    case buildFailed(String)
    case appNotFound
    case installFailed(String)
    case launchFailed(String)
    case projectNotFound
    
    var errorDescription: String? {
        switch self {
        case .simulatorBootFailed:
            return "Could not boot simulator. Please ensure Xcode Command Line Tools are installed."
        case .simulatorNotFound(let message):
            return message
        case .buildFailed(let output):
            let truncated = output.count > 1000 ? String(output.prefix(1000)) + "\n\n... (truncated)" : output
            return "Build failed:\n\n\(truncated)\n\nTip: Try building manually in Xcode (⌘R) or check if the PreviewRunner scheme builds successfully."
        case .appNotFound:
            return "Could not find the built app. The build may have failed."
        case .installFailed(let output):
            return "Install failed:\n\(output.prefix(500))"
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
        simulatorName: String,
        onProgress: @escaping (String) -> Void,
        onSuccess: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) {
        Task { @MainActor in
            do {
                // Save project first
                let directory = try ensureExportDirectory()
                let fileURL = directory.appendingPathComponent(sanitizedProjectFileName(projectName))
                try ProjectExporter().export(project, to: fileURL)
                
                // Get project path
                guard let projectPath = getProjectPath() else {
                    onError("Could not locate Xcode project. Please ensure you're running from the project directory.")
                    return
                }
                
                // Boot simulator
                try await bootSimulator(name: simulatorName)
                
                // Find simulator
                let (udid, actualName) = try await findSimulator(preferredName: simulatorName)
                
                guard let simulatorUDID = udid else {
                    let availableSimulators = try await getAllAvailableSimulators()
                    let simulatorList = availableSimulators.isEmpty
                        ? "No simulators found."
                        : "Available simulators:\n" + availableSimulators.joined(separator: "\n")
                    
                    throw LaunchError.simulatorNotFound("""
\(simulatorName) not found.

\(simulatorList)

Tip: Make sure a simulator is running or available in Xcode.
""")
                }
                
                // Boot if needed
                let isAlreadyBooted = try await isSimulatorBooted(udid: simulatorUDID)
                if !isAlreadyBooted {
                    try await bootSimulatorDevice(simulatorUDID: simulatorUDID)
                }
                
                // Build
                onProgress("Building PreviewRunner...")
                let appPath = try await buildApp(projectPath: projectPath, simulatorUDID: simulatorUDID, simulatorName: actualName ?? simulatorName)
                
                // Install
                onProgress("Installing app...")
                try await installApp(simulatorUDID: simulatorUDID, appPath: appPath)
                
                // Copy JSON file
                do {
                    let directory = try ensureExportDirectory()
                    let jsonFileURL = directory.appendingPathComponent(sanitizedProjectFileName(projectName))
                    try await copyProjectToSimulator(simulatorUDID: simulatorUDID, jsonFileURL: jsonFileURL)
                } catch {
                    print("Warning: Could not copy project file to simulator: \(error.localizedDescription)")
                }
                
                // Launch
                onProgress("Launching app...")
                try await launchApp(simulatorUDID: simulatorUDID)
                
                let displayName = actualName ?? simulatorName
                onSuccess("PreviewRunner is launching on \(displayName) simulator!")
            } catch {
                onError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Project Path
    
    private func getProjectPath() -> String? {
        let fileManager = FileManager.default
        
        // Strategy 1: Check current working directory
        var searchPath = fileManager.currentDirectoryPath
        for _ in 0..<10 {
            let projectPath = (searchPath as NSString).appendingPathComponent("alpha.xcodeproj")
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
                let projectPath = (checkPath as NSString).appendingPathComponent("alpha.xcodeproj")
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
            homeDir,
            (homeDir as NSString).appendingPathComponent("Desktop"),
            (homeDir as NSString).appendingPathComponent("Documents"),
            "/Users/\(NSUserName())/Desktop/Thesis Project/alpha"
        ]
        
        for basePath in commonPaths {
            if fileManager.fileExists(atPath: basePath) {
                let projectPath = (basePath as NSString).appendingPathComponent("alpha.xcodeproj")
                if fileManager.fileExists(atPath: projectPath) {
                    return basePath
                }
            }
        }
        
        return nil
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
    
    private func buildApp(projectPath: String, simulatorUDID: String, simulatorName: String) async throws -> String {
        let xcodebuildPath = findXcodebuildPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcodebuildPath)
        process.arguments = [
            "-project", "\(projectPath)/alpha.xcodeproj",
            "-target", "PreviewRunner",
            "-sdk", "iphonesimulator",
            "-destination", "platform=iOS Simulator,id=\(simulatorUDID)",
            "-configuration", "Debug",
            "build"
        ]
        process.currentDirectoryPath = projectPath
        
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
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            let standardOutput = String(data: outputData, encoding: .utf8) ?? ""
            
            let hasDVTWarning = errorOutput.contains("DVTDeviceOperation") || standardOutput.contains("DVTDeviceOperation")
            let fullOutput = errorOutput.isEmpty ? standardOutput : errorOutput + "\n\n" + standardOutput
            
            if hasDVTWarning && !fullOutput.contains("error:") && !fullOutput.contains("FAILED") {
                print("DVTDeviceOperation warning detected, but checking if build succeeded...")
            } else {
                throw LaunchError.buildFailed(fullOutput)
            }
        }
        
        let fileManager = FileManager.default
        
        // Check local build directory first
        let localBuildPaths = [
            (projectPath as NSString).appendingPathComponent("build/Debug-iphonesimulator/PreviewRunner.app"),
            (projectPath as NSString).appendingPathComponent("build/Release-iphonesimulator/PreviewRunner.app"),
            (projectPath as NSString).appendingPathComponent("build/PreviewRunner.app")
        ]
        
        for appPath in localBuildPaths {
            if fileManager.fileExists(atPath: appPath) {
                return appPath
            }
        }
        
        // Fallback: DerivedData
        let homeDir = NSHomeDirectory()
        let derivedDataBase = (homeDir as NSString).appendingPathComponent("Library/Developer/Xcode/DerivedData")
        
        if let derivedDataContents = try? fileManager.contentsOfDirectory(atPath: derivedDataBase) {
            for folder in derivedDataContents {
                if folder.contains("PreviewRunner") || folder.contains("alpha") {
                    let possiblePaths = [
                        (derivedDataBase as NSString).appendingPathComponent("\(folder)/Build/Products/Debug-iphonesimulator/PreviewRunner.app"),
                        (derivedDataBase as NSString).appendingPathComponent("\(folder)/Build/Products/Release-iphonesimulator/PreviewRunner.app"),
                        (derivedDataBase as NSString).appendingPathComponent("\(folder)/Build/Products/PreviewRunner.app")
                    ]
                    
                    for appPath in possiblePaths {
                        if fileManager.fileExists(atPath: appPath) {
                            return appPath
                        }
                    }
                    
                    if let appPath = findAppRecursively(in: (derivedDataBase as NSString).appendingPathComponent(folder)) {
                        return appPath
                    }
                }
            }
        }
        
        throw LaunchError.appNotFound
    }
    
    private func findAppRecursively(in directory: String) -> String? {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: directory) else { return nil }
        
        for case let path as String in enumerator {
            if path.hasSuffix("PreviewRunner.app") {
                return (directory as NSString).appendingPathComponent(path)
            }
        }
        
        return nil
    }
    
    private func installApp(simulatorUDID: String, appPath: String) async throws {
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["install", simulatorUDID, appPath]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LaunchError.installFailed(output)
        }
    }
    
    private func launchApp(simulatorUDID: String) async throws {
        let simctlPath = findSimctlPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: simctlPath.executable)
        process.arguments = simctlPath.arguments + ["launch", simulatorUDID, bundleID]
        
        var environment = ProcessInfo.processInfo.environment
        if let developerDir = getDeveloperDirectory() {
            environment["DEVELOPER_DIR"] = developerDir
        }
        process.environment = environment
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LaunchError.launchFailed(output)
        }
    }
    
    private func copyProjectToSimulator(simulatorUDID: String, jsonFileURL: URL) async throws {
        let fileManager = FileManager.default
        let homeDir = NSHomeDirectory()
        let simulatorDevicesPath = (homeDir as NSString).appendingPathComponent("Library/Developer/CoreSimulator/Devices/\(simulatorUDID)/data/Containers/Data/Application")
        
        guard fileManager.fileExists(atPath: simulatorDevicesPath) else {
            throw LaunchError.launchFailed("Could not find simulator data container directory")
        }
        
        guard let appDirs = try? fileManager.contentsOfDirectory(atPath: simulatorDevicesPath) else {
            throw LaunchError.launchFailed("Could not list application containers")
        }
        
        var appDataContainer: String?
        for appDir in appDirs {
            let appPath = (simulatorDevicesPath as NSString).appendingPathComponent(appDir)
            let infoPlistPath = (appPath as NSString).appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
            
            if fileManager.fileExists(atPath: infoPlistPath),
               let plistData = try? Data(contentsOf: URL(fileURLWithPath: infoPlistPath)),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
               let identifier = plist["MCMMetadataIdentifier"] as? String,
               identifier == bundleID {
                appDataContainer = appPath
                break
            }
        }
        
        if appDataContainer == nil {
            let simctlPath = findSimctlPath()
            let process = Process()
            process.executableURL = URL(fileURLWithPath: simctlPath.executable)
            process.arguments = simctlPath.arguments + ["get_app_container", simulatorUDID, bundleID]
            
            var environment = ProcessInfo.processInfo.environment
            if let developerDir = getDeveloperDirectory() {
                environment["DEVELOPER_DIR"] = developerDir
            }
            process.environment = environment
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                if let bundlePath = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !bundlePath.isEmpty {
                    if bundlePath.contains("/Containers/Bundle/Application/") {
                        let dataPath = bundlePath.replacingOccurrences(of: "/Containers/Bundle/Application/", with: "/Containers/Data/Application/")
                        if fileManager.fileExists(atPath: dataPath) {
                            appDataContainer = dataPath
                        }
                    }
                }
            }
        }
        
        guard let containerPath = appDataContainer else {
            throw LaunchError.launchFailed("Could not find app data container. The app may need to be launched first.")
        }
        
        let documentsPath = (containerPath as NSString).appendingPathComponent("Documents")
        if !fileManager.fileExists(atPath: documentsPath) {
            try fileManager.createDirectory(atPath: documentsPath, withIntermediateDirectories: true)
        }
        
        let exportDir = (documentsPath as NSString).appendingPathComponent("SwiftUIBuilderProjects")
        if !fileManager.fileExists(atPath: exportDir) {
            try fileManager.createDirectory(atPath: exportDir, withIntermediateDirectories: true)
        }
        
        let destinationURL = URL(fileURLWithPath: (exportDir as NSString).appendingPathComponent(jsonFileURL.lastPathComponent))
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: jsonFileURL, to: destinationURL)
    }
    
    // MARK: - Helper Functions
    
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
    
    private func sanitizedProjectFileName(_ projectName: String) -> String {
        let base = projectName.isEmpty ? "Prototype" : projectName
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = base
            .components(separatedBy: allowed.inverted)
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        return sanitized.isEmpty ? "Prototype.json" : "\(sanitized).json"
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

