import SwiftUI
import SwiftBuilderComponents

struct WorkspaceToolbar: View {
    let theme: WorkspaceTheme

    @Binding var projectName: String
    @Binding var selectedDevice: DevicePreset
    @Binding var appearance: PreviewAppearance
    @Binding var zoomLevel: Double
    @Binding var isBuilding: Bool
    @Binding var alertInfo: AlertInfo?
    @Binding var runTarget: RunTarget
    let availablePhysicalDevices: [PhysicalDevice]
    @Binding var selectedPhysicalDeviceID: String?
    let isRefreshingPhysicalDevices: Bool
    let physicalDeviceStatusMessage: String?

    let onReset: () -> Void
    let onSave: () -> Void
    let onExportCode: () -> Void
    let onShowRunGuide: () -> Void
    let onRefreshPhysicalDevices: () -> Void
    let onLaunchPreview: () -> Void

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
        .background(theme.toolbarBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.brandAccent.opacity(0.22))
                .frame(height: 1)
        }
        .alert(item: $alertInfo) { info in
            Alert(title: Text(info.title), message: Text(info.message), dismissButton: .default(Text("OK")))
        }
    }

    private var leftZone: some View {
        HStack(spacing: Spacing.md) {
            Text("SwiftBuilder")
                .font(TypographyPreset.toolbarTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.brandAccentHighlight, theme.brandAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            PillDivider()

            TextField("Project Name", text: $projectName)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.elevatedBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(theme.outlineStrokeColor, lineWidth: 1)
                        )
                )
                .frame(width: 160)
        }
    }

    private var centerZone: some View {
        HStack(spacing: Spacing.md) {
            Picker("Device", selection: $selectedDevice) {
                ForEach(DevicePreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 180)
            .tint(theme.brandAccent)

            Picker("Appearance", selection: $appearance) {
                ForEach(PreviewAppearance.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .tint(theme.brandAccent)

            PillDivider()

            HStack(spacing: 6) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Slider(value: $zoomLevel, in: 0.65...1.35)
                    .frame(width: 80)
                    .tint(theme.brandAccent)
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
            .tint(theme.brandAccent)
            .help("Save Project")

            Button(action: onExportCode) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 32, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .tint(theme.brandAccent)
            .help("Export SwiftUI Code")

            runTargetControls

            Button(action: onLaunchPreview) {
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
            .tint(theme.brandAccent)
            .disabled(isBuilding || !canRunSelectedTarget)
            .help(runTarget.runButtonHelp)
        }
    }

    private var runTargetControls: some View {
        HStack(spacing: 6) {
            Menu {
                ForEach(RunTarget.allCases) { target in
                    Button {
                        runTarget = target
                    } label: {
                        Label(target.title, systemImage: target == runTarget ? "checkmark" : target.systemImage)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: runTarget.systemImage)
                        .font(.system(size: 12, weight: .semibold))
                    Text(runTarget.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 9)
                .frame(width: 118, height: 28)
                .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .help("Choose where PreviewRunner should launch")

            if runTarget == .physicalDevice {
                physicalDeviceMenu

                Button(action: onRefreshPhysicalDevices) {
                    if isRefreshingPhysicalDevices {
                        ProgressView()
                            .scaleEffect(0.55)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 14, height: 14)
                    }
                }
                .buttonStyle(.bordered)
                .tint(theme.brandAccent)
                .frame(width: 32, height: 28)
                .disabled(isRefreshingPhysicalDevices)
                .help("Refresh connected iPhones")
            }
        }
    }

    private var physicalDeviceMenu: some View {
        Menu {
            if availablePhysicalDevices.isEmpty {
                Button {
                    onRefreshPhysicalDevices()
                } label: {
                    Label("No iPhone Found", systemImage: "exclamationmark.triangle")
                }
            } else {
                ForEach(availablePhysicalDevices) { device in
                    Button {
                        selectedPhysicalDeviceID = device.id
                    } label: {
                        Label(
                            device.displayName,
                            systemImage: device.id == selectedPhysicalDeviceID ? "checkmark" : "iphone"
                        )
                    }
                    .disabled(!device.isAvailable)
                }

                Divider()

                Button(action: onRefreshPhysicalDevices) {
                    Label("Refresh Devices", systemImage: "arrow.clockwise")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedPhysicalDevice?.isAvailable == false ? "exclamationmark.triangle" : "iphone")
                    .font(.system(size: 12, weight: .semibold))
                Text(selectedPhysicalDevice?.displayName ?? "No iPhone")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 9)
            .frame(width: 164, height: 28)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .help(physicalDeviceStatusMessage ?? "Select a connected, trusted iPhone")
    }

    private var selectedPhysicalDevice: PhysicalDevice? {
        guard let selectedPhysicalDeviceID else { return nil }
        return availablePhysicalDevices.first { $0.id == selectedPhysicalDeviceID }
    }

    private var canRunSelectedTarget: Bool {
        switch runTarget {
        case .simulator:
            return true
        case .physicalDevice:
            return selectedPhysicalDevice?.isAvailable == true
        }
    }
}
