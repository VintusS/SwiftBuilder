import SwiftUI

enum FontWeightOption: String, CaseIterable, Identifiable {
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var weight: Font.Weight {
        switch self {
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }

    var exportKey: String {
        rawValue
    }
}
