//
//  InspectorView.swift
//  SwiftBuilder
//

import SwiftUI
import SwiftBuilderComponents

struct InspectorView: View {
    let binding: Binding<CanvasBlock>?
    let screens: [Screen]
    let onDuplicate: () -> Void
    let onReset: () -> Void
    let onDelete: () -> Void

    @State private var expandedSections: Set<InspectorSection> = [.content, .typography, .colors, .layout, .style]

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
                .padding(Spacing.xl)
            Divider()
            if let binding = binding {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        contentSection(binding: binding)
                        typographySection(binding: binding)
                        colorsSection(binding: binding)
                        layoutSection(binding: binding)
                        styleSection(binding: binding)
                        if screens.count > 1 {
                            navigationSection(binding: binding)
                        }
                        actionButtons
                            .padding(.top, Spacing.lg)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.bottom, Spacing.xl)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                emptyState
                Spacer()
            }
        }
        .clipped()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Inspector")
                    .font(TypographyPreset.panelTitle)
                if let kind = binding?.wrappedValue.kind {
                    HStack(spacing: 6) {
                        Image(systemName: kind.iconSystemName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(kind.paletteColor)
                        Text(kind.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(kind.paletteColor.opacity(0.12))
                    )
                } else {
                    Text("Select an element")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "cursorarrow.click.2")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.quaternary)
            VStack(spacing: Spacing.xs) {
                Text("No selection")
                    .font(.system(size: 13, weight: .semibold))
                Text("Tap a component on the canvas or in the outline.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Collapsible Sections

    private func contentSection(binding: Binding<CanvasBlock>) -> some View {
        let kind = binding.wrappedValue.kind
        let hasContent = kind != .divider && kind != .spacer && kind != .progressBar
        return Group {
            if hasContent {
                collapsibleSection(.content) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        contentControls(binding: binding, kind: kind)
                    }
                }
            }
        }
    }

    private func typographySection(binding: Binding<CanvasBlock>) -> some View {
        let kind = binding.wrappedValue.kind
        let hasTypography: Bool = {
            switch kind {
            case .heroTitle, .bodyText, .caption, .badge,
                 .primaryButton, .secondaryButton, .linkButton,
                 .textField, .searchBar, .toggle, .slider,
                 .list, .card, .iconRow, .segmentedControl,
                 .symbol, .image, .avatar:
                return true
            default:
                return false
            }
        }()
        return Group {
            if hasTypography {
                collapsibleSection(.typography) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        typographyControls(binding: binding, kind: kind)
                    }
                }
            }
        }
    }

    private func colorsSection(binding: Binding<CanvasBlock>) -> some View {
        let kind = binding.wrappedValue.kind
        let hasColors = kind != .spacer
        return Group {
            if hasColors {
                collapsibleSection(.colors) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        colorControls(binding: binding, kind: kind)
                    }
                }
            }
        }
    }

    private func layoutSection(binding: Binding<CanvasBlock>) -> some View {
        collapsibleSection(.layout) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                layoutControls(binding: binding, kind: binding.wrappedValue.kind)
            }
        }
    }

    private func styleSection(binding: Binding<CanvasBlock>) -> some View {
        let kind = binding.wrappedValue.kind
        let hasStyle = kind != .spacer
        return Group {
            if hasStyle {
                collapsibleSection(.style) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        styleControls(binding: binding, kind: kind)
                    }
                }
            }
        }
    }

    private func navigationSection(binding: Binding<CanvasBlock>) -> some View {
        collapsibleSection(.navigation) {
            navigationControls(binding: binding)
        }
    }

    // MARK: - Content Controls (per kind)

    @ViewBuilder
    private func contentControls(binding: Binding<CanvasBlock>, kind: CanvasBlock.Kind) -> some View {
        switch kind {
        case .heroTitle, .bodyText:
            textField("Text", text: binding.content, axis: .vertical)
        case .caption:
            textField("Text", text: binding.content)
        case .badge:
            textField("Label", text: binding.content)
        case .primaryButton, .secondaryButton:
            textField("Title", text: binding.content)
            textField("Icon (SF Symbol)", text: binding.symbolName)
        case .linkButton:
            textField("Title", text: binding.content)
            textField("Icon (SF Symbol)", text: binding.symbolName)
        case .textField:
            textField("Placeholder", text: binding.content)
        case .searchBar:
            textField("Placeholder", text: binding.content)
            textField("Icon (SF Symbol)", text: binding.symbolName)
        case .toggle:
            textField("Label", text: binding.content)
            toggleStatePicker(binding: binding)
        case .slider:
            textField("Label", text: binding.content)
            compactSlider(value: binding.symbolScale, range: 0...1, label: "Value", format: "%.0f%%", multiplier: 100)
        case .segmentedControl:
            listItemsEditor(binding: binding, itemLabel: "Segment", maxItems: 5)
            HStack {
                Text("Selected").font(TypographyPreset.controlLabel).foregroundStyle(.secondary)
                Spacer()
                Stepper(
                    "\(Int(binding.symbolScale.wrappedValue) + 1)",
                    value: binding.symbolScale,
                    in: 0...Double(max(binding.listItems.wrappedValue.count - 1, 0)),
                    step: 1
                )
                .frame(maxWidth: 120)
            }
        case .symbol:
            textField("SF Symbol", text: binding.symbolName)
            compactSlider(value: binding.symbolScale, range: 0.4...2.0, label: "Scale", format: "%.0f%%", multiplier: 100)
        case .image:
            textField("SF Symbol", text: binding.symbolName)
            compactSlider(value: binding.symbolScale, range: 0.4...2.0, label: "Size", format: "%.0f%%", multiplier: 100)
        case .avatar:
            textField("SF Symbol", text: binding.symbolName)
            compactSlider(value: binding.symbolScale, range: 0.5...3.0, label: "Size", format: "%.0f%%", multiplier: 100)
        case .mapPlaceholder:
            compactSlider(value: binding.symbolScale, range: 0.5...2.0, label: "Height", format: "%.0f%%", multiplier: 100)
        case .list:
            listItemsEditor(binding: binding)
        case .card:
            textField("Title", text: binding.content)
            subtitleField(binding: binding)
            textField("Icon (SF Symbol)", text: binding.symbolName)
        case .iconRow:
            textField("Title", text: binding.content)
            valueField(binding: binding)
            textField("Icon (SF Symbol)", text: binding.symbolName)
            chevronToggle(binding: binding)
        case .progressBar:
            compactSlider(value: binding.symbolScale, range: 0...1, label: "Progress", format: "%.0f%%", multiplier: 100)
        default:
            EmptyView()
        }
    }

    // MARK: - Typography Controls

    @ViewBuilder
    private func typographyControls(binding: Binding<CanvasBlock>, kind: CanvasBlock.Kind) -> some View {
        switch kind {
        case .heroTitle:
            fontSizeStepper(binding: binding, range: 16...60)
            fontWeightPicker(binding: binding)
            alignmentPicker(binding: binding)
            compactSlider(value: binding.lineSpacing, range: 0...20, label: "Line Spacing")
        case .bodyText:
            fontSizeStepper(binding: binding, range: 12...36)
            fontWeightPicker(binding: binding)
            alignmentPicker(binding: binding)
            compactSlider(value: binding.lineSpacing, range: 0...20, label: "Line Spacing")
        case .caption:
            fontSizeStepper(binding: binding, range: 8...22)
            fontWeightPicker(binding: binding)
            alignmentPicker(binding: binding)
            compactSlider(value: binding.lineSpacing, range: 0...12, label: "Line Spacing")
        case .badge:
            fontSizeStepper(binding: binding, range: 8...22)
            fontWeightPicker(binding: binding)
            alignmentPicker(binding: binding)
        case .primaryButton, .secondaryButton:
            fontSizeStepper(binding: binding, range: 12...30)
            fontWeightPicker(binding: binding, options: [.medium, .semibold, .bold])
            alignmentPicker(binding: binding)
        case .linkButton:
            fontSizeStepper(binding: binding, range: 11...26)
            fontWeightPicker(binding: binding)
            alignmentPicker(binding: binding)
        case .textField:
            fontSizeStepper(binding: binding, range: 12...26)
            fontWeightPicker(binding: binding)
        case .searchBar:
            fontSizeStepper(binding: binding, range: 12...26)
            fontWeightPicker(binding: binding)
        case .toggle:
            fontSizeStepper(binding: binding, range: 12...26)
            fontWeightPicker(binding: binding)
        case .slider:
            fontSizeStepper(binding: binding, range: 12...24)
            fontWeightPicker(binding: binding)
        case .list:
            fontSizeStepper(binding: binding, range: 12...26)
            fontWeightPicker(binding: binding)
        case .card:
            fontSizeStepper(binding: binding, range: 12...28)
            fontWeightPicker(binding: binding)
            compactSlider(value: binding.lineSpacing, range: 0...12, label: "Line Spacing")
        case .iconRow:
            fontSizeStepper(binding: binding, range: 12...24)
            fontWeightPicker(binding: binding)
        case .segmentedControl:
            fontSizeStepper(binding: binding, range: 11...20)
            fontWeightPicker(binding: binding)
        case .symbol:
            fontWeightPicker(binding: binding)
        case .image:
            fontWeightPicker(binding: binding)
        case .avatar:
            fontWeightPicker(binding: binding)
        default:
            EmptyView()
        }
    }

    // MARK: - Color Controls

    @ViewBuilder
    private func colorControls(binding: Binding<CanvasBlock>, kind: CanvasBlock.Kind) -> some View {
        switch kind {
        case .heroTitle, .bodyText, .caption:
            colorRow("Text Color", selection: binding.textColor)
            colorRow("Background", selection: binding.fillColor)
        case .badge:
            colorRow("Label Color", selection: binding.textColor)
            colorRow("Background", selection: binding.fillColor)
        case .primaryButton:
            colorRow("Label Color", selection: binding.textColor)
            colorRow("Background", selection: binding.fillColor)
        case .secondaryButton:
            colorRow("Label / Border", selection: binding.textColor)
            colorRow("Background", selection: binding.fillColor)
        case .linkButton:
            colorRow("Color", selection: binding.textColor)
        case .textField, .searchBar:
            colorRow("Placeholder", selection: binding.textColor)
            colorRow("Background", selection: binding.fillColor)
        case .toggle:
            colorRow("Label Color", selection: binding.textColor)
            colorRow("Tint", selection: binding.fillColor)
        case .slider:
            colorRow("Label Color", selection: binding.textColor)
            colorRow("Tint", selection: binding.fillColor)
        case .segmentedControl:
            colorRow("Text Color", selection: binding.textColor)
            colorRow("Background", selection: binding.fillColor)
        case .symbol:
            colorRow("Color", selection: binding.fillColor)
        case .image:
            colorRow("Icon Color", selection: binding.textColor)
            colorRow("Background", selection: binding.fillColor)
        case .avatar:
            colorRow("Icon Color", selection: binding.textColor)
            colorRow("Background", selection: binding.fillColor)
        case .mapPlaceholder:
            colorRow("Background", selection: binding.fillColor)
        case .list:
            colorRow("Text Color", selection: binding.textColor)
            colorRow("Background", selection: binding.fillColor)
        case .card:
            colorRow("Text Color", selection: binding.textColor)
            colorRow("Background", selection: binding.fillColor)
        case .iconRow:
            colorRow("Icon Color", selection: binding.fillColor)
            colorRow("Text Color", selection: binding.textColor)
        case .divider:
            colorRow("Color", selection: binding.fillColor)
        case .progressBar:
            colorRow("Tint", selection: binding.fillColor)
        default:
            EmptyView()
        }
    }

    // MARK: - Layout Controls

    @ViewBuilder
    private func layoutControls(binding: Binding<CanvasBlock>, kind: CanvasBlock.Kind) -> some View {
        if kind == .spacer {
            compactSlider(value: binding.spacingBefore, range: 4...200, label: "Height")
        } else {
            compactSlider(value: binding.spacingBefore, range: 0...60, label: "Spacing Above")

            switch kind {
            case .heroTitle, .bodyText, .caption:
                paddingSliders(binding: binding, hRange: 0...32, vRange: 0...24)
                compactSlider(value: binding.cornerRadius, range: 0...24, label: "Corner Radius")
            case .badge:
                paddingSliders(binding: binding, hRange: 4...28, vRange: 2...16)
                compactSlider(value: binding.cornerRadius, range: 4...24, label: "Corner Radius")
            case .primaryButton, .secondaryButton:
                paddingSliders(binding: binding, hRange: 4...40, vRange: 4...28)
                compactSlider(value: binding.cornerRadius, range: 0...40, label: "Corner Radius")
            case .linkButton:
                paddingSliders(binding: binding, hRange: 0...24, vRange: 0...16)
            case .textField, .searchBar:
                paddingSliders(binding: binding, hRange: 6...32, vRange: 4...24)
                compactSlider(value: binding.cornerRadius, range: 0...28, label: "Corner Radius")
            case .toggle:
                paddingSliders(binding: binding, hRange: 0...24, vRange: 0...16)
            case .slider:
                paddingSliders(binding: binding, hRange: 0...24, vRange: 0...16)
                Text("V Padding also controls track height")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            case .segmentedControl:
                paddingSliders(binding: binding, hRange: 0...16, vRange: 4...20)
                compactSlider(value: binding.cornerRadius, range: 4...20, label: "Corner Radius")
            case .symbol:
                alignmentPicker(binding: binding)
            case .image:
                compactSlider(value: binding.cornerRadius, range: 0...40, label: "Corner Radius")
                alignmentPicker(binding: binding)
            case .avatar:
                alignmentPicker(binding: binding)
            case .mapPlaceholder:
                compactSlider(value: binding.cornerRadius, range: 0...32, label: "Corner Radius")
            case .list:
                paddingSliders(binding: binding, hRange: 8...32, vRange: 6...24)
                compactSlider(value: binding.cornerRadius, range: 0...28, label: "Corner Radius")
            case .card:
                paddingSliders(binding: binding, hRange: 8...32, vRange: 6...32)
                compactSlider(value: binding.cornerRadius, range: 0...32, label: "Corner Radius")
            case .iconRow:
                paddingSliders(binding: binding, hRange: 8...32, vRange: 6...24)
                compactSlider(value: binding.cornerRadius, range: 0...24, label: "Corner Radius")
            case .divider:
                compactSlider(value: binding.borderWidth, range: 0...6, label: "Thickness")
                paddingSliders(binding: binding, hRange: 0...60, vRange: 0...0)
            case .progressBar:
                compactSlider(value: binding.verticalPadding, range: 4...24, label: "Bar Height")
                compactSlider(value: binding.cornerRadius, range: 0...16, label: "Corner Radius")
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Style & Effects Controls

    @ViewBuilder
    private func styleControls(binding: Binding<CanvasBlock>, kind: CanvasBlock.Kind) -> some View {
        compactSlider(value: binding.opacity, range: 0.05...1, label: "Opacity", format: "%.0f%%", multiplier: 100)

        let supportsShadow: Bool = {
            switch kind {
            case .heroTitle, .bodyText, .primaryButton, .secondaryButton,
                 .badge, .card, .iconRow, .image, .avatar,
                 .list, .textField, .searchBar, .mapPlaceholder, .symbol:
                return true
            default:
                return false
            }
        }()

        if supportsShadow {
            compactSlider(value: binding.shadowRadius, range: 0...30, label: "Shadow")
        }

        let supportsBorder: Bool = {
            switch kind {
            case .heroTitle, .bodyText, .caption, .badge,
                 .primaryButton, .secondaryButton,
                 .card, .iconRow, .image, .avatar,
                 .list, .textField, .searchBar, .mapPlaceholder:
                return true
            default:
                return false
            }
        }()

        if supportsBorder {
            compactSlider(value: binding.borderWidth, range: 0...6, label: "Border Width")
        }
    }

    // MARK: - Collapsible Section Wrapper

    private func collapsibleSection<Content: View>(_ section: InspectorSection, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedSections.contains(section) {
                        expandedSections.remove(section)
                    } else {
                        expandedSections.insert(section)
                    }
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: section.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Text(section.title)
                        .font(TypographyPreset.sectionHeader)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(expandedSections.contains(section) ? 90 : 0))
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expandedSections.contains(section) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    content()
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.lg)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Reusable Control Builders

    private func textField(_ label: String, text: Binding<String>, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label).font(TypographyPreset.controlLabel).foregroundStyle(.secondary)
            TextField(label, text: text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .lineLimit(axis == .vertical ? 3 : 1)
        }
    }

    private func alignmentPicker(binding: Binding<CanvasBlock>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Alignment").font(TypographyPreset.controlLabel).foregroundStyle(.secondary)
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
            Text("Size").font(TypographyPreset.controlLabel).foregroundStyle(.secondary)
            Spacer()
            Stepper("\(Int(binding.fontSize.wrappedValue)) pt", value: binding.fontSize, in: range, step: 1)
                .frame(maxWidth: 130)
        }
    }

    private func fontWeightPicker(binding: Binding<CanvasBlock>, options: [FontWeightOption] = FontWeightOption.allCases) -> some View {
        HStack {
            Text("Weight").font(TypographyPreset.controlLabel).foregroundStyle(.secondary)
            Spacer()
            Picker("Weight", selection: binding.fontWeight) {
                ForEach(options) { o in Text(o.label).tag(o) }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 140)
        }
    }

    private func colorRow(_ label: String, selection: Binding<Color>) -> some View {
        ColorPicker(label, selection: selection)
            .font(TypographyPreset.controlLabel)
    }

    private func compactSlider(value: Binding<Double>, range: ClosedRange<Double>, label: String, format: String? = nil, multiplier: Double = 1) -> some View {
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(label).font(TypographyPreset.controlLabel).foregroundStyle(.secondary)
                Spacer()
                if let fmt = format {
                    Text(String(format: fmt, value.wrappedValue * multiplier))
                        .font(TypographyPreset.controlValue).foregroundStyle(.secondary)
                } else {
                    Text("\(Int(value.wrappedValue)) pt")
                        .font(TypographyPreset.controlValue).foregroundStyle(.secondary)
                }
            }
            Slider(value: value, in: range)
                .tint(.accentColor)
        }
    }

    private func paddingSliders(binding: Binding<CanvasBlock>, hRange: ClosedRange<Double>, vRange: ClosedRange<Double>) -> some View {
        VStack(spacing: 6) {
            compactSlider(value: binding.horizontalPadding, range: hRange, label: "H Padding")
            if vRange.lowerBound != vRange.upperBound {
                compactSlider(value: binding.verticalPadding, range: vRange, label: "V Padding")
            }
        }
    }

    private func toggleStatePicker(binding: Binding<CanvasBlock>) -> some View {
        HStack {
            Text("Initial State").font(TypographyPreset.controlLabel).foregroundStyle(.secondary)
            Spacer()
            Picker("State", selection: Binding(
                get: { binding.symbolScale.wrappedValue >= 0.5 ? 1.0 : 0.0 },
                set: { binding.symbolScale.wrappedValue = $0 }
            )) {
                Text("Off").tag(0.0)
                Text("On").tag(1.0)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 120)
        }
    }

    private func subtitleField(binding: Binding<CanvasBlock>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Description").font(TypographyPreset.controlLabel).foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Value / Detail").font(TypographyPreset.controlLabel).foregroundStyle(.secondary)
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
        .font(TypographyPreset.controlLabel)
    }

    private func listItemsEditor(binding: Binding<CanvasBlock>, itemLabel: String = "Item", maxItems: Int = 10) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("\(itemLabel)s").font(TypographyPreset.controlLabel).foregroundStyle(.secondary)
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
                    .font(.system(size: 12))
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
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(binding.listItems.wrappedValue.count >= maxItems)
        }
    }

    // MARK: - Navigation

    private static let noNavigationID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    private func navigationControls(binding: Binding<CanvasBlock>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tap to navigate to another screen.")
                .font(.system(size: 11)).foregroundStyle(.secondary)

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
        HStack(spacing: Spacing.sm) {
            Button(action: onDuplicate) {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            Button(action: onReset) {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .controlSize(.small)
        .buttonStyle(.bordered)
        .font(.system(size: 11))
    }
}

// MARK: - Inspector Section

private enum InspectorSection: String, Hashable {
    case content, typography, colors, layout, style, navigation

    var title: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .content: return "text.cursor"
        case .typography: return "textformat.size"
        case .colors: return "paintpalette"
        case .layout: return "ruler"
        case .style: return "sparkles.rectangle.stack"
        case .navigation: return "arrow.right.circle"
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
