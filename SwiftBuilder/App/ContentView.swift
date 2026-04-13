//
//  ContentView.swift
//  SwiftBuilder
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @State private var store = ProjectStore()

    var body: some View {
        BuilderWorkspaceV2(store: store)
            .frame(minWidth: 1080, minHeight: 700)
            #if os(macOS)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let window = NSApplication.shared.mainWindow,
                       !window.styleMask.contains(.fullScreen) {
                        window.toggleFullScreen(nil)
                    }
                }
            }
            #endif
    }
}

struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

#Preview {
    ContentView()
        .frame(width: 1280, height: 780)
}
