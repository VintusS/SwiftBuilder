//
//  InspectorView.swift
//  alpha
//

import SwiftUI

struct InspectorView: View {
    let binding: Binding<CanvasBlock>?
    let onDuplicate: () -> Void
    let onReset: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Inspector")
                    .font(.title3.weight(.semibold))
                Text(selectedBlockTitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            if let binding = binding {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        componentSummary(binding: binding)
                        contentControls(binding: binding)
                        layoutControls(binding: binding)
                        styleControls(binding: binding)
                        actionButtons
                    }
                    .padding(20)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select a component")
                        .font(.headline)
                    Text("Choose an item in the outline or tap directly on the preview.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                Spacer()
            }
        }
    }
    
    private var selectedBlockTitle: String {
        binding?.wrappedValue.kind.displayName ?? "Tap an element to begin"
    }
    
    // MARK: - Inspector Sections
    
    private func componentSummary(binding: Binding<CanvasBlock>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(binding.wrappedValue.kind.displayName)
                .font(.headline)
            Text(binding.wrappedValue.kind.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    private func contentControls(binding: Binding<CanvasBlock>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content")
                .font(.subheadline.weight(.semibold))
            
            switch binding.wrappedValue.kind {
            case .heroTitle, .bodyText:
                TextField("Text", text: binding.content, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3)
                Picker("Alignment", selection: binding.alignment) {
                    ForEach(BlockAlignment.allCases) { alignment in
                        Text(alignment.title).tag(alignment)
                    }
                }
                .pickerStyle(.segmented)
                Stepper(value: binding.fontSize, in: 16...44, step: 1) {
                    Text("Font size \(Int(binding.fontSize.wrappedValue)) pt")
                }
                Picker("Weight", selection: binding.fontWeight) {
                    ForEach(FontWeightOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            case .primaryButton:
                TextField("Button Title", text: binding.content)
                    .textFieldStyle(.roundedBorder)
                Stepper(value: binding.fontSize, in: 14...26, step: 1) {
                    Text("Font size \(Int(binding.fontSize.wrappedValue)) pt")
                }
                Picker("Weight", selection: binding.fontWeight) {
                    ForEach([FontWeightOption.medium, .semibold, .bold]) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            case .symbol:
                TextField("SF Symbol", text: binding.symbolName)
                    .textFieldStyle(.roundedBorder)
                Slider(value: binding.symbolScale, in: 0.7...1.6) {
                    Text("Scale")
                }
                .tint(.accentColor)
                LabeledContent("Scale") {
                    Text(String(format: "%.0f%%", binding.symbolScale.wrappedValue * 100))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            case .list:
                VStack(alignment: .leading, spacing: 8) {
                    Text("List Items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(Array(binding.listItems.enumerated()), id: \.offset) { index, _ in
                        HStack {
                            TextField("Item \(index + 1)", text: Binding(
                                get: { binding.listItems.wrappedValue[safe: index] ?? "" },
                                set: { newValue in
                                    var items = binding.listItems.wrappedValue
                                    if index < items.count {
                                        items[index] = newValue
                                    }
                                    binding.listItems.wrappedValue = items
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                            Button {
                                var items = binding.listItems.wrappedValue
                                items.remove(at: index)
                                binding.listItems.wrappedValue = items
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                            .disabled(binding.listItems.wrappedValue.count <= 1)
                        }
                    }
                    Button {
                        var items = binding.listItems.wrappedValue
                        items.append("New item")
                        binding.listItems.wrappedValue = items
                    } label: {
                        Label("Add Item", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                    .disabled(binding.listItems.wrappedValue.count >= 10)
                }
                Stepper(value: binding.fontSize, in: 14...22, step: 1) {
                    Text("Font size \(Int(binding.fontSize.wrappedValue)) pt")
                }
                Picker("Weight", selection: binding.fontWeight) {
                    ForEach(FontWeightOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private func layoutControls(binding: Binding<CanvasBlock>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Layout")
                .font(.subheadline.weight(.semibold))
            
            Slider(value: binding.spacingBefore, in: 0...48, step: 1) {
                Text("Spacing above")
            }
            .tint(.accentColor)
            LabeledContent("Spacing above") {
                Text(String(format: "%.0f pt", binding.spacingBefore.wrappedValue))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            if binding.wrappedValue.kind == .primaryButton {
                Slider(value: binding.horizontalPadding, in: 12...32, step: 1) {
                    Text("Horizontal padding")
                }
                .tint(.accentColor)
                Slider(value: binding.verticalPadding, in: 10...26, step: 1) {
                    Text("Vertical padding")
                }
                .tint(.accentColor)
                Slider(value: binding.cornerRadius, in: 12...30, step: 1) {
                    Text("Corner radius")
                }
                .tint(.accentColor)
            }
            
            if binding.wrappedValue.kind == .list {
                Slider(value: binding.horizontalPadding, in: 12...24, step: 1) {
                    Text("Horizontal padding")
                }
                .tint(.accentColor)
                Slider(value: binding.verticalPadding, in: 8...20, step: 1) {
                    Text("Vertical padding")
                }
                .tint(.accentColor)
                Slider(value: binding.cornerRadius, in: 8...20, step: 1) {
                    Text("Corner radius")
                }
                .tint(.accentColor)
            }
        }
    }
    
    private func styleControls(binding: Binding<CanvasBlock>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Style")
                .font(.subheadline.weight(.semibold))
            
            switch binding.wrappedValue.kind {
            case .heroTitle, .bodyText:
                ColorPicker("Text Color", selection: binding.textColor)
            case .primaryButton:
                ColorPicker("Background", selection: binding.fillColor)
                ColorPicker("Label Color", selection: binding.textColor)
            case .symbol:
                ColorPicker("Symbol Color", selection: binding.fillColor, supportsOpacity: true)
            case .list:
                ColorPicker("Text Color", selection: binding.textColor)
                ColorPicker("Background", selection: binding.fillColor)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            HStack {
                Button("Duplicate") {
                    onDuplicate()
                }
                Button("Reset") {
                    onReset()
                }
                Spacer()
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

