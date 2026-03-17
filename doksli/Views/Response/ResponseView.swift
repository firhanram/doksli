import SwiftUI

// MARK: - ResponseTab

enum ResponseTab: Hashable {
    case body
    case headers
    case raw

    var label: String {
        switch self {
        case .body: return "Body"
        case .headers: return "Headers"
        case .raw: return "Raw"
        }
    }
}

// MARK: - ResponseView

struct ResponseView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeTab: ResponseTab = .body

    var body: some View {
        Group {
            if appState.isLoading {
                loadingView
            } else if let response = appState.pendingResponse {
                responseContent(response)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.canvas)
    }

    // MARK: - Response content

    private func responseContent(_ response: Response) -> some View {
        VStack(spacing: 0) {
            StatsBarView(response: response)

            TabBarView(
                tabs: [ResponseTab.body, .headers, .raw],
                activeTab: $activeTab,
                label: { $0.label }
            )

            tabContent(response)
        }
    }

    // MARK: - Tab content

    @ViewBuilder
    private func tabContent(_ response: Response) -> some View {
        switch activeTab {
        case .body:
            if isJSONResponse(response) {
                JSONTreeView(data: response.body)
            } else {
                RawBodyView(data: response.body)
            }
        case .headers:
            HeadersListView(headers: response.headers)
        case .raw:
            RawBodyView(data: response.body)
        }
    }

    // MARK: - JSON detection

    private func isJSONResponse(_ response: Response) -> Bool {
        if let contentType = response.headers.first(where: {
            $0.key.lowercased() == "content-type"
        }) {
            return contentType.value.lowercased().contains("json")
        }
        // Try parsing as JSON as fallback
        return (try? JSONSerialization.jsonObject(with: response.body)) != nil
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "paperplane")
                .font(.system(size: 32))
                .foregroundColor(AppColors.textPlaceholder)
            Text("Send a request to see the response")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPlaceholder)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .controlSize(.small)
            Text("Sending request…")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
        }
    }
}
