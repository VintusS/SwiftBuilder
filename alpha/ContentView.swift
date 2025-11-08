//
//  ContentView.swift
//  alpha
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        BuilderWorkspaceV2()
            .frame(minWidth: 1080, minHeight: 700)
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
