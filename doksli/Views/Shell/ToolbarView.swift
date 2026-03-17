import SwiftUI

// MARK: - ToolbarView

struct ToolbarView: ToolbarContent {
    @ObservedObject var appState: AppState

    var body: some ToolbarContent {

        // MARK: Environment selector

        ToolbarItem(placement: .primaryAction) {
            EnvSelectorMenu(appState: appState)
        }

        // MARK: Keyboard shortcuts (hidden)

        ToolbarItem(placement: .automatic) {
            Group {
                Button("") { }
                    .keyboardShortcut(.return, modifiers: .command)
                Button("") { }
                    .keyboardShortcut("n", modifiers: .command)
                Button("") { }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                Button("") { }
                    .keyboardShortcut("k", modifiers: .command)
                Button("") { appState.showEnvEditor = true }
                    .keyboardShortcut("e", modifiers: .command)
                Button("") { }
                    .keyboardShortcut("d", modifiers: .command)
            }
            .frame(width: 0, height: 0)
            .opacity(0)
        }
    }
}
