import SwiftUI

struct WorkspaceTheme {
    let colorScheme: ColorScheme

    var brandAccent: Color {
        Color(red: 1.0, green: 0.04, blue: 0.03)
    }

    var brandAccentHighlight: Color {
        Color(red: 1.0, green: 0.28, blue: 0.22)
    }

    var brandAccentDeep: Color {
        Color(red: 0.52, green: 0.0, blue: 0.0)
    }

    var workspaceBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.035, green: 0.025, blue: 0.025)
        : Color(red: 0.975, green: 0.955, blue: 0.95)
    }

    var toolbarBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.055, green: 0.035, blue: 0.035)
        : Color(red: 0.99, green: 0.965, blue: 0.955)
    }

    var panelBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.075, green: 0.055, blue: 0.055)
        : Color(red: 1.0, green: 0.985, blue: 0.98)
    }

    var elevatedBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.105, green: 0.075, blue: 0.075)
        : Color(red: 0.995, green: 0.97, blue: 0.96)
    }

    var panelShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.65) : brandAccentDeep.opacity(0.08)
    }

    var cardShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.55) : brandAccentDeep.opacity(0.06)
    }

    var outlineStrokeColor: Color {
        colorScheme == .dark ? brandAccent.opacity(0.14) : brandAccentDeep.opacity(0.10)
    }

    var subtleDivider: Color {
        colorScheme == .dark ? brandAccent.opacity(0.12) : brandAccentDeep.opacity(0.09)
    }

    func outlineFill(isActive: Bool) -> Color {
        if isActive {
            return brandAccent.opacity(colorScheme == .dark ? 0.26 : 0.13)
        }
        return panelBackground
    }

    var hoverOverlay: Color {
        colorScheme == .dark ? brandAccent.opacity(0.10) : brandAccentDeep.opacity(0.05)
    }

    var pressedOverlay: Color {
        colorScheme == .dark ? brandAccent.opacity(0.16) : brandAccentDeep.opacity(0.08)
    }

    var hoverStroke: Color {
        colorScheme == .dark ? brandAccent.opacity(0.28) : brandAccentDeep.opacity(0.14)
    }

    var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.62) : Color.black.opacity(0.50)
    }

    var tertiaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.40) : Color.black.opacity(0.34)
    }
}
