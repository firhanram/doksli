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
                Button("") { }
                    .keyboardShortcut("e", modifiers: .command)
                Button("") { }
                    .keyboardShortcut("d", modifiers: .command)
            }
            .frame(width: 0, height: 0)
            .opacity(0)
        }
    }
}
