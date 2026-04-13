import SwiftUI
import SwiftBuilderComponents

struct TemplateCard: View {
    let template: ScreenTemplate
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(template.accentColor.opacity(0.1))
                    Image(systemName: template.icon)
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(template.accentColor)
                }
                .frame(height: 100)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(template.title)
                        .font(.system(size: 14, weight: .semibold))
                    Text(template.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(isHovered ? 0.12 : 0.06), radius: isHovered ? 12 : 8, y: isHovered ? 6 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isHovered ? template.accentColor.opacity(0.3) : Color.secondary.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
