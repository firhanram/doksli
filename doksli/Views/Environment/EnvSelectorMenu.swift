import SwiftUI

// MARK: - EnvSelectorMenu

struct EnvSelectorMenu: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Menu {
            Button {
                appState.activeEnvironment = nil
            } label: {
                HStack {
                    Text("No Environment")
                    if appState.activeEnvironment == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(appState.environments) { env in
                Button {
                    appState.activeEnvironment = env
                } label: {
                    HStack {
                        Text(env.name)
                        if appState.activeEnvironment?.id == env.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button("Edit Environments…") {
                appState.showEnvEditor = true
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "square.stack")
                Text(appState.activeEnvironment?.name ?? "No Environment")
                    .font(AppFonts.body)
            }
        }
    }
}
