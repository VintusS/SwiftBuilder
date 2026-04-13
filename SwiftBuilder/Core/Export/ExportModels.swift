import SwiftUI

struct ExportedScreen: Codable {
    var id: String
    var name: String
    var blocks: [ExportedBlock]
}

struct ExportedBlock: Codable {
    var kind: String
    var content: String
    var symbolName: String
    var alignment: String
    var fontSize: Double
    var fontWeight: String
    var textColor: ColorComponents
    var fillColor: ColorComponents
    var spacingBefore: Double
    var horizontalPadding: Double
    var verticalPadding: Double
    var cornerRadius: Double
    var symbolScale: Double
    var listItems: [String]
    var navigationTarget: String?
    var opacity: Double?
    var borderWidth: Double?
    var lineSpacing: Double?
    var shadowRadius: Double?
    var rowGroupID: String?
}

struct ColorComponents: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
}
