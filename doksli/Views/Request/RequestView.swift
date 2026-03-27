import SwiftUI

// MARK: - RequestTab

enum RequestTab: String, CaseIterable {
    case params = "Params"
    case headers = "Headers"
    case body = "Body"
    case auth = "Auth"
}

// MARK: - RequestView

struct RequestView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeTab: RequestTab = .params
    @State private var previousRequestId: UUID?

    var body: some View {
        Group {
            if appState.selectedRequest != nil {
                requestEditor
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.canvas)
        .onChange(of: appState.selectedRequest?.id) { newId in
            if let prevId = previousRequestId, prevId != newId {
                syncRequestToWorkspace()
            }
            previousRequestId = newId
        }
        .onChange(of: appState.selectedRequest) { _ in
            syncRequestToWorkspace()
        }
    }

    // MARK: - Request editor

    private var requestBinding: Binding<Request> {
        Binding(
            get: {
                appState.selectedRequest ?? Request(
                    id: UUID(), name: "", method: .GET, url: "",
                    params: [], headers: [], body: .none, auth: .none
                )
            },
            set: { appState.selectedRequest = $0 }
        )
    }

    private var requestEditor: some View {
        VStack(spacing: 0) {
            URLBarView(request: requestBinding)

            Divider()
                .foregroundColor(AppColors.border)

            TabBarView(
                tabs: RequestTab.allCases,
                activeTab: $activeTab,
                label: { $0.rawValue }
            )

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .params:
            ScrollView {
                KVEditor(
                    pairs: requestBinding.params,
                    keyPlaceholder: "Parameter",
                    valuePlaceholder: "Value",
                    showValueType: true,
                    showFileOption: false
                )
            }

        case .headers:
            ScrollView {
                KVEditor(
                    pairs: requestBinding.headers,
                    keyPlaceholder: "Header",
                    valuePlaceholder: "Value"
                )
            }

        case .body:
            BodyEditor(requestBody: requestBinding.body)

        case .auth:
            AuthEditor(auth: requestBinding.auth)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "arrow.left.circle")
                .font(.largeTitle)
                .foregroundColor(AppColors.textFaint)
            Text("Select a request")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
        }
    }

    // MARK: - Workspace sync

    private func syncRequestToWorkspace() {
        guard let request = appState.selectedRequest,
              let wsIndex = appState.workspaces.firstIndex(where: { $0.id == appState.selectedWorkspace?.id }) else { return }

        var workspace = appState.workspaces[wsIndex]
        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = updateRequestInItems(requestId: request.id, request: request, in: col.items)
            return col
        }

        appState.workspaces[wsIndex] = workspace
        appState.saveWorkspaces()
    }

    private func updateRequestInItems(requestId: UUID, request: Request, in items: [Item]) -> [Item] {
        items.map { item in
            switch item {
            case .request(var r):
                if r.id == requestId { r = request }
                return .request(r)
            case .folder(var f):
                f.items = updateRequestInItems(requestId: requestId, request: request, in: f.items)
                return .folder(f)
            }
        }
    }
}
