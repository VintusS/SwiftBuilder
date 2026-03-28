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
    let onExportCode: () -> Void
    let onShowRunGuide: () -> Void
    let onLaunchSimulator: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            leftZone
            Spacer(minLength: Spacing.lg)
            centerZone
            Spacer(minLength: Spacing.lg)
            rightZone
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .alert(item: $alertInfo) { info in
            Alert(title: Text(info.title), message: Text(info.message), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Left Zone: Identity + Project Name

    private var leftZone: some View {
        HStack(spacing: Spacing.md) {
            Text("alpha")
                .font(TypographyPreset.toolbarTitle)
                .foregroundStyle(.primary)

            PillDivider()

            TextField("Project Name", text: $projectName)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                )
                .frame(width: 160)
        }
    }

    // MARK: - Center Zone: Preview Controls

    private var centerZone: some View {
        HStack(spacing: Spacing.md) {
            Picker("Device", selection: $selectedDevice) {
                ForEach(DevicePreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)

            Picker("Appearance", selection: $appearance) {
                ForEach(PreviewAppearance.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            PillDivider()

            HStack(spacing: 6) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Slider(value: $zoomLevel, in: 0.65...1.35)
                    .frame(width: 80)
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("\(Int(zoomLevel * 100))%")
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 34, alignment: .trailing)
            }
        }
    }

    // MARK: - Right Zone: Actions

    private var rightZone: some View {
        HStack(spacing: Spacing.sm) {
            Menu {
                Button(action: onReset) {
                    Label("Reset Canvas", systemImage: "arrow.counterclockwise")
                }
                Button(action: onShowRunGuide) {
                    Label("Run Preview Guide", systemImage: "book")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 32, height: 28)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .frame(width: 32)
            .help("More actions")

            PillDivider()

            Button(action: onSave) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 32, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .help("Save Project")

            Button(action: onExportCode) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 32, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .help("Export SwiftUI Code")

            Button(action: onLaunchSimulator) {
                HStack(spacing: 6) {
                    if isBuilding {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .bold))
                    }
                    Text("Run")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .frame(height: 28)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBuilding)
            .help("Build & Run on Simulator")
        }
    }
}

// MARK: - Toolbar Pill Divider

private struct PillDivider: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.primary.opacity(0.12))
            .frame(width: 1, height: 20)
    }
}
