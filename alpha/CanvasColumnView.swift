//
//  CanvasColumnView.swift
//  alpha
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
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label(screenName, systemImage: "iphone")
                    .font(.title3.weight(.semibold))
                Text("\(selectedDevice.displayName) \u{00B7} \(appearance.title)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
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
        .padding(24)
    }
}

