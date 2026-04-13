import SwiftUI

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

enum TypographyPreset {
    static let sectionHeader: Font = .system(size: 11, weight: .semibold, design: .rounded)
    static let controlLabel: Font = .system(size: 12, weight: .medium)
    static let controlValue: Font = .system(size: 12, weight: .regular).monospacedDigit()
    static let panelTitle: Font = .system(size: 15, weight: .semibold, design: .rounded)
    static let toolbarTitle: Font = .system(size: 18, weight: .bold, design: .rounded)
}
