import Foundation

enum PreviewZoom {
    static let minimum = 0.25
    static let maximum = 3.0
    static let reset = 1.0

    static func clamped(_ value: Double) -> Double {
        min(max(value, minimum), maximum)
    }
}
