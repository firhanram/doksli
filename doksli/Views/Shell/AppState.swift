import SwiftUI

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var selectedWorkspace: Workspace? = nil
    @Published var selectedRequest: Request? = nil
    @Published var activeEnvironment: Environment? = nil
    @Published var environments: [Environment] = []
    @Published var pendingResponse: Response? = nil
    @Published var isLoading: Bool = false
    @Published var showEnvEditor: Bool = false
    @Published var editingEnvironment: Environment? = nil

    // MARK: - Environment helpers

    func loadEnvironments() {
        environments = StorageService.loadEnvironments()
    }

    func saveEnvironments() {
        try? StorageService.saveEnvironments(environments)
    }
}
