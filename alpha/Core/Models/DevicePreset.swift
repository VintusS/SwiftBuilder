import SwiftUI

enum DeviceFormFactor {
    case homeButton
    case dynamicIsland
    case iPad
}

enum DevicePreset: String, CaseIterable, Identifiable {
    case iphoneSE
    case iphone16
    case iphone16Pro
    case iphone16ProMax
    case iphoneAir
    case ipadMini
    case ipadAir11

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iphoneSE: return "iPhone SE"
        case .iphone16: return "iPhone 16"
        case .iphone16Pro: return "iPhone 16 Pro"
        case .iphone16ProMax: return "iPhone 16 Pro Max"
        case .iphoneAir: return "iPhone Air"
        case .ipadMini: return "iPad mini"
        case .ipadAir11: return "iPad Air 11\""
        }
    }

    var formFactor: DeviceFormFactor {
        switch self {
        case .iphoneSE: return .homeButton
        case .iphone16, .iphone16Pro, .iphone16ProMax, .iphoneAir: return .dynamicIsland
        case .ipadMini, .ipadAir11: return .iPad
        }
    }

    var size: CGSize {
        switch self {
        case .iphoneSE: return CGSize(width: 375, height: 667)
        case .iphone16: return CGSize(width: 393, height: 852)
        case .iphone16Pro: return CGSize(width: 402, height: 874)
        case .iphone16ProMax: return CGSize(width: 440, height: 956)
        case .iphoneAir: return CGSize(width: 430, height: 932)
        case .ipadMini: return CGSize(width: 744, height: 1133)
        case .ipadAir11: return CGSize(width: 820, height: 1180)
        }
    }

    var screenCornerRadius: CGFloat {
        switch self {
        case .iphoneSE: return 0
        case .iphone16: return 50
        case .iphone16Pro: return 55
        case .iphone16ProMax: return 55
        case .iphoneAir: return 53
        case .ipadMini: return 22
        case .ipadAir11: return 22
        }
    }

    var cornerRadius: CGFloat { screenCornerRadius }

    var bezelWidth: CGFloat {
        switch formFactor {
        case .homeButton: return 6
        case .dynamicIsland: return 5
        case .iPad: return 12
        }
    }

    var topBezel: CGFloat {
        switch self {
        case .iphoneSE: return 56
        default: return bezelWidth
        }
    }

    var bottomBezel: CGFloat {
        switch self {
        case .iphoneSE: return 56
        default: return bezelWidth
        }
    }

    var frameCornerRadius: CGFloat {
        switch self {
        case .iphoneSE: return 36
        case .iphone16: return 54
        case .iphone16Pro: return 59
        case .iphone16ProMax: return 59
        case .iphoneAir: return 57
        case .ipadMini: return 28
        case .ipadAir11: return 28
        }
    }

    var frameSize: CGSize {
        CGSize(
            width: size.width + bezelWidth * 2,
            height: size.height + topBezel + bottomBezel
        )
    }

    var dynamicIslandSize: CGSize {
        guard formFactor == .dynamicIsland else { return .zero }
        switch self {
        case .iphone16ProMax, .iphoneAir:
            return CGSize(width: 126, height: 37)
        default:
            return CGSize(width: 120, height: 36)
        }
    }

    var safeAreaInsets: EdgeInsets {
        switch self {
        case .iphoneSE:
            return EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0)
        case .iphone16, .iphone16Pro, .iphone16ProMax, .iphoneAir:
            return EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
        case .ipadMini, .ipadAir11:
            return EdgeInsets(top: 24, leading: 0, bottom: 22, trailing: 0)
        }
    }
}
