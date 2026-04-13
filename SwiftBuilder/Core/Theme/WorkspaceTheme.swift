import SwiftUI

struct WorkspaceTheme {
    let colorScheme: ColorScheme

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

    var panelShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.08)
    }

    var cardShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.04)
    }

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

    var hoverOverlay: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    var pressedOverlay: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }

    var hoverStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.10)
    }

    var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
    }

    var tertiaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.30)
    }
}
