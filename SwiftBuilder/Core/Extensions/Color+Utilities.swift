import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {
    func ensuringContrast(in appearance: PreviewAppearance, minimumLuminance: Double = 0.62) -> Color {
        guard appearance == .dark else { return self }
        guard let luminance = relativeLuminance else { return self }
        if luminance >= minimumLuminance { return self }
        let blendAmount = min(0.95, (minimumLuminance - luminance) * 1.8)
        return blended(with: .white, amount: blendAmount)
    }

    func toComponents() -> ColorComponents {
        if let rgb = rgbComponents() {
            return ColorComponents(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: rgb.alpha)
        }
        return ColorComponents(red: 0, green: 0, blue: 0, alpha: 1)
    }

    private func blended(with color: Color, amount: Double) -> Color {
        guard let first = rgbComponents(), let second = color.rgbComponents() else { return self }
        let ratio = max(0, min(1, amount))
        let red = clamp(first.red + (second.red - first.red) * ratio)
        let green = clamp(first.green + (second.green - first.green) * ratio)
        let blue = clamp(first.blue + (second.blue - first.blue) * ratio)
        let alpha = clamp(first.alpha + (second.alpha - first.alpha) * ratio)
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    private func rgbComponents() -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        #if os(macOS)
        guard let platformColor = NSColor(self).usingColorSpace(.deviceRGB) else { return nil }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue), Double(alpha))
        #else
        let platformColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return (Double(red), Double(green), Double(blue), Double(alpha))
        #endif
    }

    private var relativeLuminance: Double? {
        guard let components = rgbComponents() else { return nil }
        let red = linearized(components.red)
        let green = linearized(components.green)
        let blue = linearized(components.blue)
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    private func linearized(_ value: Double) -> Double {
        value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
