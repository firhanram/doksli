import SwiftUI

// MARK: - ToolbarView

struct ToolbarView: ToolbarContent {
    @ObservedObject var appState: AppState

    var body: some ToolbarContent {

        // MARK: Environment selector

        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("No Environment") {
                    appState.activeEnvironment = nil
                }
                Divider()
                // Environment list populated in Phase 8
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "square.stack")
                    Text(appState.activeEnvironment?.name ?? "No Environment")
                        .font(AppFonts.body)
                }
            }
        }

        // MARK: Keyboard shortcuts

        ToolbarItem(placement: .automatic) {
            Button("Send Request") { }
                .keyboardShortcut(.return, modifiers: .command)
        }

        ToolbarItem(placement: .automatic) {
            Button("New Request") { }
                .keyboardShortcut("n", modifiers: .command)
        }

        ToolbarItem(placement: .automatic) {
            Button("New Folder") { }
                .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        ToolbarItem(placement: .automatic) {
            Button("Clear Response") { }
                .keyboardShortcut("k", modifiers: .command)
        }

        ToolbarItem(placement: .automatic) {
            Button("Env Editor") { }
                .keyboardShortcut("e", modifiers: .command)
        }

        ToolbarItem(placement: .automatic) {
            Button("Duplicate") { }
                .keyboardShortcut("d", modifiers: .command)
        }
    }
}
