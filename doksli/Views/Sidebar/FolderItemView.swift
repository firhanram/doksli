import SwiftUI
import UniformTypeIdentifiers

/// Extracted from SidebarView to break the recursive opaque-type chain
/// that crashes the Swift compiler under -O optimization.
///
/// SidebarView.itemRow → FolderItemView (struct boundary) → FolderItemView.childItemRow → FolderItemView
/// Each struct resolves `some View` independently, preventing infinite type expansion.
struct FolderItemView: View {
    let folder: Folder
    @EnvironmentObject var appState: AppState
    @Binding var draggedItemId: UUID?

    // Closures that trigger alerts owned by SidebarView
    var onRenameRequest: (RequestStub) -> Void
    var onDuplicateRequest: (RequestStub) -> Void
    var onConfirmDelete: (_ requestId: UUID?, _ folderId: UUID?, _ name: String) -> Void
    var onRenameFolder: (Folder) -> Void
    var onAddRequestInFolder: (Folder, HTTPMethod) -> Void

    var body: some View {
        let isExpanded = Binding<Bool>(
            get: { appState.expandedFolders.contains(folder.id) },
            set: { newValue in
                if newValue { appState.expandedFolders.insert(folder.id) }
                else { appState.expandedFolders.remove(folder.id) }
            }
        )
        VStack(spacing: 0) {
            DisclosureGroup(isExpanded: isExpanded) {
                VStack(spacing: 2) {
                    ForEach(Array(folder.items.enumerated()), id: \.offset) { _, child in
                        childItemRow(child)
                    }
                }
                .padding(.leading, AppSpacing.sm)
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    FolderRow(folder: folder)
                    Spacer()
                    folderActionsMenu
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isExpanded.wrappedValue.toggle()
                }
                .contextMenu { folderContextMenu }
            }
        }
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers: providers, targetFolderId: folder.id)
        }
        .padding(.leading, AppSpacing.sm)
        .background(alignment: .leading) {
            if isExpanded.wrappedValue {
                Rectangle()
                    .fill(AppColors.muted)
                    .frame(width: 1)
                    .padding(.top, 28)
                    .padding(.leading, 11)
            }
        }
    }

    // MARK: - Child item rendering

    @ViewBuilder
    private func childItemRow(_ item: Item) -> some View {
        switch item {
        case .folder(let childFolder):
            FolderItemView(
                folder: childFolder,
                draggedItemId: $draggedItemId,
                onRenameRequest: onRenameRequest,
                onDuplicateRequest: onDuplicateRequest,
                onConfirmDelete: onConfirmDelete,
                onRenameFolder: onRenameFolder,
                onAddRequestInFolder: onAddRequestInFolder
            )

        case .request(let stub):
            RequestRow(
                stub: stub,
                isActive: appState.selectedRequest?.id == stub.id
            )
            .contentShape(Rectangle())
            .onTapGesture {
                appState.selectRequest(stub: stub)
            }
            .contextMenu { requestContextMenu(stub) }
            .onDrag {
                draggedItemId = stub.id
                return NSItemProvider(object: stub.id.uuidString as NSString)
            }
            .padding(.leading, AppSpacing.lg)
            .id(stub.id)
        }
    }

    // MARK: - Context menus

    @ViewBuilder
    private func requestContextMenu(_ stub: RequestStub) -> some View {
        Button {
            onRenameRequest(stub)
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Button {
            onDuplicateRequest(stub)
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }

        Divider()

        Button(role: .destructive) {
            onConfirmDelete(stub.id, nil, stub.name)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    @ViewBuilder
    private var folderContextMenu: some View {
        Button {
            onRenameFolder(folder)
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Menu {
            ForEach([HTTPMethod.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS, .HEAD], id: \.self) { method in
                Button(method.rawValue) {
                    onAddRequestInFolder(folder, method)
                }
            }
        } label: {
            Label("New Request", systemImage: "plus")
        }

        Divider()

        Button(role: .destructive) {
            onConfirmDelete(nil, folder.id, folder.name)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private var folderActionsMenu: some View {
        Menu {
            Button {
                onRenameFolder(folder)
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Menu {
                ForEach([HTTPMethod.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS, .HEAD], id: \.self) { method in
                    Button(method.rawValue) {
                        onAddRequestInFolder(folder, method)
                    }
                }
            } label: {
                Label("New Request", systemImage: "plus")
            }

            Divider()

            Button(role: .destructive) {
                onConfirmDelete(nil, folder.id, folder.name)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    // MARK: - Drag and drop

    private func handleDrop(providers: [NSItemProvider], targetFolderId: UUID) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, _ in
            guard let data = data as? Data,
                  let uuidString = String(data: data, encoding: .utf8),
                  let itemId = UUID(uuidString: uuidString) else { return }

            DispatchQueue.main.async {
                moveItemToFolder(itemId: itemId, targetFolderId: targetFolderId)
            }
        }
        return true
    }

    private func moveItemToFolder(itemId: UUID, targetFolderId: UUID) {
        guard var workspace = appState.selectedWorkspace,
              let wsIndex = appState.workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        if itemId == targetFolderId { return }

        var extractedItem: Item?
        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = SidebarTreeHelpers.extractItem(itemId: itemId, from: col.items, extracted: &extractedItem)
            return col
        }

        guard let item = extractedItem else { return }

        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = SidebarTreeHelpers.insertIntoFolder(folderId: targetFolderId, item: item, in: col.items)
            return col
        }

        appState.workspaces[wsIndex] = workspace
        appState.selectedWorkspace = workspace
        appState.expandedFolders.insert(targetFolderId)
        appState.saveWorkspaces()
        draggedItemId = nil
    }
}
