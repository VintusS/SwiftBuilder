import SwiftUI

struct SelectionOutline<Content: View>: View {
    let isActive: Bool
    let isHovered: Bool
    let content: Content

    private let outlineRadius: CGFloat = 8

    init(isActive: Bool, isHovered: Bool = false, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.isHovered = isHovered
        self.content = content()
    }

    var body: some View {
        content
            .background(backgroundTint)
            .overlay(borderOverlay)
            .animation(.easeInOut(duration: 0.15), value: isActive)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
    }

    @ViewBuilder
    private var backgroundTint: some View {
        if isActive {
            RoundedRectangle(cornerRadius: outlineRadius, style: .continuous)
                .fill(Color.accentColor.opacity(0.04))
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if isActive {
            RoundedRectangle(cornerRadius: outlineRadius, style: .continuous)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
        } else if isHovered {
            RoundedRectangle(cornerRadius: outlineRadius, style: .continuous)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        }
    }
}
