import SwiftUI

struct CanvasBlockView: View {
    let block: CanvasBlock
    let appearance: PreviewAppearance
    let isSelected: Bool
    var isInteractive: Bool = false
    var onButtonTap: (() -> Void)? = nil

    @State private var isHovered = false
    @State private var textFieldValue: String = ""
    @State private var searchFieldValue: String = ""
    @State private var toggleIsOn: Bool = false
    @State private var selectedSegment: Int = 0
    @State private var sliderValue: Double = 0.5

    var body: some View {
        SelectionOutline(isActive: isSelected, isHovered: isHovered) {
            buildContent()
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder
    private func buildContent() -> some View {
        let rendered = buildRawContent()
            .opacity(block.opacity)

        let hasInternalBorder: Bool = {
            switch block.kind {
            case .divider, .spacer, .secondaryButton, .textField, .card, .avatar, .list:
                return true
            default:
                return false
            }
        }()

        if block.borderWidth > 0 && !hasInternalBorder {
            rendered.overlay(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .stroke(block.textColor.opacity(0.5), lineWidth: CGFloat(block.borderWidth))
            )
        } else {
            rendered
        }
    }

    @ViewBuilder
    private func buildRawContent() -> some View {
        switch block.kind {
        case .heroTitle:
            let titleColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            Text(block.content)
                .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                .foregroundColor(titleColor)
                .lineSpacing(CGFloat(block.lineSpacing))
                .multilineTextAlignment(block.alignment.textAlignment)
                .padding(.horizontal, CGFloat(block.horizontalPadding))
                .padding(.vertical, max(4, CGFloat(block.verticalPadding)))
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)
                .background {
                    if block.fillColor != .clear {
                        RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                            .fill(block.fillColor)
                    }
                }
                .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.12 : 0), radius: CGFloat(block.shadowRadius), x: 0, y: CGFloat(block.shadowRadius / 2))
        case .bodyText:
            let bodyColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.68)
            Text(block.content)
                .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                .foregroundColor(bodyColor.opacity(appearance == .dark ? 0.92 : 1))
                .lineSpacing(CGFloat(block.lineSpacing))
                .multilineTextAlignment(block.alignment.textAlignment)
                .padding(.horizontal, CGFloat(block.horizontalPadding))
                .padding(.vertical, max(4, CGFloat(block.verticalPadding)))
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)
                .background {
                    if block.fillColor != .clear {
                        RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                            .fill(block.fillColor)
                    }
                }
                .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.12 : 0), radius: CGFloat(block.shadowRadius), x: 0, y: CGFloat(block.shadowRadius / 2))
        case .caption:
            let captionColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.55)
            Text(block.content)
                .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                .foregroundColor(captionColor)
                .lineSpacing(CGFloat(block.lineSpacing))
                .multilineTextAlignment(block.alignment.textAlignment)
                .padding(.horizontal, CGFloat(block.horizontalPadding))
                .padding(.vertical, CGFloat(block.verticalPadding))
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)
                .background {
                    if block.fillColor != .clear {
                        RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                            .fill(block.fillColor)
                    }
                }

        case .primaryButton:
            let labelColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.82)
            let bgFill = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.32)
            let buttonVisual = HStack(spacing: 8) {
                if !block.symbolName.isEmpty {
                    Image(systemName: block.symbolName)
                        .font(.system(size: CGFloat(block.fontSize) - 2, weight: block.fontWeight.weight))
                }
                Text(block.content)
                    .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
            }
                .foregroundColor(labelColor)
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)
                .padding(.horizontal, CGFloat(block.horizontalPadding))
                .padding(.vertical, CGFloat(block.verticalPadding))
                .background(
                    RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                        .fill(bgFill)
                        .shadow(color: block.fillColor.opacity(block.shadowRadius > 0 ? 0.24 : 0.24), radius: max(CGFloat(block.shadowRadius), 10), x: 0, y: max(CGFloat(block.shadowRadius * 0.8), 8))
                )
            if let tap = onButtonTap {
                Button(action: tap) { buttonVisual }.buttonStyle(.plain)
            } else {
                buttonVisual
            }

        case .secondaryButton:
            let borderColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.5)
            let strokeW = block.borderWidth > 0 ? CGFloat(block.borderWidth) : 1.5
            let buttonVisual = HStack(spacing: 8) {
                if !block.symbolName.isEmpty {
                    Image(systemName: block.symbolName)
                        .font(.system(size: CGFloat(block.fontSize) - 2, weight: block.fontWeight.weight))
                }
                Text(block.content)
                    .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
            }
                .foregroundColor(borderColor)
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)
                .padding(.horizontal, CGFloat(block.horizontalPadding))
                .padding(.vertical, CGFloat(block.verticalPadding))
                .background(
                    RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                        .stroke(borderColor, lineWidth: strokeW)
                )
                .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.08 : 0), radius: CGFloat(block.shadowRadius), x: 0, y: CGFloat(block.shadowRadius / 2))
            if let tap = onButtonTap {
                Button(action: tap) { buttonVisual }.buttonStyle(.plain)
            } else {
                buttonVisual
            }

        case .linkButton:
            let linkColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.5)
            let linkVisual = HStack(spacing: 6) {
                if !block.symbolName.isEmpty {
                    Image(systemName: block.symbolName)
                        .font(.system(size: CGFloat(block.fontSize) - 2, weight: block.fontWeight.weight))
                }
                Text(block.content)
                    .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
            }
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
                .font(.system(size: 80 * block.symbolScale, weight: block.fontWeight.weight))
                .foregroundColor(symbolColor)
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)
                .padding(.vertical, 26)
                .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.15 : 0), radius: CGFloat(block.shadowRadius), x: 0, y: CGFloat(block.shadowRadius / 2))

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
            .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.08 : 0), radius: CGFloat(block.shadowRadius), x: 0, y: CGFloat(block.shadowRadius / 2))

        case .image:
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.85)
            ZStack {
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
                Image(systemName: block.symbolName.isEmpty ? "photo.fill" : block.symbolName)
                    .font(.system(size: 40 * block.symbolScale, weight: block.fontWeight.weight))
                    .foregroundColor(block.textColor.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)
            .frame(height: 160 * block.symbolScale)
            .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.1 : 0), radius: CGFloat(block.shadowRadius), x: 0, y: CGFloat(block.shadowRadius / 2))

        case .textField:
            let placeholderColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.55)
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.88)
            HStack {
                if isInteractive {
                    TextField(block.content, text: $textFieldValue)
                        .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                        .foregroundColor(.primary)
                        #if os(iOS)
                        .textFieldStyle(.plain)
                        #endif
                } else {
                    Text(block.content)
                        .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                        .foregroundColor(placeholderColor)
                    Spacer()
                }
            }
            .padding(.horizontal, CGFloat(block.horizontalPadding))
            .padding(.vertical, CGFloat(block.verticalPadding))
            .background(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: max(1, CGFloat(block.borderWidth)))
            )
            .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.08 : 0), radius: CGFloat(block.shadowRadius), x: 0, y: CGFloat(block.shadowRadius / 2))

        case .toggle:
            let labelColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            let tintColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.4)
            if isInteractive {
                Toggle(isOn: $toggleIsOn) {
                    Text(block.content)
                        .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                        .foregroundColor(labelColor)
                }
                .toggleStyle(.switch)
                .tint(tintColor)
                .frame(maxWidth: .infinity)
                .onAppear { toggleIsOn = block.symbolScale >= 0.5 }
            } else {
                let isOn = block.symbolScale >= 0.5
                Toggle(isOn: .constant(isOn)) {
                    Text(block.content)
                        .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                        .foregroundColor(labelColor)
                }
                .toggleStyle(.switch)
                .tint(tintColor)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
            }

        case .divider:
            let divColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.6)
            Rectangle()
                .fill(divColor)
                .frame(height: max(1, CGFloat(block.borderWidth > 0 ? block.borderWidth : 1)))
                .padding(.horizontal, CGFloat(block.horizontalPadding))
                .frame(maxWidth: .infinity)

        case .spacer:
            Color.clear
                .frame(height: max(CGFloat(block.spacingBefore), 8))

        case .segmentedControl:
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.88)
            let textColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            let activeIdx = isInteractive ? selectedSegment : max(0, min(Int(block.symbolScale), block.listItems.count - 1))
            HStack(spacing: 0) {
                ForEach(Array(block.listItems.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.system(size: CGFloat(block.fontSize), weight: index == activeIdx ? .semibold : block.fontWeight.weight, design: .rounded))
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, CGFloat(max(block.verticalPadding, 8)))
                        .background(
                            RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius) - 1, style: .continuous)
                                .fill(index == activeIdx ? Color.white : Color.clear)
                                .shadow(color: index == activeIdx ? .black.opacity(0.08) : .clear, radius: 2, y: 1)
                        )
                        .padding(2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isInteractive {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedSegment = index
                                }
                            }
                        }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
            )
            .onAppear {
                selectedSegment = max(0, min(Int(block.symbolScale), block.listItems.count - 1))
            }

        case .slider:
            let labelColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            let tintColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.4)
            if isInteractive {
                VStack(alignment: .leading, spacing: 8) {
                    if !block.content.isEmpty {
                        HStack {
                            Text(block.content)
                                .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                                .foregroundColor(labelColor)
                            Spacer()
                            Text("\(Int(sliderValue * 100))%")
                                .font(.system(size: CGFloat(block.fontSize) - 2, design: .rounded))
                                .foregroundColor(labelColor.opacity(0.6))
                        }
                    }
                    Slider(value: $sliderValue, in: 0...1)
                        .tint(tintColor)
                }
                .onAppear { sliderValue = min(max(block.symbolScale, 0), 1) }
            } else {
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
                    .frame(height: max(6, CGFloat(block.verticalPadding > 0 ? block.verticalPadding : 6)))
                    .clipShape(Capsule())
                }
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
                .overlay(
                    block.borderWidth > 0
                        ? Circle().stroke(block.textColor.opacity(0.3), lineWidth: CGFloat(block.borderWidth))
                        : nil
                )
                .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.15 : 0), radius: CGFloat(block.shadowRadius), x: 0, y: CGFloat(block.shadowRadius / 2))
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
                .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.12 : 0), radius: CGFloat(block.shadowRadius), x: 0, y: CGFloat(block.shadowRadius / 2))
                .frame(maxWidth: .infinity, alignment: block.alignment.frameAlignment)

        case .searchBar:
            let placeholderColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.55)
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.88)
            HStack(spacing: 8) {
                Image(systemName: block.symbolName.isEmpty ? "magnifyingglass" : block.symbolName)
                    .foregroundColor(placeholderColor)
                    .font(.system(size: CGFloat(block.fontSize) - 1))
                if isInteractive {
                    TextField(block.content, text: $searchFieldValue)
                        .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                        .foregroundColor(.primary)
                        #if os(iOS)
                        .textFieldStyle(.plain)
                        #endif
                } else {
                    Text(block.content)
                        .font(.system(size: CGFloat(block.fontSize), weight: block.fontWeight.weight, design: .rounded))
                        .foregroundColor(placeholderColor)
                    Spacer()
                }
            }
            .padding(.horizontal, CGFloat(block.horizontalPadding))
            .padding(.vertical, CGFloat(block.verticalPadding))
            .background(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
            )
            .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.08 : 0), radius: CGFloat(block.shadowRadius), x: 0, y: CGFloat(block.shadowRadius / 2))

        case .progressBar:
            let tintColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.4)
            let progress = min(max(block.symbolScale, 0), 1)
            let barHeight = max(4, CGFloat(block.verticalPadding > 0 ? block.verticalPadding : 8))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                        .fill(tintColor)
                        .frame(width: max(geo.size.width * progress, 4))
                }
            }
            .frame(height: barHeight)

        case .card:
            let titleColor = block.textColor.ensuringContrast(in: appearance, minimumLuminance: 0.75)
            let bgColor = block.fillColor.ensuringContrast(in: appearance, minimumLuminance: 0.9)
            let shadowR = block.shadowRadius > 0 ? CGFloat(block.shadowRadius) : 8
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
                        .lineSpacing(CGFloat(block.lineSpacing))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, CGFloat(block.horizontalPadding))
            .padding(.vertical, CGFloat(block.verticalPadding))
            .background(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .fill(bgColor)
                    .shadow(color: .black.opacity(0.06), radius: shadowR, x: 0, y: shadowR / 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(block.cornerRadius), style: .continuous)
                    .stroke(titleColor.opacity(0.06), lineWidth: max(1, CGFloat(block.borderWidth)))
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
                    .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.06 : 0.04), radius: max(4, CGFloat(block.shadowRadius)), x: 0, y: 2)
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
            .shadow(color: .black.opacity(block.shadowRadius > 0 ? 0.1 : 0), radius: CGFloat(block.shadowRadius), x: 0, y: CGFloat(block.shadowRadius / 2))
        }
    }
}
