import SwiftUI

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
    var opacity: Double = 1.0
    var borderWidth: Double = 0
    var lineSpacing: Double = 4
    var shadowRadius: Double = 0
    var rowGroupID: UUID? = nil

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
                kind: .symbol, content: "", symbolName: "iphone", alignment: .center,
                fontSize: 0, fontWeight: .light, textColor: .primary,
                fillColor: Color(red: 0.45, green: 0.52, blue: 0.96),
                spacingBefore: 0, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1.1, listItems: [])
        case .heroTitle:
            return CanvasBlock(
                kind: .heroTitle, content: "Design onboarding screens in minutes", symbolName: "", alignment: .leading,
                fontSize: 32, fontWeight: .bold,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28), fillColor: .clear,
                spacingBefore: 18, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: [])
        case .bodyText:
            return CanvasBlock(
                kind: .bodyText, content: "Compose flows visually, then preview them instantly on real device frames.", symbolName: "", alignment: .leading,
                fontSize: 18, fontWeight: .regular,
                textColor: Color(red: 0.33, green: 0.38, blue: 0.48), fillColor: .clear,
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: [])
        case .primaryButton:
            return CanvasBlock(
                kind: .primaryButton, content: "Preview Prototype", symbolName: "", alignment: .center,
                fontSize: 18, fontWeight: .semibold, textColor: .white,
                fillColor: Color(red: 0.29, green: 0.46, blue: 0.96),
                spacingBefore: 18, horizontalPadding: 20, verticalPadding: 14,
                cornerRadius: 18, symbolScale: 1, listItems: [])
        case .caption:
            return CanvasBlock(
                kind: .caption, content: "Caption or helper text", symbolName: "", alignment: .leading,
                fontSize: 13, fontWeight: .regular,
                textColor: Color(red: 0.50, green: 0.50, blue: 0.54), fillColor: .clear,
                spacingBefore: 8, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: [])
        case .secondaryButton:
            return CanvasBlock(
                kind: .secondaryButton, content: "Secondary Action", symbolName: "", alignment: .center,
                fontSize: 17, fontWeight: .semibold,
                textColor: Color(red: 0.29, green: 0.46, blue: 0.96), fillColor: .clear,
                spacingBefore: 12, horizontalPadding: 20, verticalPadding: 12,
                cornerRadius: 18, symbolScale: 1, listItems: [])
        case .linkButton:
            return CanvasBlock(
                kind: .linkButton, content: "Learn More", symbolName: "", alignment: .center,
                fontSize: 16, fontWeight: .medium,
                textColor: Color(red: 0.29, green: 0.46, blue: 0.96), fillColor: .clear,
                spacingBefore: 8, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: [])
        case .card:
            return CanvasBlock(
                kind: .card, content: "Card Title", symbolName: "star.fill",
                alignment: .leading, fontSize: 17, fontWeight: .semibold,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.97, green: 0.97, blue: 0.98),
                spacingBefore: 12, horizontalPadding: 16, verticalPadding: 14,
                cornerRadius: 16, symbolScale: 1,
                listItems: ["A brief description or supporting info."])
        case .iconRow:
            return CanvasBlock(
                kind: .iconRow, content: "Settings Item", symbolName: "gearshape.fill",
                alignment: .leading, fontSize: 16, fontWeight: .regular,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.29, green: 0.56, blue: 0.96),
                spacingBefore: 4, horizontalPadding: 16, verticalPadding: 12,
                cornerRadius: 12, symbolScale: 1, listItems: ["Value"])
        case .mapPlaceholder:
            return CanvasBlock(
                kind: .mapPlaceholder, content: "", symbolName: "map.fill", alignment: .center,
                fontSize: 0, fontWeight: .regular, textColor: .secondary,
                fillColor: Color(red: 0.85, green: 0.92, blue: 0.85),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 16, symbolScale: 1.0, listItems: [])
        case .list:
            return CanvasBlock(
                kind: .list, content: "", symbolName: "", alignment: .leading,
                fontSize: 17, fontWeight: .regular,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.96, green: 0.97, blue: 0.98),
                spacingBefore: 18, horizontalPadding: 16, verticalPadding: 12,
                cornerRadius: 12, symbolScale: 1,
                listItems: ["First item", "Second item", "Third item"])
        case .image:
            return CanvasBlock(
                kind: .image, content: "", symbolName: "photo.fill", alignment: .center,
                fontSize: 0, fontWeight: .light, textColor: .secondary,
                fillColor: Color(red: 0.92, green: 0.93, blue: 0.95),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 12, symbolScale: 0.8, listItems: [])
        case .textField:
            return CanvasBlock(
                kind: .textField, content: "Enter text...", symbolName: "", alignment: .leading,
                fontSize: 16, fontWeight: .regular,
                textColor: Color(red: 0.60, green: 0.60, blue: 0.64),
                fillColor: Color(red: 0.95, green: 0.95, blue: 0.97),
                spacingBefore: 12, horizontalPadding: 14, verticalPadding: 12,
                cornerRadius: 10, symbolScale: 1, listItems: [])
        case .toggle:
            return CanvasBlock(
                kind: .toggle, content: "Enable notifications", symbolName: "", alignment: .leading,
                fontSize: 17, fontWeight: .regular,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.34, green: 0.80, blue: 0.46),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: [])
        case .divider:
            return CanvasBlock(
                kind: .divider, content: "", symbolName: "", alignment: .center,
                fontSize: 0, fontWeight: .regular, textColor: .clear,
                fillColor: Color(red: 0.78, green: 0.78, blue: 0.80),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: [])
        case .spacer:
            return CanvasBlock(
                kind: .spacer, content: "", symbolName: "", alignment: .center,
                fontSize: 0, fontWeight: .regular, textColor: .clear, fillColor: .clear,
                spacingBefore: 32, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: [])
        case .segmentedControl:
            return CanvasBlock(
                kind: .segmentedControl, content: "", symbolName: "", alignment: .center,
                fontSize: 14, fontWeight: .medium,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.93, green: 0.93, blue: 0.95),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 8, symbolScale: 0, listItems: ["First", "Second", "Third"])
        case .slider:
            return CanvasBlock(
                kind: .slider, content: "Volume", symbolName: "", alignment: .leading,
                fontSize: 16, fontWeight: .regular,
                textColor: Color(red: 0.15, green: 0.17, blue: 0.28),
                fillColor: Color(red: 0.29, green: 0.56, blue: 0.96),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 0.5, listItems: [])
        case .avatar:
            return CanvasBlock(
                kind: .avatar, content: "", symbolName: "person.fill", alignment: .center,
                fontSize: 0, fontWeight: .regular, textColor: .white,
                fillColor: Color(red: 0.56, green: 0.48, blue: 0.96),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 0, symbolScale: 1, listItems: [])
        case .badge:
            return CanvasBlock(
                kind: .badge, content: "New", symbolName: "", alignment: .leading,
                fontSize: 13, fontWeight: .semibold, textColor: .white,
                fillColor: Color(red: 0.96, green: 0.36, blue: 0.42),
                spacingBefore: 8, horizontalPadding: 10, verticalPadding: 4,
                cornerRadius: 12, symbolScale: 1, listItems: [])
        case .searchBar:
            return CanvasBlock(
                kind: .searchBar, content: "Search...", symbolName: "magnifyingglass",
                alignment: .leading, fontSize: 16, fontWeight: .regular,
                textColor: Color(red: 0.60, green: 0.60, blue: 0.64),
                fillColor: Color(red: 0.95, green: 0.95, blue: 0.97),
                spacingBefore: 12, horizontalPadding: 12, verticalPadding: 10,
                cornerRadius: 10, symbolScale: 1, listItems: [])
        case .progressBar:
            return CanvasBlock(
                kind: .progressBar, content: "", symbolName: "", alignment: .center,
                fontSize: 0, fontWeight: .regular, textColor: .clear,
                fillColor: Color(red: 0.29, green: 0.56, blue: 0.96),
                spacingBefore: 12, horizontalPadding: 0, verticalPadding: 0,
                cornerRadius: 4, symbolScale: 0.6, listItems: [])
        }
    }
}
