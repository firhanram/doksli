import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } content: {
            RequestView()
        } detail: {
            ResponseView()
        }
        .frame(minWidth: 900, minHeight: 600)
        .navigationTitle("Doksli")
        .toolbar { ToolbarView(appState: appState) }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
}
