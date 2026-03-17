import SwiftUI

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var selectedWorkspace: Workspace? = nil {
        didSet {
            // Restore per-workspace environment when switching workspaces
            if oldValue?.id != selectedWorkspace?.id {
                if let envId = selectedWorkspace?.activeEnvironmentId {
                    activeEnvironment = environments.first { $0.id == envId }
                } else {
                    activeEnvironment = nil
                }
            }
        }
    }
    @Published var selectedRequest: Request? = nil
    @Published var activeEnvironment: Environment? = nil {
        didSet {
            // Persist environment selection to the current workspace
            guard oldValue?.id != activeEnvironment?.id,
                  var workspace = selectedWorkspace,
                  let wsIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }
            workspace.activeEnvironmentId = activeEnvironment?.id
            workspaces[wsIndex] = workspace
            selectedWorkspace = workspace
        }
    }
    @Published var environments: [Environment] = []
    @Published var pendingResponse: Response? = nil
    @Published var isLoading: Bool = false
    @Published var showEnvEditor: Bool = false
    @Published var editingEnvironment: Environment? = nil

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
}
