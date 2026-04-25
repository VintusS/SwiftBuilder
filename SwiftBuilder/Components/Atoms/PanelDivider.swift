import SwiftUI

struct PanelDivider: View {
    enum Orientation {
        case horizontal
        case vertical
    }

    let theme: WorkspaceTheme
    var orientation: Orientation = .horizontal

    var body: some View {
        Rectangle()
            .fill(theme.subtleDivider)
            .frame(
                width: orientation == .vertical ? 1 : nil,
                height: orientation == .horizontal ? 1 : nil
            )
    }
}
