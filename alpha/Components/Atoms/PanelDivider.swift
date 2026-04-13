import SwiftUI

struct PanelDivider: View {
    let theme: WorkspaceTheme

    var body: some View {
        Rectangle()
            .fill(theme.subtleDivider)
            .frame(height: 1)
    }
}
