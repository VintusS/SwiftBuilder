//
//  WorkspaceToolbar.swift
//  alpha
//

import SwiftUI

struct WorkspaceToolbar: View {
    @Binding var projectName: String
    @Binding var selectedDevice: DevicePreset
    @Binding var appearance: PreviewAppearance
    @Binding var zoomLevel: Double
    @Binding var isBuilding: Bool
    @Binding var alertInfo: AlertInfo?
    
    let onReset: () -> Void
    let onSave: () -> Void
    let onShowRunGuide: () -> Void
    let onLaunchSimulator: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SwiftUI Builder · alpha v2")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text("Test a lightweight workflow: add, tweak and preview a single screen.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 24)
            
            TextField("Project Name", text: $projectName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
            
            Picker("Device", selection: $selectedDevice) {
                ForEach(DevicePreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 160)
            
            Picker("Appearance", selection: $appearance) {
                ForEach(PreviewAppearance.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            
            HStack(spacing: 10) {
                Image(systemName: "rectangle.and.magnifyingglass")
                    .foregroundStyle(.secondary)
                Slider(value: $zoomLevel, in: 0.65...1.35)
                    .frame(width: 120)
                Text("\(Int(zoomLevel * 100))%")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(width: 46, alignment: .leading)
            }
            
            Divider()
                .frame(height: 28)
            
            Button("Reset Canvas") {
                onReset()
            }
            .buttonStyle(.bordered)
            
            Button {
                onSave()
            } label: {
                Label("Save Project", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            
            Button {
                onShowRunGuide()
            } label: {
                Label("Run Preview Guide", systemImage: "play.rectangle.on.rectangle")
            }
            .buttonStyle(.bordered)
            
            Button {
                onLaunchSimulator()
            } label: {
                if isBuilding {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else {
                    Label("Run on Simulator", systemImage: "iphone")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBuilding)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .alert(item: $alertInfo) { info in
            Alert(title: Text(info.title), message: Text(info.message), dismissButton: .default(Text("OK")))
        }
    }
}

