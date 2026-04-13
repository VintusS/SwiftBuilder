//
//  CanvasColumnView.swift
//  SwiftBuilder
//

import SwiftUI

struct CanvasColumnView: View {
    let theme: WorkspaceTheme
    let selectedDevice: DevicePreset
    let appearance: PreviewAppearance
    let zoomLevel: Double
    let blocks: [CanvasBlock]
    let selectedBlockID: CanvasBlock.ID?
    let screenName: String
    let onSelectBlock: (CanvasBlock.ID) -> Void

    init(theme: WorkspaceTheme, selectedDevice: DevicePreset, appearance: PreviewAppearance,
         zoomLevel: Double, blocks: [CanvasBlock], selectedBlockID: CanvasBlock.ID?,
         screenName: String = "Screen", onSelectBlock: @escaping (CanvasBlock.ID) -> Void) {
        self.theme = theme
        self.selectedDevice = selectedDevice
        self.appearance = appearance
        self.zoomLevel = zoomLevel
        self.blocks = blocks
        self.selectedBlockID = selectedBlockID
        self.screenName = screenName
        self.onSelectBlock = onSelectBlock
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            canvasHeader
            canvasBody
        }
        .padding(Spacing.xxl)
    }

    private var canvasHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label(screenName, systemImage: selectedDevice.formFactor == .iPad ? "ipad" : "iphone")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            HStack(spacing: 6) {
                Text(selectedDevice.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Circle()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 3, height: 3)
                Text(appearance.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Circle()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 3, height: 3)
                Text("\(blocks.count) component\(blocks.count == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var canvasBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.panelBackground)
                .shadow(color: theme.panelShadowColor, radius: 18, x: 0, y: 24)
            ScrollView([.vertical, .horizontal]) {
                DevicePreview(
                    device: selectedDevice,
                    appearance: appearance,
                    zoom: zoomLevel,
                    blocks: blocks,
                    selectedID: selectedBlockID,
                    onSelect: { id in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            onSelectBlock(id)
                        }
                    }
                )
                .padding(70)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}
