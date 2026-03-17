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
                Button("") { appState.sendCurrentRequest() }
                    .keyboardShortcut(.return, modifiers: .command)
                Button("") { appState.addNewRequest() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("") { appState.addNewFolder() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                Button("") { appState.clearResponse() }
                    .keyboardShortcut("k", modifiers: .command)
                Button("") { appState.showEnvEditor = true }
                    .keyboardShortcut("e", modifiers: .command)
                Button("") { appState.duplicateSelectedRequest() }
                    .keyboardShortcut("d", modifiers: .command)
            }
            .frame(width: 0, height: 0)
            .opacity(0)
        }
    }
}
