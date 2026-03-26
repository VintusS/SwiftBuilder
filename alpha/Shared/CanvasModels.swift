import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct CanvasBlock: Identifiable {
    enum Kind: String, CaseIterable, Identifiable {
        case symbol, heroTitle, bodyText, caption, primaryButton, secondaryButton, linkButton
        case list, card, iconRow
        case image, textField, toggle, divider, spacer
        case segmentedControl, slider, avatar, badge
        case searchBar, progressBar, mapPlaceholder

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .heroTitle: return "Heading"
            case .bodyText: return "Body Text"
            case .caption: return "Caption"
            case .badge: return "Badge"
            case .primaryButton: return "Primary Button"
            case .secondaryButton: return "Secondary Button"
            case .linkButton: return "Link Button"
            case .textField: return "Text Field"
            case .searchBar: return "Search Bar"
            case .toggle: return "Toggle"
            case .slider: return "Slider"
            case .segmentedControl: return "Segmented Control"
            case .symbol: return "Icon"
            case .image: return "Image"
            case .avatar: return "Avatar"
            case .mapPlaceholder: return "Map"
            case .list: return "List"
            case .card: return "Card"
            case .iconRow: return "Info Row"
            case .divider: return "Divider"
            case .spacer: return "Spacer"
            case .progressBar: return "Progress Bar"
            }
        }

        var description: String {
            switch self {
            case .heroTitle: return "Large bold title or headline."
            case .bodyText: return "Paragraph text with line spacing."
            case .caption: return "Small label or helper text."
            case .badge: return "Pill-shaped tag or status label."
            case .primaryButton: return "Filled call-to-action button."
            case .secondaryButton: return "Outlined secondary action."
            case .linkButton: return "Text-only tappable link."
            case .textField: return "Input field with placeholder."
            case .searchBar: return "Search input with icon."
            case .toggle: return "On/off switch with label."
            case .slider: return "Adjustable value slider."
            case .segmentedControl: return "Horizontal tab picker."
            case .symbol: return "Large SF Symbol icon."
            case .image: return "Image placeholder area."
            case .avatar: return "Circular profile image."
            case .mapPlaceholder: return "Map area placeholder."
            case .list: return "Vertical list of text rows."
            case .card: return "Rounded card with title and description."
            case .iconRow: return "Icon, label, value, and chevron row."
            case .divider: return "Horizontal separator line."
            case .spacer: return "Flexible vertical space."
            case .progressBar: return "Horizontal progress indicator."
            }
        }

        var iconSystemName: String {
            switch self {
            case .heroTitle: return "textformat.size.larger"
            case .bodyText: return "text.alignleft"
            case .caption: return "textformat.size.smaller"
            case .badge: return "capsule.fill"
            case .primaryButton: return "button.horizontal.top.press.fill"
            case .secondaryButton: return "button.horizontal"
            case .linkButton: return "link"
            case .textField: return "character.cursor.ibeam"
            case .searchBar: return "magnifyingglass"
            case .toggle: return "switch.2"
            case .slider: return "slider.horizontal.3"
            case .segmentedControl: return "rectangle.split.3x1"
            case .symbol: return "sparkles"
            case .image: return "photo"
            case .avatar: return "person.circle"
            case .mapPlaceholder: return "map"
            case .list: return "list.bullet"
            case .card: return "rectangle.on.rectangle"
            case .iconRow: return "list.bullet.indent"
            case .divider: return "minus"
            case .spacer: return "arrow.up.and.down"
            case .progressBar: return "chart.bar.fill"
            }
        }

        var paletteColor: Color {
            switch self {
            case .heroTitle: return Color(red: 0.40, green: 0.48, blue: 0.96)
            case .bodyText: return Color(red: 0.38, green: 0.69, blue: 0.96)
            case .caption: return Color(red: 0.52, green: 0.60, blue: 0.90)
            case .badge: return Color(red: 0.96, green: 0.36, blue: 0.42)
            case .primaryButton: return Color(red: 0.29, green: 0.56, blue: 0.93)
            case .secondaryButton: return Color(red: 0.40, green: 0.60, blue: 0.95)
            case .linkButton: return Color(red: 0.32, green: 0.52, blue: 0.96)
            case .textField: return Color(red: 0.38, green: 0.82, blue: 0.60)
            case .searchBar: return Color(red: 0.50, green: 0.66, blue: 0.96)
            case .toggle: return Color(red: 0.34, green: 0.80, blue: 0.46)
            case .slider: return Color(red: 0.29, green: 0.56, blue: 0.96)
            case .segmentedControl: return Color(red: 0.56, green: 0.48, blue: 0.96)
            case .symbol: return Color(red: 0.56, green: 0.41, blue: 0.96)
            case .image: return Color(red: 0.96, green: 0.56, blue: 0.41)
            case .avatar: return Color(red: 0.96, green: 0.68, blue: 0.38)
            case .mapPlaceholder: return Color(red: 0.38, green: 0.76, blue: 0.52)
            case .list: return Color(red: 0.96, green: 0.48, blue: 0.40)
            case .card: return Color(red: 0.96, green: 0.62, blue: 0.30)
            case .iconRow: return Color(red: 0.55, green: 0.50, blue: 0.96)
            case .divider: return Color(red: 0.60, green: 0.60, blue: 0.64)
            case .spacer: return Color(red: 0.50, green: 0.50, blue: 0.56)
            case .progressBar: return Color(red: 0.38, green: 0.82, blue: 0.96)
            }
        }

        var exportKey: String { rawValue }

        struct Category: Identifiable {
            let id: String
            let name: String
            let icon: String
            let kinds: [Kind]
        }

        static let categories: [Category] = [
            Category(id: "text", name: "Text", icon: "textformat", kinds: [.heroTitle, .bodyText, .caption, .badge]),
            Category(id: "buttons", name: "Buttons", icon: "cursorarrow.click.2", kinds: [.primaryButton, .secondaryButton, .linkButton]),
            Category(id: "inputs", name: "Inputs", icon: "rectangle.and.pencil.and.ellipsis", kinds: [.textField, .searchBar, .toggle, .slider, .segmentedControl]),
            Category(id: "media", name: "Media", icon: "photo.on.rectangle", kinds: [.symbol, .image, .avatar, .mapPlaceholder]),
            Category(id: "data", name: "Data Display", icon: "rectangle.stack", kinds: [.list, .card, .iconRow]),
            Category(id: "layout", name: "Layout", icon: "square.split.2x1", kinds: [.divider, .spacer, .progressBar]),
        ]
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
    var navigationTarget: UUID?

    var outlineSummary: String {
        switch kind {
        case .symbol: return symbolName.isEmpty ? "sparkles" : symbolName
        case .primaryButton, .secondaryButton, .linkButton, .heroTitle, .bodyText, .caption, .badge: return content
        case .list: return "\(listItems.count) items"
        case .image: return symbolName.isEmpty ? "photo" : symbolName
        case .textField: return content.isEmpty ? "Text Field" : content
        case .toggle: return content
        case .divider: return "Separator"
        case .spacer: return "\(Int(spacingBefore))pt space"
        case .segmentedControl: return "\(listItems.count) segments"
        case .slider: return content
        case .avatar: return symbolName.isEmpty ? "Avatar" : symbolName
        case .searchBar: return "Search"
        case .progressBar: return "\(Int(symbolScale * 100))%"
        case .card: return content
        case .iconRow: return content
        case .mapPlaceholder: return "Map"
        }
    }

    var selectionCornerRadius: CGFloat {
        switch kind {
        case .primaryButton, .secondaryButton: return CGFloat(cornerRadius + 6)
        case .symbol: return 20
        case .list: return 16
        case .image, .mapPlaceholder: return CGFloat(cornerRadius + 4)
        case .textField, .searchBar: return CGFloat(cornerRadius + 4)
        case .toggle, .slider: return 10
        case .avatar: return 50
        case .badge: return CGFloat(cornerRadius + 4)
        case .segmentedControl: return 12
        case .progressBar: return 8
        case .divider, .spacer: return 4
        case .card: return CGFloat(cornerRadius + 4)
        case .iconRow: return CGFloat(cornerRadius + 4)
        case .linkButton, .caption: return 6
        default: return 8
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
        case .caption:
            return CanvasBlock(
                kind: .caption, content: "Caption or helper text", symbolName: "", alignment: .leading,
                fontSize: 13, fontWeight: .regular,
                textColor: Color(red: 0.50, green: 0.50, blue: 0.54), fillColor: .clear,
                spacingBefore: 8, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: []
            )
        case .secondaryButton:
            return CanvasBlock(
                kind: .secondaryButton, content: "Secondary Action", symbolName: "", alignment: .center,
                fontSize: 17, fontWeight: .semibold,
                textColor: Color(red: 0.29, green: 0.46, blue: 0.96), fillColor: .clear,
                spacingBefore: 12, horizontalPadding: 20, verticalPadding: 12,
                cornerRadius: 18, symbolScale: 1, listItems: []
            )
        case .linkButton:
            return CanvasBlock(
                kind: .linkButton, content: "Learn More", symbolName: "", alignment: .center,
                fontSize: 16, fontWeight: .medium,
                textColor: Color(red: 0.29, green: 0.46, blue: 0.96), fillColor: .clear,
                spacingBefore: 8, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: []
            )
        case .card:
            return CanvasBlock(
                kind: .card, content: "Card Title", symbolName: "star.fill",
                alignment: .leading, fontSize: 17, fontWeight: .semibold,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.97, green: 0.97, blue: 0.98),
                spacingBefore: 12, horizontalPadding: 16, verticalPadding: 14,
                cornerRadius: 16, symbolScale: 1,
                listItems: ["A brief description or supporting info."]
            )
        case .iconRow:
            return CanvasBlock(
                kind: .iconRow, content: "Settings Item", symbolName: "gearshape.fill",
                alignment: .leading, fontSize: 16, fontWeight: .regular,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.29, green: 0.56, blue: 0.96),
                spacingBefore: 4, horizontalPadding: 16, verticalPadding: 12,
                cornerRadius: 12, symbolScale: 1,
                listItems: ["Value"]
            )
        case .mapPlaceholder:
            return CanvasBlock(
                kind: .mapPlaceholder, content: "", symbolName: "map.fill", alignment: .center,
                fontSize: 0, fontWeight: .regular, textColor: .secondary,
                fillColor: Color(red: 0.85, green: 0.92, blue: 0.85),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 16, symbolScale: 1.0, listItems: []
            )
        case .list:
            return CanvasBlock(
                kind: .list, content: "", symbolName: "", alignment: .leading,
                fontSize: 17, fontWeight: .regular,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.96, green: 0.97, blue: 0.98),
                spacingBefore: 18, horizontalPadding: 16, verticalPadding: 12,
                cornerRadius: 12, symbolScale: 1,
                listItems: ["First item", "Second item", "Third item"]
            )
        case .image:
            return CanvasBlock(
                kind: .image, content: "", symbolName: "photo.fill", alignment: .center,
                fontSize: 0, fontWeight: .regular, textColor: .secondary,
                fillColor: Color(red: 0.92, green: 0.93, blue: 0.95),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 12, symbolScale: 0.8, listItems: []
            )
        case .textField:
            return CanvasBlock(
                kind: .textField, content: "Enter text...", symbolName: "", alignment: .leading,
                fontSize: 16, fontWeight: .regular,
                textColor: Color(red: 0.60, green: 0.60, blue: 0.64),
                fillColor: Color(red: 0.95, green: 0.95, blue: 0.97),
                spacingBefore: 12, horizontalPadding: 14, verticalPadding: 12,
                cornerRadius: 10, symbolScale: 1, listItems: []
            )
        case .toggle:
            return CanvasBlock(
                kind: .toggle, content: "Enable notifications", symbolName: "", alignment: .leading,
                fontSize: 17, fontWeight: .regular,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.34, green: 0.80, blue: 0.46),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: []
            )
        case .divider:
            return CanvasBlock(
                kind: .divider, content: "", symbolName: "", alignment: .center,
                fontSize: 0, fontWeight: .regular, textColor: .clear,
                fillColor: Color(red: 0.78, green: 0.78, blue: 0.80),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: []
            )
        case .spacer:
            return CanvasBlock(
                kind: .spacer, content: "", symbolName: "", alignment: .center,
                fontSize: 0, fontWeight: .regular, textColor: .clear, fillColor: .clear,
                spacingBefore: 32, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: []
            )
        case .segmentedControl:
            return CanvasBlock(
                kind: .segmentedControl, content: "", symbolName: "", alignment: .center,
                fontSize: 14, fontWeight: .medium,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.93, green: 0.93, blue: 0.95),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 8, symbolScale: 0, listItems: ["First", "Second", "Third"]
            )
        case .slider:
            return CanvasBlock(
                kind: .slider, content: "Volume", symbolName: "", alignment: .leading,
                fontSize: 16, fontWeight: .regular,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.29, green: 0.56, blue: 0.96),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 0.5, listItems: []
            )
        case .avatar:
            return CanvasBlock(
                kind: .avatar, content: "", symbolName: "person.fill", alignment: .center,
                fontSize: 0, fontWeight: .regular, textColor: .white,
                fillColor: Color(red: 0.56, green: 0.48, blue: 0.96),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: []
            )
        case .badge:
            return CanvasBlock(
                kind: .badge, content: "New", symbolName: "", alignment: .leading,
                fontSize: 13, fontWeight: .semibold, textColor: .white,
                fillColor: Color(red: 0.96, green: 0.36, blue: 0.42),
                spacingBefore: 8, horizontalPadding: 10, verticalPadding: 4,
                cornerRadius: 12, symbolScale: 1, listItems: []
            )
        case .searchBar:
            return CanvasBlock(
                kind: .searchBar, content: "Search...", symbolName: "magnifyingglass",
                alignment: .leading, fontSize: 16, fontWeight: .regular,
                textColor: Color(red: 0.60, green: 0.60, blue: 0.64),
                fillColor: Color(red: 0.95, green: 0.95, blue: 0.97),
                spacingBefore: 12, horizontalPadding: 12, verticalPadding: 10,
                cornerRadius: 10, symbolScale: 1, listItems: []
            )
        case .progressBar:
            return CanvasBlock(
                kind: .progressBar, content: "", symbolName: "", alignment: .center,
                fontSize: 0, fontWeight: .regular, textColor: .clear,
                fillColor: Color(red: 0.29, green: 0.56, blue: 0.96),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 4, symbolScale: 0.6, listItems: []
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
            listItems: listItems,
            navigationTarget: navigationTarget?.uuidString
        )
    }
}

extension CanvasBlock {
    init(from exported: ExportedBlock) {
        let kind = CanvasBlock.Kind(rawValue: exported.kind) ?? .heroTitle
        let alignment = BlockAlignment(rawValue: exported.alignment) ?? .leading
        let weight = FontWeightOption(rawValue: exported.fontWeight) ?? .regular
        let navTarget: UUID? = exported.navigationTarget.flatMap { UUID(uuidString: $0) }

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
            listItems: exported.listItems,
            navigationTarget: navTarget
        )
    }
}

extension Screen {
    func exportRepresentation() -> ExportedScreen {
        ExportedScreen(
            id: id.uuidString,
            name: name,
            blocks: blocks.map { $0.exportRepresentation() }
        )
    }

    init(from exported: ExportedScreen) {
        self.init(
            id: UUID(uuidString: exported.id) ?? UUID(),
            name: exported.name,
            blocks: exported.blocks.map { CanvasBlock(from: $0) }
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
