import SwiftUI

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
            navigationTarget: navigationTarget?.uuidString,
            opacity: opacity,
            borderWidth: borderWidth,
            lineSpacing: lineSpacing,
            shadowRadius: shadowRadius,
            rowGroupID: rowGroupID?.uuidString
        )
    }
}

extension CanvasBlock {
    init(from exported: ExportedBlock) {
        let kind = CanvasBlock.Kind(rawValue: exported.kind) ?? .heroTitle
        let alignment = BlockAlignment(rawValue: exported.alignment) ?? .leading
        let weight = FontWeightOption(rawValue: exported.fontWeight) ?? .regular
        let navTarget: UUID? = exported.navigationTarget.flatMap { UUID(uuidString: $0) }
        let rowGroup: UUID? = exported.rowGroupID.flatMap { UUID(uuidString: $0) }

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
            navigationTarget: navTarget,
            opacity: exported.opacity ?? 1.0,
            borderWidth: exported.borderWidth ?? 0,
            lineSpacing: exported.lineSpacing ?? 4,
            shadowRadius: exported.shadowRadius ?? 0,
            rowGroupID: rowGroup
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

extension ColorComponents {
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
