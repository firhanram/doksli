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
            detailPlaceholder
        }
        .frame(minWidth: 900, minHeight: 600)
        .navigationTitle("Doksli")
        .toolbar { ToolbarView(appState: appState) }
    }

    // MARK: Placeholder — replaced in Phase 7

    private var detailPlaceholder: some View {
        VStack {
            Spacer()
            Text("Response Panel")
                .font(AppFonts.title)
                .foregroundColor(AppColors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.surface)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
}
