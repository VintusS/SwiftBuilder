//
//  WorkspaceTheme.swift
//  alpha
//
//  Created by Dragomir Mindrescu on 19.10.2025.
//

import SwiftUI

// MARK: - Spacing Tokens

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Typography Presets

enum TypographyPreset {
    static let sectionHeader: Font = .system(size: 11, weight: .semibold, design: .rounded)
    static let controlLabel: Font = .system(size: 12, weight: .medium)
    static let controlValue: Font = .system(size: 12, weight: .regular).monospacedDigit()
    static let panelTitle: Font = .system(size: 15, weight: .semibold, design: .rounded)
    static let toolbarTitle: Font = .system(size: 18, weight: .bold, design: .rounded)
}

// MARK: - Theme

struct WorkspaceTheme {
    let colorScheme: ColorScheme

    // MARK: Backgrounds

    var workspaceBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.09, green: 0.1, blue: 0.12)
        : Color(red: 0.95, green: 0.96, blue: 0.98)
    }

    var panelBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.14, green: 0.15, blue: 0.18)
        : Color.white
    }

    var elevatedBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.17, green: 0.18, blue: 0.22)
        : Color(red: 0.98, green: 0.98, blue: 0.99)
    }

    // MARK: Shadows

    var panelShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.08)
    }

    var cardShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.04)
    }

    // MARK: Outlines & Strokes

    var outlineStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }

    var subtleDivider: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    func outlineFill(isActive: Bool) -> Color {
        if isActive {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.24 : 0.14)
        }
        return panelBackground
    }

    // MARK: Hover & Interactive States

    var hoverOverlay: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    var pressedOverlay: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }

    var hoverStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.10)
    }

    // MARK: Text

    var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
    }

    var tertiaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.30)
    }
}

// MARK: - Reusable Panel Header

struct PanelHeader: View {
    let title: String
    let icon: String?
    let theme: WorkspaceTheme

    init(_ title: String, icon: String? = nil, theme: WorkspaceTheme) {
        self.title = title
        self.icon = icon
        self.theme = theme
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.secondaryText)
            }
            Text(title)
                .font(TypographyPreset.panelTitle)
        }
    }
}

// MARK: - Subtle Divider

struct PanelDivider: View {
    let theme: WorkspaceTheme

    var body: some View {
        Rectangle()
            .fill(theme.subtleDivider)
            .frame(height: 1)
    }
}

