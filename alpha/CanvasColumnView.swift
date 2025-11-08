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
    let onSelectBlock: (CanvasBlock.ID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Screen Preview", systemImage: "iphone")
                    .font(.title3.weight(.semibold))
                Text("Preview updates for \(selectedDevice.displayName) in \(appearance.title.lowercased()) mode.")
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

