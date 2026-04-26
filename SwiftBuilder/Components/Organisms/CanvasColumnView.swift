//
//  CanvasColumnView.swift
//  SwiftBuilder
//

import SwiftUI
import SwiftBuilderComponents

struct CanvasColumnView: View {
    let theme: WorkspaceTheme
    let selectedDevice: DevicePreset
    let appearance: PreviewAppearance
    @Binding var zoomLevel: Double
    let blocks: [CanvasBlock]
    let selectedBlockID: CanvasBlock.ID?
    let screenName: String
    let onSelectBlock: (CanvasBlock.ID) -> Void

    @State private var viewportSize: CGSize = .zero

    private let canvasPadding: CGFloat = 96

    init(theme: WorkspaceTheme, selectedDevice: DevicePreset, appearance: PreviewAppearance,
         zoomLevel: Binding<Double>, blocks: [CanvasBlock], selectedBlockID: CanvasBlock.ID?,
         screenName: String = "Screen", onSelectBlock: @escaping (CanvasBlock.ID) -> Void) {
        self.theme = theme
        self.selectedDevice = selectedDevice
        self.appearance = appearance
        self._zoomLevel = zoomLevel
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var canvasHeader: some View {
        HStack(alignment: .top) {
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

            Spacer(minLength: Spacing.lg)

            HStack(spacing: Spacing.xs) {
                Button(action: fitPreviewToWindow) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .tint(theme.brandAccent)
                .disabled(!canFitPreview)
                .help("Fit preview to window")

                Button(action: resetPreviewZoom) {
                    Image(systemName: "1.magnifyingglass")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .tint(theme.brandAccent)
                .help("Reset preview to 100%")
            }
        }
    }

    private var canvasBody: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.panelBackground)
                    .shadow(color: theme.panelShadowColor, radius: 18, x: 0, y: 24)

                ZoomablePreviewScrollView(
                    zoom: $zoomLevel,
                    contentSize: previewContentSize,
                    minZoom: PreviewZoom.minimum,
                    maxZoom: PreviewZoom.maximum
                ) {
                    DevicePreview(
                        device: selectedDevice,
                        appearance: appearance,
                        blocks: blocks,
                        selectedID: selectedBlockID,
                        onSelect: { id in
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                onSelectBlock(id)
                            }
                        }
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .onAppear { viewportSize = proxy.size }
            .onChange(of: proxy.size) { _, newSize in
                viewportSize = newSize
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var previewContentSize: CGSize {
        CGSize(
            width: selectedDevice.frameSize.width + canvasPadding * 2,
            height: selectedDevice.frameSize.height + canvasPadding * 2
        )
    }

    private var canFitPreview: Bool {
        viewportSize.width > 0 && viewportSize.height > 0
    }

    private func fitPreviewToWindow() {
        guard canFitPreview else { return }
        let horizontalFit = Double(viewportSize.width / previewContentSize.width)
        let verticalFit = Double(viewportSize.height / previewContentSize.height)
        zoomLevel = PreviewZoom.clamped(min(horizontalFit, verticalFit))
    }

    private func resetPreviewZoom() {
        zoomLevel = PreviewZoom.reset
    }
}
