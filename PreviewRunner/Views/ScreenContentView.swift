//
//  ScreenContentView.swift
//  PreviewRunner
//
//  Created by Dragomir Mindrescu on 19.10.2025.
//

import SwiftUI

struct ScreenContentView: View {
    let screen: Screen
    let allScreens: [Screen]
    let appearance: PreviewAppearance
    var isRoot: Bool = false
    @Binding var alertMessage: String?

    var body: some View {
        let rows = BlockRow.group(screen.blocks)
        ZStack {
            appearance.canvasBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        if row.isGrouped {
                            HStack(spacing: 8) {
                                ForEach(row.blocks) { block in
                                    blockRow(block)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.top, CGFloat(row.blocks.first?.spacingBefore ?? 0))
                        } else if let block = row.blocks.first {
                            blockRow(block)
                        }
                    }
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(appearance.colorScheme)
        .navigationTitle(screen.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func blockRow(_ block: CanvasBlock) -> some View {
        let isButton = [CanvasBlock.Kind.primaryButton, .secondaryButton, .linkButton].contains(block.kind)
        let targetScreen = block.navigationTarget.flatMap { tid in
            allScreens.first(where: { $0.id == tid })
        }

        let view = CanvasBlockView(
            block: block,
            appearance: appearance,
            isSelected: false,
            isInteractive: true,
            onButtonTap: isButton && targetScreen == nil
                ? { alertMessage = "\(block.content.isEmpty ? "Button" : block.content) tapped (no nav target set)" }
                : nil
        )
        .padding(.top, CGFloat(block.spacingBefore))

        if let target = targetScreen {
            NavigationLink(value: target.id) {
                view
            }
            .buttonStyle(.plain)
        } else if block.navigationTarget != nil {
            view.overlay(alignment: .topTrailing) {
                Text("nav target not found")
                    .font(.system(size: 8))
                    .foregroundColor(.red)
                    .padding(2)
                    .background(.red.opacity(0.15))
            }
        } else {
            view
        }
    }
}
