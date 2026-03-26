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
        case .caption:
            let captionColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.55)
            Text(block.content)
                .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                .foregroundColor(captionColor)
                .multilineTextAlignment(block.alignment.textAlignment)
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)

        case .primaryButton:
            let labelColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.82)
            let buttonVisual = Text(block.content)
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
            if let tap = onButtonTap {
                Button(action: tap) { buttonVisual }.buttonStyle(.plain)
            } else {
                buttonVisual
            }

        case .secondaryButton:
            let borderColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.5)
            let buttonVisual = Text(block.content)
                .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                .foregroundColor(borderColor)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, CGFloat(block.horizontalPadding))
                .padding(.vertical, CGFloat(block.verticalPadding))
                .background(
                    RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                        .stroke(borderColor, lineWidth: 1.5)
                )
            if let tap = onButtonTap {
                Button(action: tap) { buttonVisual }.buttonStyle(.plain)
            } else {
                buttonVisual
            }

        case .linkButton:
            let linkColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.5)
            let linkVisual = Text(block.content)
                .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                .foregroundColor(linkColor)
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)
            if let tap = onButtonTap {
                Button(action: tap) { linkVisual }.buttonStyle(.plain)
            } else {
                linkVisual
            }

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

        case .image:
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.85)
            ZStack {
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
                Image(systemName: block.symbolName.isEmpty ? "photo.fill" : block.symbolName)
                    .font(.system(size: 40 * block.symbolScale, weight: .light))
                    .foregroundColor(block.textColor.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160 * block.symbolScale)

        case .textField:
            let placeholderColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.55)
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.88)
            HStack {
                Text(block.content)
                    .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                    .foregroundColor(placeholderColor)
                Spacer()
            }
            .padding(.horizontal, CGFloat(block.horizontalPadding))
            .padding(.vertical, CGFloat(block.verticalPadding))
            .background(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )

        case .toggle:
            let labelColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            let tintColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.4)
            HStack {
                Text(block.content)
                    .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                    .foregroundColor(labelColor)
                Spacer()
                let isOn = block.symbolScale >= 0.5
                Capsule()
                    .fill(isOn ? tintColor : Color.secondary.opacity(0.3))
                    .frame(width: 51, height: 31)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 27, height: 27)
                            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                            .offset(x: isOn ? 10 : -10),
                        alignment: isOn ? .trailing : .leading
                    )
            }

        case .divider:
            let divColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.6)
            Rectangle()
                .fill(divColor)
                .frame(height: 1)
                .frame(maxWidth: .infinity)

        case .spacer:
            Color.clear
                .frame(height: max(CGFloat(block.spacingBefore), 8))

        case .segmentedControl:
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.88)
            let textColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            let selectedIdx = max(0, min(Int(block.symbolScale), block.listItems.count - 1))
            HStack(spacing: 0) {
                ForEach(Array(block.listItems.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.system(size: CGFloat(block.fontSize), weight: index == selectedIdx ? .semibold : block.fontWeight.weight, design: .rounded))
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius) - 1, style: .continuous)
                                .fill(index == selectedIdx ? Color.white : Color.clear)
                                .shadow(color: index == selectedIdx ? .black.opacity(0.08) : .clear, radius: 2, y: 1)
                        )
                        .padding(2)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
            )

        case .slider:
            let labelColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            let tintColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.4)
            let progress = min(max(block.symbolScale, 0), 1)
            VStack(alignment: .leading, spacing: 8) {
                if !block.content.isEmpty {
                    HStack {
                        Text(block.content)
                            .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                            .foregroundColor(labelColor)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: CGFloat(block.fontSize) - 2, design: .rounded))
                            .foregroundColor(labelColor.opacity(0.6))
                    }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.2))
                        Capsule().fill(tintColor)
                            .frame(width: max(geo.size.width * progress, 6))
                    }
                }
                .frame(height: 6)
                .clipShape(Capsule())
            }

        case .avatar:
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.4)
            let iconColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.8)
            let size: CGFloat = 64 * block.symbolScale
            Circle()
                .fill(bgColor)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: block.symbolName.isEmpty ? "person.fill" : block.symbolName)
                        .font(.system(size: size * 0.45, weight: .medium))
                        .foregroundColor(iconColor)
                )
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)

        case .badge:
            let labelColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.85)
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.35)
            Text(block.content)
                .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                .foregroundColor(labelColor)
                .padding(.horizontal, CGFloat(block.horizontalPadding))
                .padding(.vertical, CGFloat(block.verticalPadding))
                .background(
                    Capsule().fill(bgColor)
                )
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)

        case .searchBar:
            let placeholderColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.55)
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.88)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(placeholderColor)
                    .font(.system(size: CGFloat(block.fontSize) - 1))
                Text(block.content)
                    .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                    .foregroundColor(placeholderColor)
                Spacer()
            }
            .padding(.horizontal, CGFloat(block.horizontalPadding))
            .padding(.vertical, CGFloat(block.verticalPadding))
            .background(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
            )

        case .progressBar:
            let tintColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.4)
            let progress = min(max(block.symbolScale, 0), 1)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                        .fill(tintColor)
                        .frame(width: max(geo.size.width * progress, 4))
                }
            }
            .frame(height: 8)

        case .card:
            let titleColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.9)
            VStack(alignment: .leading, spacing: 8) {
                if !block.symbolName.isEmpty {
                    Image(systemName: block.symbolName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(titleColor.opacity(0.7))
                }
                Text(block.content)
                    .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                    .foregroundColor(titleColor)
                if let subtitle = block.listItems.first, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: max(CGFloat(block.fontSize) - 3, 12), design: .rounded))
                        .foregroundColor(titleColor.opacity(0.6))
                        .lineSpacing(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, CGFloat(block.horizontalPadding))
            .padding(.vertical, CGFloat(block.verticalPadding))
            .background(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .stroke(titleColor.opacity(0.06), lineWidth: 1)
            )

        case .iconRow:
            let titleColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            let iconBg = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.4)
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconBg)
                        .frame(width: 32, height: 32)
                    Image(systemName: block.symbolName.isEmpty ? "circle" : block.symbolName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                Text(block.content)
                    .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                    .foregroundColor(titleColor)
                Spacer()
                if let value = block.listItems.first, !value.isEmpty {
                    Text(value)
                        .font(.system(size: max(CGFloat(block.fontSize) - 1, 12), design: .rounded))
                        .foregroundColor(titleColor.opacity(0.45))
                }
                if block.symbolScale >= 0.5 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(titleColor.opacity(0.25))
                }
            }
            .padding(.horizontal, CGFloat(block.horizontalPadding))
            .padding(.vertical, CGFloat(block.verticalPadding))
            .background(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(appearance == .dark ? Color.white.opacity(0.06) : Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            )

        case .mapPlaceholder:
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.8)
            ZStack {
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
                VStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Map")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180 * block.symbolScale)
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
