import SwiftUI

struct PanelHeader: View {
    let title: String
    let icon: String?
    let theme: WorkspaceTheme

    init(_ title: String, icon: String? = nil, theme: WorkspaceTheme) {
        self.title = title
        self.icon = icon
        self.theme = theme
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.secondaryText)
            }
            Text(title)
                .font(TypographyPreset.panelTitle)
        }
    }
}
