import SwiftUI

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var selectedWorkspace: Workspace? = nil
    @Published var selectedRequest: Request? = nil
    @Published var activeEnvironment: Environment? = nil
    @Published var pendingResponse: Response? = nil
    @Published var isLoading: Bool = false
}
