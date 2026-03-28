import SwiftUI

// MARK: - ToolbarView

struct ToolbarView: ToolbarContent {
    @ObservedObject var appState: AppState

    var body: some ToolbarContent {

        // MARK: Title + Environment selector

        ToolbarItem(placement: .navigation) {
            HStack(spacing: AppSpacing.md) {
                Text("Doksli")
                    .font(.headline)
                EnvSelectorMenu(appState: appState)
            }
        }

        // MARK: Settings (far right)

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
