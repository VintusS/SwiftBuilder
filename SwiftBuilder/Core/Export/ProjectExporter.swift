import Foundation
import SwiftBuilderComponents

struct ProjectExporter {
    func export(_ project: BuilderProject, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(project)
        try data.write(to: url, options: .atomic)
        print("[Exporter] Wrote \(data.count) bytes to \(url.path)")
        let navCount = (project.screens ?? []).flatMap(\.blocks).filter { $0.navigationTarget != nil }.count
        print("[Exporter] Screens: \(project.screens?.count ?? 0), blocks with navTarget: \(navCount)")
    }
}

#if os(macOS)
enum ExportError: LocalizedError {
    case unableToLocateDocumentsDirectory

    var errorDescription: String? {
        switch self {
        case .unableToLocateDocumentsDirectory:
            return "Could not locate the user's Documents directory for export."
        }
    }
}
#endif
