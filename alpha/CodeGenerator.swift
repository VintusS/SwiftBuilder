//
//  CodeGenerator.swift
//  alpha
//

import SwiftUI

struct CodeGenerator {

    static func generate(screens: [Screen], projectName: String, appearance: PreviewAppearance) -> String {
        var out = "import SwiftUI\n\n"

        if screens.count > 1 {
            out += generateRootView(screens: screens, projectName: projectName)
        }

        for screen in screens {
            out += generateScreenView(screen, allScreens: screens, appearance: appearance)
            out += "\n"
        }

        return out
    }

    // MARK: - Root

    private static func generateRootView(screens: [Screen], projectName: String) -> String {
        let name = sanitize(projectName)
        var s = "struct \(name)App: View {\n"
        s += "    var body: some View {\n"
        s += "        NavigationStack {\n"
        s += "            \(viewName(for: screens[0]))()\n"
        s += "        }\n"
        s += "    }\n"
        s += "}\n\n"
        return s
    }

    // MARK: - Screen

    private static func generateScreenView(_ screen: Screen, allScreens: [Screen], appearance: PreviewAppearance) -> String {
        let name = viewName(for: screen)
        var s = "struct \(name): View {\n"
        s += "    var body: some View {\n"
        s += "        ScrollView {\n"
        s += "            VStack(alignment: .leading, spacing: 0) {\n"

        for block in screen.blocks {
            let blockCode = generateBlock(block, allScreens: allScreens, appearance: appearance, indent: 4)
            s += blockCode
        }

        s += "                Spacer(minLength: 16)\n"
        s += "            }\n"
        s += "            .padding(.horizontal, 24)\n"
        s += "        }\n"
        s += "    }\n"
        s += "}\n"
        return s
    }

    // MARK: - Block

    private static func generateBlock(_ block: CanvasBlock, allScreens: [Screen], appearance: PreviewAppearance, indent: Int) -> String {
        let pad = String(repeating: "    ", count: indent)
        var lines: [String] = []

        if block.spacingBefore > 0 && block.kind != .spacer {
            lines.append("\(pad)Spacer().frame(height: \(Int(block.spacingBefore)))")
        }

        let hasNav = block.navigationTarget != nil
        let destScreen = hasNav ? allScreens.first(where: { $0.id == block.navigationTarget }) : nil

        if let dest = destScreen {
            lines.append("\(pad)NavigationLink {")
            lines.append("\(pad)    \(viewName(for: dest))()")
            lines.append("\(pad)} label: {")
            lines.append(contentsOf: blockBody(block, appearance: appearance, indent: indent + 1))
            lines.append("\(pad)}")
            lines.append("\(pad).buttonStyle(.plain)")
        } else {
            lines.append(contentsOf: blockBody(block, appearance: appearance, indent: indent))
        }

        return lines.map { $0 + "\n" }.joined()
    }

    private static func blockBody(_ block: CanvasBlock, appearance: PreviewAppearance, indent: Int) -> [String] {
        let pad = String(repeating: "    ", count: indent)
        var lines: [String] = []

        switch block.kind {
        case .heroTitle:
            lines.append("\(pad)Text(\(quoted(block.content)))")
            lines.append("\(pad)    .font(.system(size: \(Int(block.fontSize)), weight: .\(block.fontWeight.rawValue), design: .rounded))")
            lines.append("\(pad)    .foregroundColor(\(colorLiteral(block.textColor)))")
            lines.append("\(pad)    .multilineTextAlignment(.\(block.alignment.rawValue))")
            lines.append("\(pad)    .frame(maxWidth: .infinity, alignment: .\(block.alignment.rawValue))")

        case .bodyText:
            lines.append("\(pad)Text(\(quoted(block.content)))")
            lines.append("\(pad)    .font(.system(size: \(Int(block.fontSize)), weight: .\(block.fontWeight.rawValue), design: .rounded))")
            lines.append("\(pad)    .foregroundColor(\(colorLiteral(block.textColor)))")
            lines.append("\(pad)    .lineSpacing(4)")
            lines.append("\(pad)    .frame(maxWidth: .infinity, alignment: .\(block.alignment.rawValue))")

        case .caption:
            lines.append("\(pad)Text(\(quoted(block.content)))")
            lines.append("\(pad)    .font(.system(size: \(Int(block.fontSize)), weight: .\(block.fontWeight.rawValue), design: .rounded))")
            lines.append("\(pad)    .foregroundColor(\(colorLiteral(block.textColor)))")
            lines.append("\(pad)    .frame(maxWidth: .infinity, alignment: .\(block.alignment.rawValue))")

        case .primaryButton:
            lines.append("\(pad)Button(action: {}) {")
            lines.append("\(pad)    Text(\(quoted(block.content)))")
            lines.append("\(pad)        .font(.system(size: \(Int(block.fontSize)), weight: .\(block.fontWeight.rawValue), design: .rounded))")
            lines.append("\(pad)        .foregroundColor(\(colorLiteral(block.textColor)))")
            lines.append("\(pad)        .frame(maxWidth: .infinity)")
            lines.append("\(pad)        .padding(.horizontal, \(Int(block.horizontalPadding)))")
            lines.append("\(pad)        .padding(.vertical, \(Int(block.verticalPadding)))")
            lines.append("\(pad)        .background(RoundedRectangle(cornerRadius: \(Int(block.cornerRadius)), style: .continuous).fill(\(colorLiteral(block.fillColor))))")
            lines.append("\(pad)}")
            lines.append("\(pad).buttonStyle(.plain)")

        case .secondaryButton:
            lines.append("\(pad)Button(action: {}) {")
            lines.append("\(pad)    Text(\(quoted(block.content)))")
            lines.append("\(pad)        .font(.system(size: \(Int(block.fontSize)), weight: .\(block.fontWeight.rawValue), design: .rounded))")
            lines.append("\(pad)        .foregroundColor(\(colorLiteral(block.textColor)))")
            lines.append("\(pad)        .frame(maxWidth: .infinity)")
            lines.append("\(pad)        .padding(.horizontal, \(Int(block.horizontalPadding)))")
            lines.append("\(pad)        .padding(.vertical, \(Int(block.verticalPadding)))")
            lines.append("\(pad)        .overlay(RoundedRectangle(cornerRadius: \(Int(block.cornerRadius)), style: .continuous).stroke(\(colorLiteral(block.textColor)), lineWidth: 1.5))")
            lines.append("\(pad)}")
            lines.append("\(pad).buttonStyle(.plain)")

        case .linkButton:
            lines.append("\(pad)Button(\(quoted(block.content)), action: {})")
            lines.append("\(pad)    .font(.system(size: \(Int(block.fontSize)), weight: .\(block.fontWeight.rawValue), design: .rounded))")
            lines.append("\(pad)    .foregroundColor(\(colorLiteral(block.textColor)))")
            lines.append("\(pad)    .frame(maxWidth: .infinity, alignment: .\(block.alignment.rawValue))")

        case .symbol:
            let name = block.symbolName.isEmpty ? "sparkles" : block.symbolName
            lines.append("\(pad)Image(systemName: \(quoted(name)))")
            lines.append("\(pad)    .font(.system(size: \(Int(80 * block.symbolScale)), weight: .light))")
            lines.append("\(pad)    .foregroundColor(\(colorLiteral(block.fillColor)))")
            lines.append("\(pad)    .frame(maxWidth: .infinity)")
            lines.append("\(pad)    .padding(.vertical, 26)")

        case .list:
            let items = block.listItems.map { quoted($0) }.joined(separator: ", ")
            lines.append("\(pad)VStack(alignment: .leading, spacing: 0) {")
            lines.append("\(pad)    ForEach([\(items)], id: \\.self) { item in")
            lines.append("\(pad)        HStack(spacing: 12) {")
            lines.append("\(pad)            Circle().fill(\(colorLiteral(block.textColor)).opacity(0.6)).frame(width: 6, height: 6)")
            lines.append("\(pad)            Text(item)")
            lines.append("\(pad)                .font(.system(size: \(Int(block.fontSize)), weight: .\(block.fontWeight.rawValue), design: .rounded))")
            lines.append("\(pad)                .foregroundColor(\(colorLiteral(block.textColor)))")
            lines.append("\(pad)            Spacer()")
            lines.append("\(pad)        }")
            lines.append("\(pad)        .padding(.horizontal, \(Int(block.horizontalPadding)))")
            lines.append("\(pad)        .padding(.vertical, \(Int(block.verticalPadding)))")
            lines.append("\(pad)    }")
            lines.append("\(pad)}")
            lines.append("\(pad).background(RoundedRectangle(cornerRadius: \(Int(block.cornerRadius)), style: .continuous).fill(\(colorLiteral(block.fillColor))))")

        case .image:
            let name = block.symbolName.isEmpty ? "photo.fill" : block.symbolName
            lines.append("\(pad)ZStack {")
            lines.append("\(pad)    RoundedRectangle(cornerRadius: \(Int(block.cornerRadius)), style: .continuous)")
            lines.append("\(pad)        .fill(\(colorLiteral(block.fillColor)))")
            lines.append("\(pad)    Image(systemName: \(quoted(name)))")
            lines.append("\(pad)        .font(.system(size: \(Int(40 * block.symbolScale)), weight: .light))")
            lines.append("\(pad)        .foregroundColor(.secondary.opacity(0.5))")
            lines.append("\(pad)}")
            lines.append("\(pad).frame(maxWidth: .infinity)")
            lines.append("\(pad).frame(height: \(Int(160 * block.symbolScale)))")

        case .textField:
            lines.append("\(pad)TextField(\(quoted(block.content)), text: .constant(\"\"))")
            lines.append("\(pad)    .font(.system(size: \(Int(block.fontSize)), design: .rounded))")
            lines.append("\(pad)    .padding(.horizontal, \(Int(block.horizontalPadding)))")
            lines.append("\(pad)    .padding(.vertical, \(Int(block.verticalPadding)))")
            lines.append("\(pad)    .background(RoundedRectangle(cornerRadius: \(Int(block.cornerRadius)), style: .continuous).fill(\(colorLiteral(block.fillColor))))")

        case .toggle:
            let isOn = block.symbolScale >= 0.5
            lines.append("\(pad)Toggle(\(quoted(block.content)), isOn: .constant(\(isOn)))")
            lines.append("\(pad)    .font(.system(size: \(Int(block.fontSize)), design: .rounded))")
            lines.append("\(pad)    .tint(\(colorLiteral(block.fillColor)))")

        case .divider:
            lines.append("\(pad)Divider()")

        case .spacer:
            lines.append("\(pad)Spacer().frame(height: \(Int(block.spacingBefore)))")

        case .segmentedControl:
            let items = block.listItems.map { quoted($0) }.joined(separator: ", ")
            let sel = Int(block.symbolScale)
            lines.append("\(pad)Picker(\"\", selection: .constant(\(sel))) {")
            lines.append("\(pad)    ForEach(Array([\(items)].enumerated()), id: \\.offset) { i, label in")
            lines.append("\(pad)        Text(label).tag(i)")
            lines.append("\(pad)    }")
            lines.append("\(pad)}")
            lines.append("\(pad).pickerStyle(.segmented)")

        case .slider:
            let val = String(format: "%.2f", block.symbolScale)
            lines.append("\(pad)VStack(alignment: .leading, spacing: 8) {")
            if !block.content.isEmpty {
                lines.append("\(pad)    Text(\(quoted(block.content)))")
                lines.append("\(pad)        .font(.system(size: \(Int(block.fontSize)), design: .rounded))")
            }
            lines.append("\(pad)    Slider(value: .constant(\(val)), in: 0...1)")
            lines.append("\(pad)        .tint(\(colorLiteral(block.fillColor)))")
            lines.append("\(pad)}")

        case .avatar:
            let name = block.symbolName.isEmpty ? "person.fill" : block.symbolName
            let size = Int(64 * block.symbolScale)
            lines.append("\(pad)Circle()")
            lines.append("\(pad)    .fill(\(colorLiteral(block.fillColor)))")
            lines.append("\(pad)    .frame(width: \(size), height: \(size))")
            lines.append("\(pad)    .overlay(")
            lines.append("\(pad)        Image(systemName: \(quoted(name)))")
            lines.append("\(pad)            .font(.system(size: \(Int(Double(size) * 0.45)), weight: .medium))")
            lines.append("\(pad)            .foregroundColor(\(colorLiteral(block.textColor)))")
            lines.append("\(pad)    )")
            lines.append("\(pad)    .frame(maxWidth: .infinity, alignment: .\(block.alignment.rawValue))")

        case .badge:
            lines.append("\(pad)Text(\(quoted(block.content)))")
            lines.append("\(pad)    .font(.system(size: \(Int(block.fontSize)), weight: .\(block.fontWeight.rawValue), design: .rounded))")
            lines.append("\(pad)    .foregroundColor(\(colorLiteral(block.textColor)))")
            lines.append("\(pad)    .padding(.horizontal, \(Int(block.horizontalPadding)))")
            lines.append("\(pad)    .padding(.vertical, \(Int(block.verticalPadding)))")
            lines.append("\(pad)    .background(Capsule().fill(\(colorLiteral(block.fillColor))))")
            lines.append("\(pad)    .frame(maxWidth: .infinity, alignment: .\(block.alignment.rawValue))")

        case .searchBar:
            lines.append("\(pad)HStack(spacing: 8) {")
            lines.append("\(pad)    Image(systemName: \"magnifyingglass\").foregroundColor(.secondary)")
            lines.append("\(pad)    TextField(\(quoted(block.content)), text: .constant(\"\"))")
            lines.append("\(pad)        .font(.system(size: \(Int(block.fontSize)), design: .rounded))")
            lines.append("\(pad)}")
            lines.append("\(pad).padding(.horizontal, \(Int(block.horizontalPadding)))")
            lines.append("\(pad).padding(.vertical, \(Int(block.verticalPadding)))")
            lines.append("\(pad).background(RoundedRectangle(cornerRadius: \(Int(block.cornerRadius)), style: .continuous).fill(\(colorLiteral(block.fillColor))))")

        case .progressBar:
            let val = String(format: "%.2f", block.symbolScale)
            lines.append("\(pad)ProgressView(value: \(val))")
            lines.append("\(pad)    .tint(\(colorLiteral(block.fillColor)))")

        case .card:
            lines.append("\(pad)VStack(alignment: .leading, spacing: 8) {")
            if !block.symbolName.isEmpty {
                lines.append("\(pad)    Image(systemName: \(quoted(block.symbolName)))")
                lines.append("\(pad)        .font(.system(size: 24, weight: .medium))")
                lines.append("\(pad)        .foregroundColor(\(colorLiteral(block.textColor)).opacity(0.7))")
            }
            lines.append("\(pad)    Text(\(quoted(block.content)))")
            lines.append("\(pad)        .font(.system(size: \(Int(block.fontSize)), weight: .\(block.fontWeight.rawValue), design: .rounded))")
            lines.append("\(pad)        .foregroundColor(\(colorLiteral(block.textColor)))")
            if let sub = block.listItems.first, !sub.isEmpty {
                lines.append("\(pad)    Text(\(quoted(sub)))")
                lines.append("\(pad)        .font(.system(size: \(Int(block.fontSize) - 3), design: .rounded))")
                lines.append("\(pad)        .foregroundColor(\(colorLiteral(block.textColor)).opacity(0.6))")
            }
            lines.append("\(pad)}")
            lines.append("\(pad).frame(maxWidth: .infinity, alignment: .leading)")
            lines.append("\(pad).padding(.horizontal, \(Int(block.horizontalPadding)))")
            lines.append("\(pad).padding(.vertical, \(Int(block.verticalPadding)))")
            lines.append("\(pad).background(RoundedRectangle(cornerRadius: \(Int(block.cornerRadius)), style: .continuous).fill(\(colorLiteral(block.fillColor))))")
            lines.append("\(pad).shadow(color: .black.opacity(0.06), radius: 8, y: 4)")

        case .iconRow:
            let name = block.symbolName.isEmpty ? "circle" : block.symbolName
            lines.append("\(pad)HStack(spacing: 14) {")
            lines.append("\(pad)    Image(systemName: \(quoted(name)))")
            lines.append("\(pad)        .font(.system(size: 16, weight: .medium))")
            lines.append("\(pad)        .foregroundColor(.white)")
            lines.append("\(pad)        .frame(width: 32, height: 32)")
            lines.append("\(pad)        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(\(colorLiteral(block.fillColor))))")
            lines.append("\(pad)    Text(\(quoted(block.content)))")
            lines.append("\(pad)        .font(.system(size: \(Int(block.fontSize)), design: .rounded))")
            lines.append("\(pad)    Spacer()")
            if let value = block.listItems.first, !value.isEmpty {
                lines.append("\(pad)    Text(\(quoted(value)))")
                lines.append("\(pad)        .foregroundColor(.secondary)")
            }
            if block.symbolScale >= 0.5 {
                lines.append("\(pad)    Image(systemName: \"chevron.right\")")
                lines.append("\(pad)        .font(.system(size: 13, weight: .semibold))")
                lines.append("\(pad)        .foregroundColor(.secondary.opacity(0.4))")
            }
            lines.append("\(pad)}")
            lines.append("\(pad).padding(.horizontal, \(Int(block.horizontalPadding)))")
            lines.append("\(pad).padding(.vertical, \(Int(block.verticalPadding)))")

        case .mapPlaceholder:
            lines.append("\(pad)ZStack {")
            lines.append("\(pad)    RoundedRectangle(cornerRadius: \(Int(block.cornerRadius)), style: .continuous)")
            lines.append("\(pad)        .fill(\(colorLiteral(block.fillColor)))")
            lines.append("\(pad)    VStack(spacing: 8) {")
            lines.append("\(pad)        Image(systemName: \"mappin.and.ellipse\")")
            lines.append("\(pad)            .font(.system(size: 32, weight: .light))")
            lines.append("\(pad)            .foregroundColor(.secondary.opacity(0.5))")
            lines.append("\(pad)        Text(\"Map\")")
            lines.append("\(pad)            .font(.system(size: 13, weight: .medium, design: .rounded))")
            lines.append("\(pad)            .foregroundColor(.secondary.opacity(0.5))")
            lines.append("\(pad)    }")
            lines.append("\(pad)}")
            lines.append("\(pad).frame(maxWidth: .infinity)")
            lines.append("\(pad).frame(height: \(Int(180 * block.symbolScale)))")
        }

        return lines
    }

    // MARK: - Helpers

    private static func viewName(for screen: Screen) -> String {
        let cleaned = screen.name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.capitalized }
            .joined()
        let name = cleaned.isEmpty ? "Screen" : cleaned
        return name + "View"
    }

    private static func sanitize(_ name: String) -> String {
        let cleaned = name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.capitalized }
            .joined()
        return cleaned.isEmpty ? "MyApp" : cleaned
    }

    private static func quoted(_ s: String) -> String {
        let escaped = s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }

    private static func colorLiteral(_ color: Color) -> String {
        let c = color.toComponents()
        if c.alpha < 0.01 { return ".clear" }
        if c.red < 0.01 && c.green < 0.01 && c.blue < 0.01 && c.alpha > 0.99 { return ".black" }
        if c.red > 0.99 && c.green > 0.99 && c.blue > 0.99 && c.alpha > 0.99 { return ".white" }
        return String(format: "Color(red: %.2f, green: %.2f, blue: %.2f)", c.red, c.green, c.blue)
    }
}
