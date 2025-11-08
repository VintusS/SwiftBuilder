import SwiftUI

struct DevicePreview: View {
    let device: DevicePreset
    let appearance: PreviewAppearance
    let zoom: Double
    let blocks: [CanvasBlock]
    let selectedID: CanvasBlock.ID?
    let onSelect: (CanvasBlock.ID) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: device.cornerRadius + 42, style: .continuous)
                .fill(appearance.deviceShellColor)
                .shadow(color: Color.black.opacity(0.26), radius: 32, x: 0, y: 24)
            RoundedRectangle(cornerRadius: device.cornerRadius + 18, style: .continuous)
                .fill(appearance.bezelHighlight)
                .frame(width: device.size.width + 54, height: device.size.height + 54)
            RoundedRectangle(cornerRadius: device.cornerRadius + 6, style: .continuous)
                .fill(appearance.deviceInnerRim)
                .frame(width: device.size.width + 18, height: device.size.height + 18)
            RoundedRectangle(cornerRadius: device.cornerRadius, style: .continuous)
                .fill(appearance.canvasBackground)
                .frame(width: device.size.width, height: device.size.height)
                .overlay(screenContent)
                .clipShape(RoundedRectangle(cornerRadius: device.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: device.cornerRadius, style: .continuous)
                        .stroke(appearance.screenStroke, lineWidth: 1)
                )
        }
        .scaleEffect(zoom)
        .animation(.easeOut(duration: 0.2), value: zoom)
    }

    private var screenContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(blocks) { block in
                CanvasBlockView(
                    block: block,
                    appearance: appearance,
                    isSelected: block.id == selectedID
                )
                .padding(.top, CGFloat(block.spacingBefore))
                .onTapGesture {
                    onSelect(block.id)
                }
            }
            Spacer(minLength: 16)
        }
        .padding(.horizontal, 24)
        .padding(.top, device.safeAreaInsets.top)
        .padding(.bottom, device.safeAreaInsets.bottom)
    }
}

struct CanvasBlockView: View {
    let block: CanvasBlock
    let appearance: PreviewAppearance
    let isSelected: Bool
    var onButtonTap: (() -> Void)? = nil
    
    var body: some View {
        SelectionOutline(isActive: isSelected, cornerRadius: block.selectionCornerRadius) {
            buildContent()
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func buildContent() -> some View {
        switch block.kind {
        case .heroTitle:
            let titleColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            Text(block.content)
                .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                .foregroundColor(titleColor)
                .multilineTextAlignment(block.alignment.textAlignment)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)
        case .bodyText:
            let bodyColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.68)
            Text(block.content)
                .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                .foregroundColor(bodyColor.opacity(appearance == .dark ? 0.92 : 1))
                .lineSpacing(4)
                .multilineTextAlignment(block.alignment.textAlignment)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)
        case .primaryButton:
            let labelColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.82)
            Button(action: {
                onButtonTap?()
            }) {
                Text(block.content)
                    .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                    .foregroundColor(labelColor)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, CGFloat(block.horizontalPadding))
                    .padding(.vertical, CGFloat(block.verticalPadding))
                    .background(
                        RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                            .fill(block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.32))
                            .shadow(color: block.fillColor.opacity(0.24), radius: 10, x: 0, y: 8)
                    )
            }
            .buttonStyle(.plain)
        case .symbol:
            let symbolColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.6)
            Image(systemName: block.symbolName.isEmpty ? "sparkles" : block.symbolName)
                .font(.system(size: 80 * block.symbolScale, weight: .light))
                .foregroundColor(symbolColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
        case .list:
            let itemColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.95)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(block.listItems.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(itemColor.opacity(0.6))
                        Text(item)
                            .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                            .foregroundColor(itemColor)
                        Spacer()
                    }
                    .padding(.horizontal, CGFloat(block.horizontalPadding))
                    .padding(.vertical, CGFloat(block.verticalPadding))
                    if index < block.listItems.count - 1 {
                        Divider()
                            .padding(.leading, CGFloat(block.horizontalPadding + 18))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .stroke(itemColor.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct SelectionOutline<Content: View>: View {
    let isActive: Bool
    let cornerRadius: CGFloat
    let content: Content

    init(isActive: Bool, cornerRadius: CGFloat, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: isActive ? 2 : 0)
            )
            .animation(.easeInOut(duration: 0.18), value: isActive)
    }
}
