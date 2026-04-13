import SwiftUI

enum PreviewAppearance: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var colorScheme: ColorScheme {
        self == .dark ? .dark : .light
    }

    var deviceShellColor: Color {
        self == .dark ? Color.black.opacity(0.92) : Color.black.opacity(0.25)
    }

    var bezelHighlight: Color {
        self == .dark ? Color.black.opacity(0.75) : Color.white.opacity(0.7)
    }

    var deviceInnerRim: Color {
        self == .dark ? Color.black.opacity(0.88) : Color.black.opacity(0.82)
    }

    var canvasBackground: Color {
        self == .dark ? Color(red: 0.09, green: 0.1, blue: 0.12) : Color.white
    }

    var screenStroke: Color {
        self == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }
}
