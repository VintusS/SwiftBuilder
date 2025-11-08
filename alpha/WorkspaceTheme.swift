//
//  WorkspaceTheme.swift
//  alpha
//
//  Created by Dragomir Mindrescu on 19.10.2025.
//

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
    
    var panelShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.08)
    }
    
    var cardShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.04)
    }
    
    var outlineStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }
    
    func outlineFill(isActive: Bool) -> Color {
        if isActive {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.24 : 0.14)
        }
        return panelBackground
    }
}

