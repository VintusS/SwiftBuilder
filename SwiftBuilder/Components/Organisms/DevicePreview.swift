import SwiftUI
import SwiftBuilderComponents

struct DevicePreview: View {
    let device: DevicePreset
    let appearance: PreviewAppearance
    let blocks: [CanvasBlock]
    let selectedID: CanvasBlock.ID?
    let onSelect: (CanvasBlock.ID) -> Void

    private var frameColor: Color {
        appearance == .dark
            ? Color(red: 0.035, green: 0.025, blue: 0.025)
            : Color(red: 0.16, green: 0.11, blue: 0.11)
    }

    private var frameLightEdge: Color {
        appearance == .dark
            ? Color(red: 1.0, green: 0.06, blue: 0.04).opacity(0.28)
            : Color(red: 1.0, green: 0.18, blue: 0.13).opacity(0.40)
    }

    private var frameDarkEdge: Color {
        appearance == .dark
            ? Color.black.opacity(0.75)
            : Color(red: 0.35, green: 0.0, blue: 0.0).opacity(0.26)
    }

    private var screenBG: Color { appearance.canvasBackground }
    private var chromeColor: Color { appearance == .dark ? .white : .black }

    var body: some View {
        ZStack {
            deviceShadow
            deviceFrame
            screenArea
            chromeOverlays
            sideButtons
        }
        .frame(width: device.frameSize.width, height: device.frameSize.height)
    }

    // MARK: - Shadow

    private var deviceShadow: some View {
        RoundedRectangle(cornerRadius: device.frameCornerRadius, style: .continuous)
            .fill(Color(red: 0.65, green: 0.0, blue: 0.0).opacity(0.22))
            .frame(width: device.frameSize.width, height: device.frameSize.height)
            .blur(radius: 36)
            .offset(y: 18)
    }

    // MARK: - Frame

    private var deviceFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: device.frameCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            frameColor.opacity(0.95),
                            frameColor,
                            Color(red: 0.03, green: 0.02, blue: 0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: device.frameSize.width, height: device.frameSize.height)

            RoundedRectangle(cornerRadius: device.frameCornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [frameLightEdge, frameDarkEdge],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
                .frame(width: device.frameSize.width, height: device.frameSize.height)
        }
    }

    // MARK: - Screen Area

    private var screenArea: some View {
        RoundedRectangle(cornerRadius: device.screenCornerRadius, style: .continuous)
            .fill(screenBG)
            .frame(width: device.size.width, height: device.size.height)
            .overlay(screenContent)
            .clipShape(RoundedRectangle(cornerRadius: device.screenCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: device.screenCornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
            )
            .offset(y: (device.topBezel - device.bottomBezel) / 2)
    }

    @ViewBuilder
    private var screenContent: some View {
        if blocks.isEmpty {
            emptyCanvasState
        } else {
            let rows = BlockRow.group(blocks)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        if row.isGrouped {
                            HStack(spacing: 8) {
                                ForEach(row.blocks) { block in
                                    CanvasBlockView(
                                        block: block,
                                        appearance: appearance,
                                        isSelected: block.id == selectedID
                                    )
                                    .frame(maxWidth: .infinity)
                                    .id(block.id)
                                    .onTapGesture { onSelect(block.id) }
                                }
                            }
                            .padding(.top, CGFloat(row.blocks.first?.spacingBefore ?? 0))
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else if let block = row.blocks.first {
                            CanvasBlockView(
                                block: block,
                                appearance: appearance,
                                isSelected: block.id == selectedID
                            )
                            .padding(.top, CGFloat(block.spacingBefore))
                            .id(block.id)
                            .onTapGesture { onSelect(block.id) }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, device.safeAreaInsets.top)
                .padding(.bottom, device.safeAreaInsets.bottom)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: blocks.map(\.id))
            }
        }
    }

    // MARK: - Chrome Overlays

    @ViewBuilder
    private var chromeOverlays: some View {
        let screenOffset = (device.topBezel - device.bottomBezel) / 2

        ZStack {
            switch device.formFactor {
            case .dynamicIsland:
                dynamicIslandChrome
                    .offset(y: screenOffset)
                homeIndicator
                    .offset(y: screenOffset)

            case .homeButton:
                homeButtonChrome
                speakerGrille
                    .offset(y: -(device.size.height / 2 + device.topBezel / 2))

            case .iPad:
                homeIndicator
                    .offset(y: screenOffset)
            }
        }
    }

    // MARK: - Dynamic Island

    private var dynamicIslandChrome: some View {
        let diSize = device.dynamicIslandSize
        return Capsule()
            .fill(Color.black)
            .frame(width: diSize.width, height: diSize.height)
            .overlay(
                Capsule()
                    .fill(
                        RadialGradient(
                            colors: [Color.black, Color.black.opacity(0.9)],
                            center: .center,
                            startRadius: 0,
                            endRadius: diSize.width / 2
                        )
                    )
            )
            .overlay(
                HStack(spacing: diSize.width - 42) {
                    Circle()
                        .fill(Color(red: 0.08, green: 0.03, blue: 0.035))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .fill(Color(red: 0.25, green: 0.02, blue: 0.02).opacity(0.6))
                                .frame(width: 6, height: 6)
                        )
                    Circle()
                        .fill(Color(red: 0.05, green: 0.02, blue: 0.025))
                        .frame(width: 6, height: 6)
                }
            )
            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
            .offset(y: -(device.size.height / 2 - 17 - diSize.height / 2))
    }

    // MARK: - Home Indicator

    private var homeIndicator: some View {
        let indicatorWidth: CGFloat = device.formFactor == .iPad ? 160 : 134
        return Capsule()
            .fill(chromeColor.opacity(0.25))
            .frame(width: indicatorWidth, height: 5)
            .offset(y: device.size.height / 2 - 14)
    }

    // MARK: - Home Button (iPhone SE)

    private var homeButtonChrome: some View {
        let btnY = (device.size.height / 2 + device.bottomBezel / 2)
        let ringColor = appearance == .dark
            ? Color.white.opacity(0.12)
            : Color.white.opacity(0.25)

        return ZStack {
            Circle()
                .fill(frameColor.opacity(0.7))
                .frame(width: 50, height: 50)
            Circle()
                .stroke(ringColor, lineWidth: 2)
                .frame(width: 50, height: 50)
            RoundedRectangle(cornerRadius: 3)
                .fill(ringColor.opacity(0.5))
                .frame(width: 16, height: 16)
        }
        .offset(y: btnY)
    }

    // MARK: - Speaker Grille

    private var speakerGrille: some View {
        Capsule()
            .fill(Color.black.opacity(appearance == .dark ? 0.4 : 0.25))
            .frame(width: 36, height: 5)
    }

    // MARK: - Side Buttons

    @ViewBuilder
    private var sideButtons: some View {
        if device.formFactor != .iPad {
            let halfW = device.frameSize.width / 2
            let btnColor = frameColor.opacity(0.85)
            let screenOffset = (device.topBezel - device.bottomBezel) / 2

            RoundedRectangle(cornerRadius: 2)
                .fill(btnColor)
                .frame(width: 3, height: 60)
                .offset(x: halfW + 1.5, y: -40 + screenOffset)

            RoundedRectangle(cornerRadius: 2)
                .fill(btnColor)
                .frame(width: 3, height: 28)
                .offset(x: -(halfW + 1.5), y: -90 + screenOffset)

            RoundedRectangle(cornerRadius: 2)
                .fill(btnColor)
                .frame(width: 3, height: 50)
                .offset(x: -(halfW + 1.5), y: -30 + screenOffset)

            RoundedRectangle(cornerRadius: 2)
                .fill(btnColor)
                .frame(width: 3, height: 50)
                .offset(x: -(halfW + 1.5), y: 30 + screenOffset)
        }
    }

    // MARK: - Empty Canvas

    private var emptyCanvasState: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.rectangle.on.rectangle")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundColor(chromeColor.opacity(0.12))
            Text("Add components")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(chromeColor.opacity(0.20))
            Text("Use the Library panel to start building")
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(chromeColor.opacity(0.12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
