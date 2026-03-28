import SwiftUI

// MARK: - AppColorMode

enum AppColorMode: String, CaseIterable {
    case system, light, dark
}

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
                if let response = pendingResponse {
                    responseCache[prevId] = response
                } else {
                    responseCache.removeValue(forKey: prevId)
                }
                if let error = lastError {
                    errorCache[prevId] = error
                } else {
                    errorCache.removeValue(forKey: prevId)
                }
            }
            // Restore response for newly selected request
            if let newId = selectedRequest?.id, newId != oldValue?.id {
                pendingResponse = responseCache[newId]
                lastError = errorCache[newId]
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
    @Published var showCreateWorkspace: Bool = false
    @Published var showQuickSearch: Bool = false
    @Published var recentSearchSelections: [RecentSearchItem] = []
    @Published var expandedFolders: Set<UUID> = []
    @Published var scrollToRequestId: UUID? = nil
    @Published var editingEnvironment: Environment? = nil
    @Published var showSettings: Bool = false
    @Published var colorMode: AppColorMode = {
        if let raw = UserDefaults.standard.string(forKey: "appColorMode"),
           let mode = AppColorMode(rawValue: raw) {
            return mode
        }
        return .system
    }() {
        didSet {
            UserDefaults.standard.set(colorMode.rawValue, forKey: "appColorMode")
        }
    }
    /// Response cache — keeps at most 5 entries in memory.
    /// Evicts largest entries first when the limit is exceeded.
    private static let responseCacheLimit = 5
    private var responseCache: [UUID: Response] = [:] {
        didSet {
            if responseCache.count > Self.responseCacheLimit {
                let excess = responseCache.count - Self.responseCacheLimit
                // Evict largest responses first to free the most memory
                let sorted = responseCache.sorted { $0.value.sizeBytes > $1.value.sizeBytes }
                for entry in sorted.prefix(excess) {
                    responseCache.removeValue(forKey: entry.key)
                }
            }
        }
    }
    private var errorCache: [UUID: String] = [:]
    private var systemThemeObserver: NSObjectProtocol?

    /// Always returns an explicit scheme — never nil.
    /// Returning nil from .preferredColorScheme just removes the override
    /// without actively resetting the window appearance, which causes
    /// stale dark colors when switching from Dark → Automatic.
    var preferredScheme: ColorScheme {
        switch colorMode {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return Self.systemColorScheme
        }
    }

    /// Reads the macOS system appearance directly.
    private static var systemColorScheme: ColorScheme {
        UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ? .dark : .light
    }

    /// Call once on app launch to observe system appearance changes.
    func observeSystemAppearance() {
        systemThemeObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.colorMode == .system else { return }
            // Trigger re-render so preferredScheme picks up the new system scheme
            self.objectWillChange.send()
        }
    }

    // MARK: - Workspace helpers

    func loadWorkspaces() {
        workspaces = StorageService.loadWorkspaces()
        selectedWorkspace = workspaces.first
    }

    func saveWorkspaces() {
        try? StorageService.saveWorkspaces(workspaces)
    }

    // MARK: - Recent search

    func addRecentSearch(_ item: RecentSearchItem) {
        recentSearchSelections.removeAll { $0.id == item.id }
        recentSearchSelections.insert(item, at: 0)
        if recentSearchSelections.count > 10 {
            recentSearchSelections.removeLast()
        }
    }

    // MARK: - Navigation helpers

    func revealItem(id: UUID) {
        guard let workspace = selectedWorkspace else { return }
        for collection in workspace.collections {
            var path: [UUID] = []
            if findPathToItem(id: id, items: collection.items, path: &path) {
                for folderId in path {
                    expandedFolders.insert(folderId)
                }
                return
            }
        }
    }

    private func findPathToItem(id: UUID, items: [Item], path: inout [UUID]) -> Bool {
        for item in items {
            switch item {
            case .request(let r):
                if r.id == id { return true }
            case .folder(let f):
                path.append(f.id)
                if f.id == id { return true }
                if findPathToItem(id: id, items: f.items, path: &path) {
                    return true
                }
                path.removeLast()
            }
        }
        return false
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
        if (request.method == .GET || request.method == .HEAD), request.body.mode != .none {
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
        if let response = pendingResponse {
            responseCache[requestId] = response
        } else {
            responseCache.removeValue(forKey: requestId)
        }
        if let error = lastError {
            errorCache[requestId] = error
        } else {
            errorCache.removeValue(forKey: requestId)
        }
    }

    // MARK: - Workspace mutations

    func createWorkspace(name: String = "New Workspace") {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let newWorkspace = Workspace(
            id: UUID(),
            name: trimmed.isEmpty ? "New Workspace" : trimmed,
            collections: []
        )
        workspaces.append(newWorkspace)
        selectedWorkspace = newWorkspace
        saveWorkspaces()
    }

    /// Loads a full request from disk and sets it as the selected request.
    func selectRequest(stub: RequestStub) {
        if let full = StorageService.loadRequest(id: stub.id) {
            selectedRequest = full
        } else {
            // Fallback: create minimal request from stub fields
            let fallback = Request(
                id: stub.id, name: stub.name, method: stub.method, url: stub.url,
                params: [], headers: [], body: .none, auth: .none
            )
            selectedRequest = fallback
            try? StorageService.saveRequest(fallback)
        }
    }

    /// Updates the stub metadata in the workspace tree when a request's name/method/url changes.
    func updateStubInTree(for request: Request) {
        guard let wsIndex = workspaces.firstIndex(where: { $0.id == selectedWorkspace?.id }) else { return }
        let stub = RequestStub(from: request)
        var workspace = workspaces[wsIndex]
        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = updateStubInItems(requestId: request.id, stub: stub, in: col.items)
            return col
        }
        workspaces[wsIndex] = workspace
    }

    private func updateStubInItems(requestId: UUID, stub: RequestStub, in items: [Item]) -> [Item] {
        items.map { item in
            switch item {
            case .request(let s):
                return s.id == requestId ? .request(stub) : item
            case .folder(var f):
                f.items = updateStubInItems(requestId: requestId, stub: stub, in: f.items)
                return .folder(f)
            }
        }
    }

    func importPostmanCollection(folder: Folder, requests: [Request]) {
        guard var workspace = selectedWorkspace,
              let wsIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        // Save all request detail files
        for request in requests {
            try? StorageService.saveRequest(request)
        }

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
        let stub = RequestStub(from: newRequest)

        // Save full request to its own file
        try? StorageService.saveRequest(newRequest)

        if workspace.collections.isEmpty {
            workspace.collections.append(
                Collection(id: UUID(), name: "Requests", items: [.request(stub)])
            )
        } else {
            workspace.collections[0].items.append(.request(stub))
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

        // Save full copy to its own detail file
        try? StorageService.saveRequest(copy)

        let stub = RequestStub(from: copy)
        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = insertAfter(requestId: request.id, newItem: .request(stub), in: col.items)
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
