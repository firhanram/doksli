import SwiftUI

// MARK: - ToolbarView

struct ToolbarView: ToolbarContent {
    @ObservedObject var appState: AppState

    var body: some ToolbarContent {

        // MARK: Environment selector

        ToolbarItem(placement: .primaryAction) {
            EnvSelectorMenu(appState: appState)
        }

        // MARK: Settings

        ToolbarItem(placement: .primaryAction) {
            Button {
                appState.showSettings = true
            } label: {
                Image(systemName: "gear")
                    .foregroundColor(AppColors.textTertiary)
            }
        }

    }
}
