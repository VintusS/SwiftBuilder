//
//  InspectorView.swift
//  alpha
//

import SwiftUI

struct InspectorView: View {
    let binding: Binding<CanvasBlock>?
    let screens: [Screen]
    let onDuplicate: () -> Void
    let onReset: () -> Void
    let onDelete: () -> Void

    init(binding: Binding<CanvasBlock>?, screens: [Screen] = [],
         onDuplicate: @escaping () -> Void, onReset: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.binding = binding
        self.screens = screens
        self.onDuplicate = onDuplicate
        self.onReset = onReset
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(20)
            Divider()
            if let binding = binding {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        componentControls(binding: binding)
                        if screens.count > 1 {
                            sectionDivider
                            navigationControls(binding: binding)
                        }
                        sectionDivider
                        actionButtons
                    }
                    .padding(20)
                }
            } else {
                emptyState
                Spacer()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Inspector")
                .font(.title3.weight(.semibold))
            Text(binding?.wrappedValue.kind.displayName ?? "Select an element")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No selection")
                .font(.headline)
            Text("Tap a component in the outline or on the canvas.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }

    private var sectionDivider: some View {
        Divider().padding(.vertical, 16)
    }

    // MARK: - Per-Component Controls

    @ViewBuilder
    private func componentControls(binding: Binding<CanvasBlock>) -> some View {
        let kind = binding.wrappedValue.kind

        VStack(alignment: .leading, spacing: 14) {
            if kind != .spacer {
                compactSlider(value: binding.spacingBefore, range: 0...48, label: "Spacing Above")
            }

            switch kind {
            case .heroTitle:
                textField("Text", text: binding.content, axis: .vertical)
                alignmentPicker(binding: binding)
                fontSizeStepper(binding: binding, range: 16...44)
                fontWeightPicker(binding: binding)
                colorRow("Text Color", selection: binding.textColor)

            case .bodyText:
                textField("Text", text: binding.content, axis: .vertical)
                alignmentPicker(binding: binding)
                fontSizeStepper(binding: binding, range: 14...32)
                fontWeightPicker(binding: binding)
                colorRow("Text Color", selection: binding.textColor)

            case .caption:
                textField("Text", text: binding.content)
                alignmentPicker(binding: binding)
                fontSizeStepper(binding: binding, range: 10...18)
                colorRow("Text Color", selection: binding.textColor)

            case .badge:
                textField("Label", text: binding.content)
                alignmentPicker(binding: binding)
                fontSizeStepper(binding: binding, range: 10...18)
                colorRow("Label Color", selection: binding.textColor)
                colorRow("Background", selection: binding.fillColor)
                paddingSliders(binding: binding, hRange: 6...20, vRange: 2...12)
                compactSlider(value: binding.cornerRadius, range: 4...20, label: "Corner Radius")

            case .primaryButton:
                textField("Title", text: binding.content)
                fontSizeStepper(binding: binding, range: 14...26)
                fontWeightPicker(binding: binding, options: [.medium, .semibold, .bold])
                colorRow("Label Color", selection: binding.textColor)
                colorRow("Background", selection: binding.fillColor)
                paddingSliders(binding: binding, hRange: 8...32, vRange: 6...22)
                compactSlider(value: binding.cornerRadius, range: 4...30, label: "Corner Radius")

            case .secondaryButton:
                textField("Title", text: binding.content)
                fontSizeStepper(binding: binding, range: 14...26)
                fontWeightPicker(binding: binding, options: [.medium, .semibold, .bold])
                colorRow("Color", selection: binding.textColor)
                paddingSliders(binding: binding, hRange: 8...32, vRange: 6...22)
                compactSlider(value: binding.cornerRadius, range: 4...30, label: "Corner Radius")

            case .linkButton:
                textField("Title", text: binding.content)
                alignmentPicker(binding: binding)
                fontSizeStepper(binding: binding, range: 13...22)
                fontWeightPicker(binding: binding)
                colorRow("Color", selection: binding.textColor)

            case .textField:
                textField("Placeholder", text: binding.content)
                fontSizeStepper(binding: binding, range: 14...22)
                colorRow("Placeholder", selection: binding.textColor)
                colorRow("Background", selection: binding.fillColor)
                paddingSliders(binding: binding, hRange: 8...24, vRange: 6...18)
                compactSlider(value: binding.cornerRadius, range: 4...20, label: "Corner Radius")

            case .searchBar:
                textField("Placeholder", text: binding.content)
                fontSizeStepper(binding: binding, range: 14...20)
                colorRow("Placeholder", selection: binding.textColor)
                colorRow("Background", selection: binding.fillColor)
                paddingSliders(binding: binding, hRange: 8...24, vRange: 6...18)
                compactSlider(value: binding.cornerRadius, range: 4...20, label: "Corner Radius")

            case .toggle:
                textField("Label", text: binding.content)
                fontSizeStepper(binding: binding, range: 14...22)
                toggleStatePicker(binding: binding)
                colorRow("Label Color", selection: binding.textColor)
                colorRow("Tint", selection: binding.fillColor)

            case .slider:
                textField("Label", text: binding.content)
                compactSlider(value: binding.symbolScale, range: 0...1, label: "Value", format: "%.0f%%", multiplier: 100)
                colorRow("Label Color", selection: binding.textColor)
                colorRow("Tint", selection: binding.fillColor)

            case .segmentedControl:
                listItemsEditor(binding: binding, itemLabel: "Segment", maxItems: 5)
                HStack {
                    Text("Selected").font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Stepper(
                        "\(Int(binding.symbolScale.wrappedValue) + 1)",
                        value: binding.symbolScale,
                        in: 0...Double(max(binding.listItems.wrappedValue.count - 1, 0)),
                        step: 1
                    )
                    .frame(width: 120)
                }
                colorRow("Text Color", selection: binding.textColor)
                colorRow("Background", selection: binding.fillColor)
                compactSlider(value: binding.cornerRadius, range: 4...16, label: "Corner Radius")

            case .symbol:
                textField("SF Symbol", text: binding.symbolName)
                compactSlider(value: binding.symbolScale, range: 0.7...1.6, label: "Scale", format: "%.0f%%", multiplier: 100)
                colorRow("Color", selection: binding.fillColor)

            case .image:
                textField("SF Symbol", text: binding.symbolName)
                compactSlider(value: binding.symbolScale, range: 0.4...1.5, label: "Size", format: "%.0f%%", multiplier: 100)
                colorRow("Icon Color", selection: binding.textColor)
                colorRow("Background", selection: binding.fillColor)
                compactSlider(value: binding.cornerRadius, range: 0...24, label: "Corner Radius")

            case .avatar:
                textField("SF Symbol", text: binding.symbolName)
                compactSlider(value: binding.symbolScale, range: 0.5...2.0, label: "Size", format: "%.0f%%", multiplier: 100)
                alignmentPicker(binding: binding)
                colorRow("Icon Color", selection: binding.textColor)
                colorRow("Background", selection: binding.fillColor)

            case .mapPlaceholder:
                compactSlider(value: binding.symbolScale, range: 0.5...1.5, label: "Height", format: "%.0f%%", multiplier: 100)
                colorRow("Background", selection: binding.fillColor)
                compactSlider(value: binding.cornerRadius, range: 0...24, label: "Corner Radius")

            case .list:
                listItemsEditor(binding: binding)
                fontSizeStepper(binding: binding, range: 14...22)
                fontWeightPicker(binding: binding)
                colorRow("Text Color", selection: binding.textColor)
                colorRow("Background", selection: binding.fillColor)
                paddingSliders(binding: binding, hRange: 12...24, vRange: 8...20)
                compactSlider(value: binding.cornerRadius, range: 4...20, label: "Corner Radius")

            case .card:
                textField("Title", text: binding.content)
                subtitleField(binding: binding)
                textField("Icon (SF Symbol)", text: binding.symbolName)
                fontSizeStepper(binding: binding, range: 14...24)
                colorRow("Text Color", selection: binding.textColor)
                colorRow("Background", selection: binding.fillColor)
                paddingSliders(binding: binding, hRange: 12...24, vRange: 10...24)
                compactSlider(value: binding.cornerRadius, range: 4...24, label: "Corner Radius")

            case .iconRow:
                textField("Title", text: binding.content)
                valueField(binding: binding)
                textField("Icon (SF Symbol)", text: binding.symbolName)
                chevronToggle(binding: binding)
                colorRow("Icon Color", selection: binding.fillColor)
                colorRow("Text Color", selection: binding.textColor)
                compactSlider(value: binding.cornerRadius, range: 0...16, label: "Corner Radius")

            case .divider:
                colorRow("Color", selection: binding.fillColor)

            case .spacer:
                compactSlider(value: binding.spacingBefore, range: 8...120, label: "Height")

            case .progressBar:
                compactSlider(value: binding.symbolScale, range: 0...1, label: "Progress", format: "%.0f%%", multiplier: 100)
                colorRow("Tint", selection: binding.fillColor)
                compactSlider(value: binding.cornerRadius, range: 2...12, label: "Corner Radius")
            }
        }
    }

    // MARK: - Reusable Control Builders

    private func textField(_ label: String, text: Binding<String>, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.footnote).foregroundStyle(.secondary)
            TextField(label, text: text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .lineLimit(axis == .vertical ? 3 : 1)
        }
    }

    private func alignmentPicker(binding: Binding<CanvasBlock>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Alignment").font(.footnote).foregroundStyle(.secondary)
            Picker("Alignment", selection: binding.alignment) {
                ForEach(BlockAlignment.allCases) { a in
                    Image(systemName: a == .leading ? "text.alignleft" : a == .center ? "text.aligncenter" : "text.alignright")
                        .tag(a)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func fontSizeStepper(binding: Binding<CanvasBlock>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text("Size").font(.footnote).foregroundStyle(.secondary)
            Spacer()
            Stepper("\(Int(binding.fontSize.wrappedValue)) pt", value: binding.fontSize, in: range, step: 1)
                .frame(width: 140)
        }
    }

    private func fontWeightPicker(binding: Binding<CanvasBlock>, options: [FontWeightOption] = FontWeightOption.allCases) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Weight").font(.footnote).foregroundStyle(.secondary)
            Picker("Weight", selection: binding.fontWeight) {
                ForEach(options) { o in Text(o.label).tag(o) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func colorRow(_ label: String, selection: Binding<Color>) -> some View {
        ColorPicker(label, selection: selection)
            .font(.footnote)
    }

    private func compactSlider(value: Binding<Double>, range: ClosedRange<Double>, label: String, format: String? = nil, multiplier: Double = 1) -> some View {
        let span = range.upperBound - range.lowerBound
        let step: Double = span <= 1 ? 0.01 : 1

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.footnote).foregroundStyle(.secondary)
                Spacer()
                if let fmt = format {
                    Text(String(format: fmt, value.wrappedValue * multiplier))
                        .font(.footnote.monospacedDigit()).foregroundStyle(.secondary)
                } else {
                    Text("\(Int(value.wrappedValue)) pt")
                        .font(.footnote.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
            Slider(value: value, in: range, step: step)
                .tint(.accentColor)
        }
    }

    private func paddingSliders(binding: Binding<CanvasBlock>, hRange: ClosedRange<Double>, vRange: ClosedRange<Double>) -> some View {
        VStack(spacing: 6) {
            compactSlider(value: binding.horizontalPadding, range: hRange, label: "H Padding")
            compactSlider(value: binding.verticalPadding, range: vRange, label: "V Padding")
        }
    }

    private func toggleStatePicker(binding: Binding<CanvasBlock>) -> some View {
        HStack {
            Text("Initial State").font(.footnote).foregroundStyle(.secondary)
            Spacer()
            Picker("State", selection: Binding(
                get: { binding.symbolScale.wrappedValue >= 0.5 ? 1.0 : 0.0 },
                set: { binding.symbolScale.wrappedValue = $0 }
            )) {
                Text("Off").tag(0.0)
                Text("On").tag(1.0)
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
        }
    }

    private func subtitleField(binding: Binding<CanvasBlock>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Description").font(.footnote).foregroundStyle(.secondary)
            TextField("Description", text: Binding(
                get: { binding.listItems.wrappedValue.first ?? "" },
                set: { val in
                    if binding.listItems.wrappedValue.isEmpty {
                        binding.listItems.wrappedValue = [val]
                    } else {
                        binding.listItems.wrappedValue[0] = val
                    }
                }
            ), axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(3)
        }
    }

    private func valueField(binding: Binding<CanvasBlock>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Value / Detail").font(.footnote).foregroundStyle(.secondary)
            TextField("Value", text: Binding(
                get: { binding.listItems.wrappedValue.first ?? "" },
                set: { val in
                    if binding.listItems.wrappedValue.isEmpty {
                        binding.listItems.wrappedValue = [val]
                    } else {
                        binding.listItems.wrappedValue[0] = val
                    }
                }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }

    private func chevronToggle(binding: Binding<CanvasBlock>) -> some View {
        Toggle("Show Chevron", isOn: Binding(
            get: { binding.symbolScale.wrappedValue >= 0.5 },
            set: { binding.symbolScale.wrappedValue = $0 ? 1.0 : 0.0 }
        ))
        .font(.footnote)
    }

    private func listItemsEditor(binding: Binding<CanvasBlock>, itemLabel: String = "Item", maxItems: Int = 10) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(itemLabel)s").font(.footnote).foregroundStyle(.secondary)
            ForEach(Array(binding.listItems.enumerated()), id: \.offset) { index, _ in
                HStack(spacing: 6) {
                    TextField("\(itemLabel) \(index + 1)", text: Binding(
                        get: { binding.listItems.wrappedValue[safe: index] ?? "" },
                        set: { val in
                            var items = binding.listItems.wrappedValue
                            if index < items.count { items[index] = val }
                            binding.listItems.wrappedValue = items
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.footnote)
                    Button {
                        var items = binding.listItems.wrappedValue
                        items.remove(at: index)
                        binding.listItems.wrappedValue = items
                    } label: {
                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .disabled(binding.listItems.wrappedValue.count <= 1)
                }
            }
            Button {
                var items = binding.listItems.wrappedValue
                items.append("New \(itemLabel.lowercased())")
                binding.listItems.wrappedValue = items
            } label: {
                Label("Add \(itemLabel)", systemImage: "plus.circle")
                    .font(.footnote)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(binding.listItems.wrappedValue.count >= maxItems)
        }
    }

    // MARK: - Navigation

    private static let noNavigationID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    private func navigationControls(binding: Binding<CanvasBlock>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Navigation")
                .font(.footnote.weight(.semibold))
            Text("Tap to navigate to another screen.")
                .font(.caption2).foregroundStyle(.secondary)

            Picker("Destination", selection: Binding(
                get: { binding.navigationTarget.wrappedValue ?? Self.noNavigationID },
                set: { newValue in
                    binding.navigationTarget.wrappedValue = newValue == Self.noNavigationID ? nil : newValue
                }
            )) {
                Text("None").tag(Self.noNavigationID)
                ForEach(screens) { screen in
                    Text(screen.name).tag(screen.id)
                }
            }
            .labelsHidden()
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("Duplicate", action: onDuplicate)
            Button("Reset", action: onReset)
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .controlSize(.small)
        .buttonStyle(.bordered)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
