//
//  SwiftBuilderApp.swift
//  SwiftBuilder
//
//  Created by Dragomir Mindrescu on 06.10.2025.
//

import SwiftUI

@main
struct SwiftBuilderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            BuilderCommands()
        }
    }
}

struct BuilderCommands: Commands {
    @FocusedValue(\.store) private var store

    var body: some Commands {
        CommandGroup(after: .saveItem) {
            Button("Save Project") {
                store?.saveProject()
            }
            .keyboardShortcut("s", modifiers: .command)

            Button("Export SwiftUI Code\u{2026}") {
                store?.exportCode()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Divider()

            Button("Run on Simulator") {
                store?.launchSimulator()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(store?.isBuilding == true)
        }

        CommandGroup(after: .pasteboard) {
            Button("Duplicate") {
                store?.duplicateSelectedBlock()
            }
            .keyboardShortcut("d", modifiers: .command)
            .disabled(store?.selectedBlockID == nil)

            Button("Delete") {
                store?.removeSelectedBlock()
            }
            .keyboardShortcut(.delete, modifiers: [])
            .disabled(store?.selectedBlockID == nil)
        }

        CommandGroup(replacing: .newItem) {
            Button("New Screen from Template\u{2026}") {
                store?.showingTemplateGallery = true
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Button("New Blank Screen") {
                store?.addScreen()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }
    }
}
