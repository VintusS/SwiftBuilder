import SwiftUI
import SwiftBuilderComponents

struct TemplateGallery: View {
    let onSelect: (Screen) -> Void
    let onDismiss: () -> Void

    private let templates = ScreenTemplate.all

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: Spacing.xl)], spacing: Spacing.xl) {
                    ForEach(templates) { template in
                        TemplateCard(template: template) {
                            onSelect(template.screen)
                        }
                    }
                }
                .padding(Spacing.xxl)
            }
        }
        .frame(minWidth: 640, minHeight: 440)
        .background(.ultraThinMaterial)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Screen Templates")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Start with a pre-built layout or add a blank screen.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                onSelect(Screen(name: "New Screen", blocks: []))
            } label: {
                Label("Blank Screen", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            Button("Cancel") { onDismiss() }
                .buttonStyle(.bordered)
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.vertical, Spacing.lg)
    }
}
