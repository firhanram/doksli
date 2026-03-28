import SwiftUI

// MARK: - RequestTab

enum RequestTab: String, CaseIterable {
    case params = "Params"
    case headers = "Headers"
    case body = "Body"
    case auth = "Auth"
}

// MARK: - Non-reactive edit buffer

/// Reference-type buffer that holds the in-progress request.
/// Mutations do NOT trigger SwiftUI view updates — only the specific
/// TextField being edited updates (via its own internal state).
private class EditBuffer {
    var request: Request?
    var isDirty = false
}

// MARK: - RequestView

struct RequestView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeTab: RequestTab = .params
    @State private var displayedRequestId: UUID?
    @State private var syncWorkItem: DispatchWorkItem?
    @State private var editBuffer = EditBuffer()

    var body: some View {
        Group {
            if displayedRequestId != nil {
                requestEditor
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.canvas)
        .onChange(of: appState.selectedRequest?.id) { newId in
            // Request switched — flush pending edits, load new request into buffer
            flushSync()
            editBuffer.request = appState.selectedRequest
            editBuffer.isDirty = false
            displayedRequestId = newId
        }
        .onChange(of: appState.selectedRequest) { newRequest in
            // External update (e.g. rename from sidebar)
            guard let newRequest = newRequest else {
                editBuffer.request = nil
                editBuffer.isDirty = false
                displayedRequestId = nil
                return
            }
            if editBuffer.request?.id != newRequest.id {
                editBuffer.request = newRequest
                editBuffer.isDirty = false
                displayedRequestId = newRequest.id
            } else if syncWorkItem == nil && !editBuffer.isDirty {
                // No pending local edits — accept external update
                editBuffer.request = newRequest
            }
        }
        .onAppear {
            editBuffer.request = appState.selectedRequest
            editBuffer.isDirty = false
            displayedRequestId = appState.selectedRequest?.id
        }
        .onDisappear {
            flushSync()
        }
    }

    // MARK: - Debounced sync

    private func debouncedSync() {
        syncWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            commitEdits()
        }
        syncWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func flushSync() {
        syncWorkItem?.cancel()
        syncWorkItem = nil
        guard editBuffer.isDirty, let request = editBuffer.request else { return }
        editBuffer.isDirty = false
        syncRequestToWorkspace(request)
    }

    private func commitEdits() {
        syncWorkItem = nil
        guard editBuffer.isDirty, let request = editBuffer.request else { return }
        editBuffer.isDirty = false
        // Only update appState.selectedRequest if still editing the same request
        if appState.selectedRequest?.id == request.id, appState.selectedRequest != request {
            appState.selectedRequest = request
        }
        syncRequestToWorkspace(request)
    }

    // MARK: - Request editor

    /// Binding that reads/writes the EditBuffer directly.
    /// Because EditBuffer is a reference type, setting it does NOT
    /// trigger RequestView.body to re-evaluate — only the specific
    /// child view being edited updates via its own binding chain.
    private var requestBinding: Binding<Request> {
        Binding(
            get: { editBuffer.request ?? Request(
                id: UUID(), name: "", method: .GET, url: "",
                params: [], headers: [], body: .none, auth: .none
            ) },
            set: { newValue in
                editBuffer.request = newValue
                editBuffer.isDirty = true
                debouncedSync()
            }
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

    private func syncRequestToWorkspace(_ request: Request) {
        // Update stub in tree (name/method/url might have changed)
        appState.updateStubInTree(for: request)

        // Save full request detail file asynchronously
        let requestCopy = request
        DispatchQueue.global(qos: .utility).async {
            try? StorageService.saveRequest(requestCopy)
        }

        // Save tree (stubs only) asynchronously
        let workspaces = appState.workspaces
        DispatchQueue.global(qos: .utility).async {
            try? StorageService.saveWorkspaces(workspaces)
        }
    }
}
