import SwiftUI

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var selectedWorkspace: Workspace? = nil {
        didSet {
            // Reset state when switching workspaces
            if oldValue?.id != selectedWorkspace?.id {
                selectedRequest = nil
                pendingResponse = nil
                lastError = nil
                responseCache.removeAll()
                errorCache.removeAll()

                if let envId = selectedWorkspace?.activeEnvironmentId {
                    activeEnvironment = environments.first { $0.id == envId }
                } else {
                    activeEnvironment = nil
                }
            }
        }
    }
    @Published var selectedRequest: Request? = nil {
        didSet {
            // Save response for previous request
            if let prevId = oldValue?.id, prevId != selectedRequest?.id {
                responseCache[prevId] = pendingResponse
                errorCache[prevId] = lastError
            }
            // Restore response for newly selected request
            if let newId = selectedRequest?.id, newId != oldValue?.id {
                pendingResponse = responseCache[newId] ?? nil
                lastError = errorCache[newId] ?? nil
            }
        }
    }
    @Published var activeEnvironment: Environment? = nil {
        didSet {
            // Persist environment selection to the current workspace
            guard oldValue?.id != activeEnvironment?.id,
                  var workspace = selectedWorkspace,
                  let wsIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }
            workspace.activeEnvironmentId = activeEnvironment?.id
            workspaces[wsIndex] = workspace
            selectedWorkspace = workspace
            try? StorageService.saveWorkspaces(workspaces)
        }
    }
    @Published var environments: [Environment] = []
    @Published var pendingResponse: Response? = nil
    @Published var isLoading: Bool = false
    @Published var lastError: String? = nil
    @Published var showEnvEditor: Bool = false
    @Published var editingEnvironment: Environment? = nil
    private var responseCache: [UUID: Response?] = [:]
    private var errorCache: [UUID: String?] = [:]

    // MARK: - Workspace helpers

    func loadWorkspaces() {
        workspaces = StorageService.loadWorkspaces()
        selectedWorkspace = workspaces.first
    }

    func saveWorkspaces() {
        try? StorageService.saveWorkspaces(workspaces)
    }

    // MARK: - Environment helpers

    func loadEnvironments() {
        environments = StorageService.loadEnvironments()
        // Restore active environment for current workspace
        if let envId = selectedWorkspace?.activeEnvironmentId {
            activeEnvironment = environments.first { $0.id == envId }
        }
    }

    func saveEnvironments() {
        try? StorageService.saveEnvironments(environments)
    }

    // MARK: - Send

    func sendCurrentRequest() {
        guard let request = selectedRequest,
              !request.url.trimmingCharacters(in: .whitespaces).isEmpty,
              !isLoading else { return }

        // Validate: GET and HEAD must not have a body
        if (request.method == .GET || request.method == .HEAD), request.body != .none {
            pendingResponse = nil
            lastError = "\(request.method.rawValue) method must not have a body"
            cacheCurrentResponse(for: request.id)
            return
        }

        isLoading = true
        pendingResponse = nil
        lastError = nil

        let requestId = request.id
        Task {
            do {
                let response = try await HTTPClient.send(request, environment: activeEnvironment)
                pendingResponse = response
                isLoading = false
                cacheCurrentResponse(for: requestId)

            } catch let error as URLError {
                isLoading = false
                lastError = mapURLError(error)
                cacheCurrentResponse(for: requestId)
            } catch let error as HTTPClientError {
                isLoading = false
                switch error {
                case .invalidURL(let url):
                    lastError = "Invalid URL: \(url)"
                case .notHTTPResponse:
                    lastError = "Server returned an invalid response"
                }
                cacheCurrentResponse(for: requestId)
            } catch {
                isLoading = false
                lastError = error.localizedDescription
                cacheCurrentResponse(for: requestId)
            }
        }
    }

    private func mapURLError(_ error: URLError) -> String {
        switch error.code {
        case .timedOut:
            return "Request timed out"
        case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasUnknownRoot:
            return "SSL/TLS connection failed"
        case .cannotConnectToHost:
            return "Cannot connect to server"
        case .notConnectedToInternet:
            return "No internet connection"
        case .cannotFindHost:
            return "Cannot find host"
        default:
            return error.localizedDescription
        }
    }

    // MARK: - Response actions

    func clearResponse() {
        pendingResponse = nil
        lastError = nil
        if let id = selectedRequest?.id {
            responseCache.removeValue(forKey: id)
            errorCache.removeValue(forKey: id)
        }
    }

    private func cacheCurrentResponse(for requestId: UUID) {
        responseCache[requestId] = pendingResponse
        errorCache[requestId] = lastError
    }

    // MARK: - Workspace mutations

    func createWorkspace() {
        let newWorkspace = Workspace(
            id: UUID(),
            name: "New Workspace",
            collections: []
        )
        workspaces.append(newWorkspace)
        selectedWorkspace = newWorkspace
        saveWorkspaces()
    }

    func importPostmanFolder(_ folder: Folder) {
        guard var workspace = selectedWorkspace,
              let wsIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        if workspace.collections.isEmpty {
            workspace.collections.append(
                Collection(id: UUID(), name: "Requests", items: [.folder(folder)])
            )
        } else {
            workspace.collections[0].items.append(.folder(folder))
        }

        workspaces[wsIndex] = workspace
        selectedWorkspace = workspace
        saveWorkspaces()
    }

    func addNewRequest(method: HTTPMethod = .GET) {
        guard var workspace = selectedWorkspace,
              let wsIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        let newRequest = Request(
            id: UUID(), name: "New Request", method: method, url: "",
            params: [], headers: [], body: .none, auth: .none
        )

        if workspace.collections.isEmpty {
            workspace.collections.append(
                Collection(id: UUID(), name: "Requests", items: [.request(newRequest)])
            )
        } else {
            workspace.collections[0].items.append(.request(newRequest))
        }

        workspaces[wsIndex] = workspace
        selectedWorkspace = workspace
        selectedRequest = newRequest
        saveWorkspaces()
    }

    func addNewFolder() {
        guard var workspace = selectedWorkspace,
              let wsIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        let newFolder = Folder(id: UUID(), name: "New Folder", items: [])

        if workspace.collections.isEmpty {
            workspace.collections.append(
                Collection(id: UUID(), name: "Requests", items: [.folder(newFolder)])
            )
        } else {
            workspace.collections[0].items.append(.folder(newFolder))
        }

        workspaces[wsIndex] = workspace
        selectedWorkspace = workspace
        saveWorkspaces()
    }

    func duplicateSelectedRequest() {
        guard let request = selectedRequest,
              var workspace = selectedWorkspace,
              let wsIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        var copy = request
        copy.id = UUID()
        copy.name = "\(request.name) (Copy)"

        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = insertAfter(requestId: request.id, newItem: .request(copy), in: col.items)
            return col
        }

        workspaces[wsIndex] = workspace
        selectedWorkspace = workspace
        saveWorkspaces()
    }

    private func insertAfter(requestId: UUID, newItem: Item, in items: [Item]) -> [Item] {
        var result: [Item] = []
        for item in items {
            switch item {
            case .request(let r):
                result.append(item)
                if r.id == requestId {
                    result.append(newItem)
                }
            case .folder(let f):
                var folder = f
                folder.items = insertAfter(requestId: requestId, newItem: newItem, in: f.items)
                result.append(.folder(folder))
            }
        }
        return result
    }

}
