import SwiftUI
import SwiftBuilderComponents

struct CanvasOutlineView: View {
    let theme: WorkspaceTheme
    let blocks: [CanvasBlock]
    let selectedBlockID: CanvasBlock.ID?
    let onSelectBlock: (CanvasBlock.ID) -> Void
    var onMoveBlock: (IndexSet, Int) -> Void = { _, _ in }
    var canMergeIntoRow: (UUID) -> Bool = { _ in false }
    var onMergeIntoRow: (UUID) -> Void = { _ in }
    var onRemoveFromRow: (UUID) -> Void = { _ in }

    @State private var draggedBlockID: CanvasBlock.ID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if blocks.isEmpty {
                    emptyOutline
                } else {
                    ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                        outlineRow(block: block, index: index)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
        }
    }

    private func outlineRow(block: CanvasBlock, index: Int) -> some View {
        let isActive = block.id == selectedBlockID
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                onSelectBlock(block.id)
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                if block.rowGroupID != nil {
                    Image(systemName: "square.split.1x2.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.accentColor.opacity(0.5))
                        .frame(width: 10)
                }
                Image(systemName: block.kind.iconSystemName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isActive ? .accentColor : .secondary)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(block.kind.displayName)
                        .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                    HStack(spacing: Spacing.xs) {
                        Text(block.outlineSummary)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if block.navigationTarget != nil {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isActive ? theme.outlineFill(isActive: true) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isActive ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(draggedBlockID == block.id ? 0.4 : 1)
        .draggable(block.id.uuidString) {
            HStack(spacing: 6) {
                Image(systemName: block.kind.iconSystemName)
                    .font(.system(size: 11))
                Text(block.kind.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.regularMaterial)
            )
            .onAppear { draggedBlockID = block.id }
        }
        .dropDestination(for: String.self) { items, _ in
            guard let droppedString = items.first,
                  let droppedID = UUID(uuidString: droppedString),
                  let fromIndex = blocks.firstIndex(where: { $0.id == droppedID }),
                  fromIndex != index else { return false }
            let destination = fromIndex < index ? index + 1 : index
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                onMoveBlock(IndexSet(integer: fromIndex), destination)
            }
            draggedBlockID = nil
            return true
        } isTargeted: { targeted in
            if !targeted { draggedBlockID = nil }
        }
        .contextMenu {
            Button("Move Up") {
                withAnimation { onMoveBlock(IndexSet(integer: index), index - 1) }
            }
            .disabled(index == 0)
            Button("Move Down") {
                withAnimation { onMoveBlock(IndexSet(integer: index), index + 2) }
            }
            .disabled(index >= blocks.count - 1)
            Divider()
            if canMergeIntoRow(block.id) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onMergeIntoRow(block.id)
                    }
                } label: {
                    Label("Merge with Next into Row", systemImage: "rectangle.split.1x2")
                }
            }
            if block.rowGroupID != nil {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onRemoveFromRow(block.id)
                    }
                } label: {
                    Label("Remove from Row", systemImage: "rectangle.split.1x2.slash")
                }
            }
        }
    }

    private var emptyOutline: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "square.stack")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.quaternary)
            Text("No components yet")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text("Add from the Library tab.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
