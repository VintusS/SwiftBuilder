import Foundation

enum RunTarget: String, CaseIterable, Identifiable {
    case simulator
    case physicalDevice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simulator: return "Simulator"
        case .physicalDevice: return "Real Device"
        }
    }

    var systemImage: String {
        switch self {
        case .simulator: return "iphone.gen3"
        case .physicalDevice: return "iphone.and.arrow.forward"
        }
    }

    var runButtonHelp: String {
        switch self {
        case .simulator: return "Build and run PreviewRunner on an iOS simulator"
        case .physicalDevice: return "Build and run PreviewRunner on a connected iPhone"
        }
    }
}

struct PhysicalDevice: Identifiable, Equatable {
    let id: String
    let name: String
    let isAvailable: Bool

    var displayName: String {
        isAvailable ? name : "\(name) (Unavailable)"
    }
}
