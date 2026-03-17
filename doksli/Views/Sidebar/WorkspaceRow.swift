import SwiftUI

// MARK: - WorkspaceRow

struct WorkspaceRow: View {
    @EnvironmentObject var appState: AppState
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var isConfirmingDelete = false

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            workspaceMenu

            actionsMenu
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .alert("Rename Workspace", isPresented: $isRenaming) {
            TextField("Workspace name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("OK") {
                renameSelectedWorkspace()
            }
        }
        .alert("Delete Workspace", isPresented: $isConfirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSelectedWorkspace()
            }
        } message: {
            Text("Are you sure you want to delete \"\(appState.selectedWorkspace?.name ?? "")\"? This action cannot be undone.")
        }
    }

    // MARK: - Workspace selector dropdown (selection only)

    private var workspaceMenu: some View {
        Menu {
            ForEach(appState.workspaces) { workspace in
                Button(workspace.name) {
                    appState.selectedWorkspace = workspace
                }
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)

                Text(appState.selectedWorkspace?.name ?? "No Workspace")
                    .font(AppFonts.title)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    // MARK: - Three-dots actions menu

    private var actionsMenu: some View {
        Menu {
            Button {
                createWorkspace()
            } label: {
                Label("New Workspace", systemImage: "plus")
            }

            if appState.selectedWorkspace != nil {
                Divider()

                Button {
                    renameText = appState.selectedWorkspace?.name ?? ""
                    isRenaming = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    // MARK: - Actions

    private func createWorkspace() {
        let newWorkspace = Workspace(
            id: UUID(),
            name: "New Workspace",
            collections: []
        )
        appState.workspaces.append(newWorkspace)
        appState.selectedWorkspace = newWorkspace
    }

    private func renameSelectedWorkspace() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let selected = appState.selectedWorkspace,
              let index = appState.workspaces.firstIndex(where: { $0.id == selected.id }) else {
            return
        }
        appState.workspaces[index].name = trimmed
        appState.selectedWorkspace = appState.workspaces[index]
    }

    private func deleteSelectedWorkspace() {
        guard let selected = appState.selectedWorkspace else { return }
        appState.workspaces.removeAll { $0.id == selected.id }
        appState.selectedWorkspace = appState.workspaces.first
        appState.selectedRequest = nil
    }
}
