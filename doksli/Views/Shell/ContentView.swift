import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } content: {
            contentPlaceholder
        } detail: {
            detailPlaceholder
        }
        .frame(minWidth: 900, minHeight: 600)
        .toolbar { ToolbarView(appState: appState) }
    }

    // MARK: Placeholders — replaced in Phases 6–7

    private var contentPlaceholder: some View {
        VStack {
            Spacer()
            Text("Request Editor")
                .font(AppFonts.title)
                .foregroundColor(AppColors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.canvas)
    }

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
