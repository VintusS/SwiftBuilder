import SwiftUI

struct Screen: Identifiable {
    var id: UUID = UUID()
    var name: String
    var blocks: [CanvasBlock]

    static func starter(name: String = "Screen 1") -> Screen {
        Screen(name: name, blocks: CanvasBlock.starter())
    }
}

struct BuilderProject: Codable {
    var name: String
    var device: String
    var appearance: String
    var blocks: [ExportedBlock]
    var screens: [ExportedScreen]?
    var exportedAt: Date
}
