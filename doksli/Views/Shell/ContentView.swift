import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var newWorkspaceName = ""

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } content: {
            RequestView()
                .navigationSplitViewColumnWidth(min: 350, ideal: 400)
        } detail: {
            ResponseView()
        }
        .frame(minWidth: 1000, minHeight: 600)
        .navigationTitle("Doksli")
        .toolbar { ToolbarView(appState: appState) }
        .sheet(isPresented: $appState.showEnvEditor) {
            EnvEditorSheet()
                .environmentObject(appState)
        }
        .alert("New Workspace", isPresented: $appState.showCreateWorkspace) {
            TextField("Workspace name", text: $newWorkspaceName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                appState.createWorkspace(name: newWorkspaceName)
                newWorkspaceName = ""
            }
        }
        .overlay {
            if appState.showQuickSearch {
                QuickSearchView()
                    .environmentObject(appState)
                    .transition(.opacity)
            }
        }
        .task {
            appState.loadWorkspaces()
            appState.loadEnvironments()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
}
