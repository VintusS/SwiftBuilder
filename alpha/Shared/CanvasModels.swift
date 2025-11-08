import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct CanvasBlock: Identifiable {
    enum Kind: CaseIterable, Identifiable {
        case symbol
        case heroTitle
        case bodyText
        case primaryButton
        case list

        var id: String { displayName }

        var displayName: String {
            switch self {
            case .symbol: return "Symbol"
            case .heroTitle: return "Headline"
            case .bodyText: return "Body Copy"
            case .primaryButton: return "Primary Button"
            case .list: return "List"
            }
        }

        var description: String {
            switch self {
            case .symbol: return "Large SF Symbol placeholder for thumbnails or art."
            case .heroTitle: return "Bold hero text for onboarding screens."
            case .bodyText: return "Supporting paragraph with comfortable line spacing."
            case .primaryButton: return "Rounded call-to-action button."
            case .list: return "Vertical list of items with icons and text."
            }
        }

        var iconSystemName: String {
            switch self {
            case .symbol: return "sparkles"
            case .heroTitle: return "textformat.size.larger"
            case .bodyText: return "text.alignleft"
            case .primaryButton: return "rectangle.roundedtop"
            case .list: return "list.bullet"
            }
        }

        var paletteColor: Color {
            switch self {
            case .symbol: return Color(red: 0.56, green: 0.41, blue: 0.96)
            case .heroTitle: return Color(red: 0.40, green: 0.48, blue: 0.96)
            case .bodyText: return Color(red: 0.38, green: 0.69, blue: 0.96)
            case .primaryButton: return Color(red: 0.29, green: 0.56, blue: 0.93)
            case .list: return Color(red: 0.96, green: 0.48, blue: 0.40)
            }
        }

        var exportKey: String {
            switch self {
            case .symbol: return "symbol"
            case .heroTitle: return "heroTitle"
            case .bodyText: return "bodyText"
            case .primaryButton: return "primaryButton"
            case .list: return "list"
            }
        }
    }

    var id: UUID = UUID()
    var kind: Kind
    var content: String
    var symbolName: String
    var alignment: BlockAlignment
    var fontSize: Double
    var fontWeight: FontWeightOption
    var textColor: Color
    var fillColor: Color
    var spacingBefore: Double
    var horizontalPadding: Double
    var verticalPadding: Double
    var cornerRadius: Double
    var symbolScale: Double
    var listItems: [String]

    var outlineSummary: String {
        switch kind {
        case .symbol:
            return symbolName.isEmpty ? "sparkles" : symbolName
        case .primaryButton:
            return content
        case .list:
            return "\(listItems.count) items"
        default:
            return content
        }
    }

    var selectionCornerRadius: CGFloat {
        switch kind {
        case .primaryButton:
            return CGFloat(cornerRadius + 6)
        case .symbol:
            return 20
        case .list:
            return 16
        default:
            return 8
        }
    }

    static func starter() -> [CanvasBlock] {
        [
            CanvasBlock.template(for: .symbol),
            CanvasBlock.template(for: .heroTitle),
            CanvasBlock.template(for: .bodyText),
            CanvasBlock.template(for: .primaryButton)
        ]
    }

    static func template(for kind: Kind) -> CanvasBlock {
        switch kind {
        case .symbol:
            return CanvasBlock(
                kind: .symbol,
                content: "",
                symbolName: "iphone",
                alignment: .center,
                fontSize: 0,
                fontWeight: .regular,
                textColor: .primary,
                fillColor: Color(red: 0.45, green: 0.52, blue: 0.96),
                spacingBefore: 0,
                horizontalPadding: 0,
                verticalPadding: 0,
                cornerRadius: 0,
                symbolScale: 1.1,
                listItems: []
            )
        case .heroTitle:
            return CanvasBlock(
                kind: .heroTitle,
                content: "Design onboarding screens in minutes",
                symbolName: "",
                alignment: .leading,
                fontSize: 32,
                fontWeight: .bold,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: .clear,
                spacingBefore: 18,
                horizontalPadding: 0,
                verticalPadding: 0,
                cornerRadius: 0,
                symbolScale: 1,
                listItems: []
            )
        case .bodyText:
            return CanvasBlock(
                kind: .bodyText,
                content: "Compose flows visually, then preview them instantly on real device frames.",
                symbolName: "",
                alignment: .leading,
                fontSize: 18,
                fontWeight: .regular,
                textColor: Color(red: 0.33, green: 0.38, blue: 0.48),
                fillColor: .clear,
                spacingBefore: 12,
                horizontalPadding: 0,
                verticalPadding: 0,
                cornerRadius: 0,
                symbolScale: 1,
                listItems: []
            )
        case .primaryButton:
            return CanvasBlock(
                kind: .primaryButton,
                content: "Preview Prototype",
                symbolName: "",
                alignment: .center,
                fontSize: 18,
                fontWeight: .semibold,
                textColor: .white,
                fillColor: Color(red: 0.29, green: 0.46, blue: 0.96),
                spacingBefore: 18,
                horizontalPadding: 20,
                verticalPadding: 14,
                cornerRadius: 18,
                symbolScale: 1,
                listItems: []
            )
        case .list:
            return CanvasBlock(
                kind: .list,
                content: "",
                symbolName: "",
                alignment: .leading,
                fontSize: 17,
                fontWeight: .regular,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.96, green: 0.97, blue: 0.98),
                spacingBefore: 18,
                horizontalPadding: 16,
                verticalPadding: 12,
                cornerRadius: 12,
                symbolScale: 1,
                listItems: ["First item", "Second item", "Third item"]
            )
        }
    }
}

enum BlockAlignment: String, CaseIterable, Identifiable {
    case leading
    case center
    case trailing

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var textAlignment: TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    var exportKey: String {
        rawValue
    }
}

enum FontWeightOption: String, CaseIterable, Identifiable {
    case regular
    case medium
    case semibold
    case bold

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var weight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }

    var exportKey: String {
        rawValue
    }
}

enum DevicePreset: String, CaseIterable, Identifiable {
    case iphoneSE
    case iphone15Pro
    case ipadMini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iphoneSE: return "iPhone SE"
        case .iphone15Pro: return "iPhone 15 Pro"
        case .ipadMini: return "iPad mini"
        }
    }

    var size: CGSize {
        switch self {
        case .iphoneSE: return CGSize(width: 375, height: 667)
        case .iphone15Pro: return CGSize(width: 393, height: 852)
        case .ipadMini: return CGSize(width: 744, height: 1133)
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .iphoneSE: return 38
        case .iphone15Pro: return 48
        case .ipadMini: return 36
        }
    }

    var safeAreaInsets: EdgeInsets {
        switch self {
        case .iphoneSE:
            return EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0)
        case .iphone15Pro:
            return EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
        case .ipadMini:
            return EdgeInsets(top: 24, leading: 0, bottom: 22, trailing: 0)
        }
    }
}

enum PreviewAppearance: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var colorScheme: ColorScheme {
        self == .dark ? .dark : .light
    }

    var deviceShellColor: Color {
        self == .dark ? Color.black.opacity(0.92) : Color.black.opacity(0.25)
    }

    var bezelHighlight: Color {
        self == .dark ? Color.black.opacity(0.75) : Color.white.opacity(0.7)
    }

    var deviceInnerRim: Color {
        self == .dark ? Color.black.opacity(0.88) : Color.black.opacity(0.82)
    }

    var canvasBackground: Color {
        self == .dark ? Color(red: 0.09, green: 0.1, blue: 0.12) : Color.white
    }

    var screenStroke: Color {
        self == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }
}

struct BuilderProject: Codable {
    var name: String
    var device: String
    var appearance: String
    var blocks: [ExportedBlock]
    var exportedAt: Date
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
}

struct ColorComponents: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
}

struct ProjectExporter {
    func export(_ project: BuilderProject, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(project)
        try data.write(to: url, options: .atomic)
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

extension CanvasBlock {
    func exportRepresentation() -> ExportedBlock {
        ExportedBlock(
            kind: kind.exportKey,
            content: content,
            symbolName: symbolName,
            alignment: alignment.exportKey,
            fontSize: fontSize,
            fontWeight: fontWeight.exportKey,
            textColor: textColor.toComponents(),
            fillColor: fillColor.toComponents(),
            spacingBefore: spacingBefore,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding,
            cornerRadius: cornerRadius,
            symbolScale: symbolScale,
            listItems: listItems
        )
    }
}

extension CanvasBlock {
    init(from exported: ExportedBlock) {
        let kind = CanvasBlock.Kind.allCases.first(where: { $0.exportKey == exported.kind }) ?? .heroTitle
        let alignment = BlockAlignment(rawValue: exported.alignment) ?? .leading
        let weight = FontWeightOption(rawValue: exported.fontWeight) ?? .regular

        self.init(
            kind: kind,
            content: exported.content,
            symbolName: exported.symbolName,
            alignment: alignment,
            fontSize: exported.fontSize,
            fontWeight: weight,
            textColor: exported.textColor.color,
            fillColor: exported.fillColor.color,
            spacingBefore: exported.spacingBefore,
            horizontalPadding: exported.horizontalPadding,
            verticalPadding: exported.verticalPadding,
            cornerRadius: exported.cornerRadius,
            symbolScale: exported.symbolScale,
            listItems: exported.listItems
        )
    }
}

private extension ColorComponents {
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension Color {
    func ensuringContrast(in appearance: PreviewAppearance, minimumLuminance: Double = 0.62) -> Color {
        guard appearance == .dark else { return self }
        guard let luminance = relativeLuminance else { return self }
        if luminance >= minimumLuminance { return self }
        let blendAmount = min(0.95, (minimumLuminance - luminance) * 1.8)
        return blended(with: .white, amount: blendAmount)
    }

    func toComponents() -> ColorComponents {
        if let rgb = rgbComponents() {
            return ColorComponents(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: rgb.alpha)
        }
        return ColorComponents(red: 0, green: 0, blue: 0, alpha: 1)
    }

    private func blended(with color: Color, amount: Double) -> Color {
        guard let first = rgbComponents(), let second = color.rgbComponents() else { return self }
        let ratio = max(0, min(1, amount))
        let red = clamp(first.red + (second.red - first.red) * ratio)
        let green = clamp(first.green + (second.green - first.green) * ratio)
        let blue = clamp(first.blue + (second.blue - first.blue) * ratio)
        let alpha = clamp(first.alpha + (second.alpha - first.alpha) * ratio)
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    private func rgbComponents() -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        #if os(macOS)
        guard let platformColor = NSColor(self).usingColorSpace(.deviceRGB) else { return nil }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue), Double(alpha))
        #else
        let platformColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return (Double(red), Double(green), Double(blue), Double(alpha))
        #endif
    }

    private var relativeLuminance: Double? {
        guard let components = rgbComponents() else { return nil }
        let red = linearized(components.red)
        let green = linearized(components.green)
        let blue = linearized(components.blue)
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    private func linearized(_ value: Double) -> Double {
        value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
