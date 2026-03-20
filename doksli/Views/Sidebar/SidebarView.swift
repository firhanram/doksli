import SwiftUI
import UniformTypeIdentifiers

// MARK: - SidebarView

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @State private var isRenamingRequest = false
    @State private var isRenamingFolder = false
    @State private var renameText = ""
    @State private var renamingRequestId: UUID?
    @State private var renamingFolderId: UUID?
    @State private var isConfirmingDelete = false
    @State private var deletingRequestId: UUID?
    @State private var deletingFolderId: UUID?
    @State private var deletingItemName = ""
    @State private var expandedFolders: Set<UUID> = []
    @State private var draggedItemId: UUID?
    @State private var showImportError = false
    @State private var importError = ""
    @State private var searchQuery = ""
    @State private var searchResults: [SearchResult]?
    @State private var searchTask: Task<Void, Never>?
    private let searchService = SidebarSearchService()

    var body: some View {
        VStack(spacing: 0) {
            WorkspaceRow()

            Divider()
                .foregroundColor(AppColors.subtle)

            if appState.selectedWorkspace != nil {
                searchBar

                Divider()
                    .foregroundColor(AppColors.subtle)
            }

            Group {
                if let workspace = appState.selectedWorkspace {
                    if !searchQuery.isEmpty, let results = searchResults {
                        searchResultsList(results)
                    } else {
                        collectionsTree(workspace)
                    }
                } else {
                    emptyState
                }
            }
            .frame(maxHeight: .infinity)

        }
        .background(AppColors.surface)
        .contextMenu { sidebarContextMenu }
        .alert("Rename Request", isPresented: $isRenamingRequest) {
            TextField("Request name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("OK") { applyRenameRequest() }
        }
        .alert("Rename Folder", isPresented: $isRenamingFolder) {
            TextField("Folder name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("OK") { applyRenameFolder() }
        }
        .alert("Import Error", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError)
        }
        .alert("Delete \"\(deletingItemName)\"", isPresented: $isConfirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteItem(requestId: deletingRequestId, folderId: deletingFolderId)
                deletingRequestId = nil
                deletingFolderId = nil
            }
        } message: {
            Text("Are you sure you want to delete \"\(deletingItemName)\"? This action cannot be undone.")
        }
    }

    // MARK: - Collections tree

    private func collectionsTree(_ workspace: Workspace) -> some View {
        let nonEmpty = workspace.collections.filter { !$0.items.isEmpty }
        return Group {
            if nonEmpty.isEmpty {
                emptyCollectionsState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(nonEmpty) { collection in
                            collectionSection(collection)
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
            }
        }
        .contextMenu { workspaceContextMenu }
    }

    @ViewBuilder
    private var sidebarContextMenu: some View {
        Button {
            createWorkspace()
        } label: {
            Label("New Workspace", systemImage: "plus")
        }

        if appState.selectedWorkspace != nil {
            Divider()

            Menu {
                ForEach([HTTPMethod.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS, .HEAD], id: \.self) { method in
                    Button(method.rawValue) {
                        appState.addNewRequest(method: method)
                    }
                }
            } label: {
                Label("New Request", systemImage: "plus")
            }

            Button {
                appState.addNewFolder()
            } label: {
                Label("New Folder", systemImage: "folder.badge.plus")
            }
        }
    }

    @ViewBuilder
    private var workspaceContextMenu: some View {
        Menu {
            ForEach([HTTPMethod.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS, .HEAD], id: \.self) { method in
                Button(method.rawValue) {
                    appState.addNewRequest(method: method)
                }
            }
        } label: {
            Label("New Request", systemImage: "plus")
        }

        Button {
            appState.addNewFolder()
        } label: {
            Label("New Folder", systemImage: "folder.badge.plus")
        }

        Divider()

        Button {
            importPostmanCollection()
        } label: {
            Label("Import Postman Collection", systemImage: "square.and.arrow.down")
        }
    }

    private func collectionSection(_ collection: Collection) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(collection.name.uppercased())
                .font(AppFonts.eyebrow)
                .tracking(AppFonts.eyebrowTracking)
                .foregroundColor(AppColors.textFaint)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)

            ForEach(Array(collection.items.enumerated()), id: \.offset) { _, item in
                itemRow(item)
            }
        }
    }

    // MARK: - Recursive item rendering

    private func itemRow(_ item: Item) -> AnyView {
        switch item {
        case .folder(let folder):
            let isExpanded = Binding<Bool>(
                get: { expandedFolders.contains(folder.id) },
                set: { newValue in
                    if newValue { expandedFolders.insert(folder.id) }
                    else { expandedFolders.remove(folder.id) }
                }
            )
            return AnyView(
                VStack(spacing: 0) {
                    DisclosureGroup(isExpanded: isExpanded) {
                        VStack(spacing: 2) {
                            ForEach(Array(folder.items.enumerated()), id: \.offset) { _, child in
                                itemRow(child)
                            }
                        }
                        .padding(.leading, AppSpacing.sm)
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            FolderRow(folder: folder)
                            Spacer()
                            folderActionsMenu(folder)
                        }
                        .contextMenu { folderContextMenu(folder) }
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
            )

        case .request(let request):
            return AnyView(
                RequestRow(
                    request: request,
                    isActive: appState.selectedRequest?.id == request.id
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    appState.selectedRequest = request
                }
                .contextMenu { requestContextMenu(request) }
                .onDrag {
                    draggedItemId = request.id
                    return NSItemProvider(object: request.id.uuidString as NSString)
                }
                .padding(.leading, AppSpacing.lg)
            )
        }
    }

    // MARK: - Context menus

    @ViewBuilder
    private func requestContextMenu(_ request: Request) -> some View {
        Button {
            renameRequest(request)
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Button {
            duplicateRequest(request)
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }

        Divider()

        Button(role: .destructive) {
            confirmDelete(requestId: request.id, name: request.name)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    @ViewBuilder
    private func folderContextMenu(_ folder: Folder) -> some View {
        Button {
            renameFolder(folder)
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Menu {
            ForEach([HTTPMethod.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS, .HEAD], id: \.self) { method in
                Button(method.rawValue) {
                    addRequestInFolder(folder, method: method)
                }
            }
        } label: {
            Label("New Request", systemImage: "plus")
        }

        Divider()

        Button(role: .destructive) {
            confirmDelete(folderId: folder.id, name: folder.name)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func folderActionsMenu(_ folder: Folder) -> some View {
        Menu {
            Button {
                renameFolder(folder)
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Menu {
                ForEach([HTTPMethod.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS, .HEAD], id: \.self) { method in
                    Button(method.rawValue) {
                        addRequestInFolder(folder, method: method)
                    }
                }
            } label: {
                Label("New Request", systemImage: "plus")
            }

            Divider()

            Button(role: .destructive) {
                confirmDelete(folderId: folder.id, name: folder.name)
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

    // MARK: - Context menu actions

    private func duplicateRequest(_ request: Request) {
        guard var workspace = appState.selectedWorkspace,
              let wsIndex = appState.workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        var copy = request
        copy.id = UUID()
        copy.name = "\(request.name) (Copy)"

        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = insertAfter(requestId: request.id, newItem: .request(copy), in: col.items)
            return col
        }

        appState.workspaces[wsIndex] = workspace
        appState.selectedWorkspace = workspace
        appState.saveWorkspaces()
    }

    private func confirmDelete(requestId: UUID? = nil, folderId: UUID? = nil, name: String) {
        deletingRequestId = requestId
        deletingFolderId = folderId
        deletingItemName = name
        isConfirmingDelete = true
    }

    private func deleteItem(requestId: UUID? = nil, folderId: UUID? = nil) {
        guard var workspace = appState.selectedWorkspace,
              let wsIndex = appState.workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = removeItem(requestId: requestId, folderId: folderId, from: col.items)
            return col
        }

        if let rid = requestId, appState.selectedRequest?.id == rid {
            appState.selectedRequest = nil
        }

        appState.workspaces[wsIndex] = workspace
        appState.selectedWorkspace = workspace
        appState.saveWorkspaces()
    }

    private func addRequestInFolder(_ folder: Folder, method: HTTPMethod = .GET) {
        guard var workspace = appState.selectedWorkspace,
              let wsIndex = appState.workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        let newRequest = Request(
            id: UUID(), name: "New Request", method: method, url: "",
            params: [], headers: [], body: .none, auth: .none
        )

        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = addToFolder(folderId: folder.id, newItem: .request(newRequest), in: col.items)
            return col
        }

        appState.workspaces[wsIndex] = workspace
        appState.selectedWorkspace = workspace
        appState.selectedRequest = newRequest
        expandedFolders.insert(folder.id)
        appState.saveWorkspaces()
    }

    private func renameRequest(_ request: Request) {
        renamingRequestId = request.id
        renameText = request.name
        isRenamingRequest = true
    }

    private func renameFolder(_ folder: Folder) {
        renamingFolderId = folder.id
        renameText = folder.name
        isRenamingFolder = true
    }

    private func applyRenameRequest() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let rid = renamingRequestId,
              var workspace = appState.selectedWorkspace,
              let wsIndex = appState.workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = renameRequestInItems(requestId: rid, newName: trimmed, in: col.items)
            return col
        }

        appState.workspaces[wsIndex] = workspace
        appState.selectedWorkspace = workspace
        if appState.selectedRequest?.id == rid {
            appState.selectedRequest?.name = trimmed
        }
        appState.saveWorkspaces()
    }

    private func applyRenameFolder() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let fid = renamingFolderId,
              var workspace = appState.selectedWorkspace,
              let wsIndex = appState.workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }

        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = renameFolderInItems(folderId: fid, newName: trimmed, in: col.items)
            return col
        }

        appState.workspaces[wsIndex] = workspace
        appState.selectedWorkspace = workspace
        appState.saveWorkspaces()
    }

    private func renameRequestInItems(requestId: UUID, newName: String, in items: [Item]) -> [Item] {
        items.map { item in
            switch item {
            case .request(var r):
                if r.id == requestId { r.name = newName }
                return .request(r)
            case .folder(var f):
                f.items = renameRequestInItems(requestId: requestId, newName: newName, in: f.items)
                return .folder(f)
            }
        }
    }

    private func renameFolderInItems(folderId: UUID, newName: String, in items: [Item]) -> [Item] {
        items.map { item in
            switch item {
            case .request:
                return item
            case .folder(var f):
                if f.id == folderId { f.name = newName }
                f.items = renameFolderInItems(folderId: folderId, newName: newName, in: f.items)
                return .folder(f)
            }
        }
    }

    // MARK: - Tree mutation helpers

    private func removeItem(requestId: UUID?, folderId: UUID?, from items: [Item]) -> [Item] {
        items.compactMap { item in
            switch item {
            case .request(let r):
                if let rid = requestId, r.id == rid { return nil }
                return item
            case .folder(let f):
                if let fid = folderId, f.id == fid { return nil }
                var folder = f
                folder.items = removeItem(requestId: requestId, folderId: folderId, from: f.items)
                return .folder(folder)
            }
        }
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

    private func addToFolder(folderId: UUID, newItem: Item, in items: [Item]) -> [Item] {
        items.map { item in
            switch item {
            case .folder(let f):
                var folder = f
                if f.id == folderId {
                    folder.items.append(newItem)
                } else {
                    folder.items = addToFolder(folderId: folderId, newItem: newItem, in: f.items)
                }
                return .folder(folder)
            case .request:
                return item
            }
        }
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

        // Don't drop a folder into itself
        if itemId == targetFolderId { return }

        // Find and extract the item
        var extractedItem: Item?
        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = extractItem(itemId: itemId, from: col.items, extracted: &extractedItem)
            return col
        }

        guard let item = extractedItem else { return }

        // Insert into target folder
        workspace.collections = workspace.collections.map { collection in
            var col = collection
            col.items = insertIntoFolder(folderId: targetFolderId, item: item, in: col.items)
            return col
        }

        appState.workspaces[wsIndex] = workspace
        appState.selectedWorkspace = workspace
        expandedFolders.insert(targetFolderId)
        appState.saveWorkspaces()
        draggedItemId = nil
    }

    private func extractItem(itemId: UUID, from items: [Item], extracted: inout Item?) -> [Item] {
        items.compactMap { item in
            switch item {
            case .request(let r):
                if r.id == itemId {
                    extracted = item
                    return nil
                }
                return item
            case .folder(var f):
                if f.id == itemId {
                    extracted = item
                    return nil
                }
                f.items = extractItem(itemId: itemId, from: f.items, extracted: &extracted)
                return .folder(f)
            }
        }
    }

    private func insertIntoFolder(folderId: UUID, item: Item, in items: [Item]) -> [Item] {
        items.map { existing in
            switch existing {
            case .folder(var f):
                if f.id == folderId {
                    f.items.append(item)
                } else {
                    f.items = insertIntoFolder(folderId: folderId, item: item, in: f.items)
                }
                return .folder(f)
            case .request:
                return existing
            }
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPlaceholder)

            TextField("Search...", text: $searchQuery)
                .font(AppFonts.body)
                .textFieldStyle(.plain)

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    searchResults = nil
                    searchService.clearCache()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPlaceholder)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surfacePlus)
        .cornerRadius(AppSpacing.radiusInput)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .onChange(of: searchQuery) { newValue in
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                    searchResults = nil
                } else if let workspace = appState.selectedWorkspace {
                    searchResults = searchService.search(query: newValue, in: workspace)
                }
            }
        }
    }

    private func searchResultsList(_ results: [SearchResult]) -> some View {
        Group {
            if results.isEmpty {
                VStack(spacing: AppSpacing.md) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.title)
                        .foregroundColor(AppColors.textFaint)
                    Text("No results found")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textTertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(results) { result in
                            searchResultRow(result)
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
            }
        }
    }

    private func searchResultRow(_ result: SearchResult) -> some View {
        Button {
            selectSearchResult(result)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if let method = result.method {
                    MethodBadge(method: method)
                } else {
                    Image(systemName: "folder")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 42)
                }

                VStack(alignment: .leading, spacing: 2) {
                    if result.matchedField == .name {
                        highlightedText(result.name, matchedIndices: Set(result.matchedIndices))
                            .font(AppFonts.body)
                            .lineLimit(1)
                        if let url = result.url, !url.isEmpty {
                            Text(url)
                                .font(AppFonts.eyebrow)
                                .foregroundColor(AppColors.textFaint)
                                .lineLimit(1)
                        }
                    } else {
                        Text(result.name)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)
                        if let url = result.url {
                            highlightedText(url, matchedIndices: Set(result.matchedIndices))
                                .font(AppFonts.eyebrow)
                                .lineLimit(1)
                        }
                    }

                    if !result.breadcrumb.isEmpty {
                        Text(result.breadcrumb)
                            .font(AppFonts.eyebrow)
                            .foregroundColor(AppColors.textPlaceholder)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(appState.selectedRequest?.id == result.id ? AppColors.subtle : Color.clear)
            .cornerRadius(AppSpacing.radiusCard)
        }
        .buttonStyle(.plain)
    }

    private func highlightedText(_ text: String, matchedIndices: Set<Int>) -> Text {
        var result = Text("")
        for (i, char) in text.enumerated() {
            if matchedIndices.contains(i) {
                result = result + Text(String(char))
                    .foregroundColor(AppColors.brand)
                    .bold()
            } else {
                result = result + Text(String(char))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        return result
    }

    private func selectSearchResult(_ result: SearchResult) {
        // Find the request in the workspace tree
        guard let workspace = appState.selectedWorkspace else { return }

        if result.method != nil {
            // It's a request — find and select it
            let request = findRequest(id: result.id, in: workspace)
            if let request = request {
                appState.selectedRequest = request
            }
        } else {
            // It's a folder — expand it
            expandedFolders.insert(result.id)
        }

        // Expand parent folders so the item is visible
        expandParentFolders(for: result.id, in: workspace)

        // Clear search
        searchQuery = ""
        searchResults = nil
    }

    private func findRequest(id: UUID, in workspace: Workspace) -> Request? {
        for collection in workspace.collections {
            if let found = findRequestInItems(id: id, items: collection.items) {
                return found
            }
        }
        return nil
    }

    private func findRequestInItems(id: UUID, items: [Item]) -> Request? {
        for item in items {
            switch item {
            case .request(let r):
                if r.id == id { return r }
            case .folder(let f):
                if let found = findRequestInItems(id: id, items: f.items) {
                    return found
                }
            }
        }
        return nil
    }

    private func expandParentFolders(for itemId: UUID, in workspace: Workspace) {
        for collection in workspace.collections {
            var path: [UUID] = []
            if findPathToItem(id: itemId, items: collection.items, path: &path) {
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

    // MARK: - Empty states

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "tray")
                .font(.title)
                .foregroundColor(AppColors.textFaint)
            Text("No workspace selected")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
            Text("Press ⌘⇧W to create one")
                .font(AppFonts.eyebrow)
                .foregroundColor(AppColors.textPlaceholder)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyCollectionsState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title)
                .foregroundColor(AppColors.textFaint)
            Text("No requests yet")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
            Text("Press ⌘N to create one")
                .font(AppFonts.eyebrow)
                .foregroundColor(AppColors.textPlaceholder)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    private func methodColor(_ method: HTTPMethod) -> MethodColor {
        switch method {
        case .GET:     return AppColors.methodGet
        case .POST:    return AppColors.methodPost
        case .PUT:     return AppColors.methodPut
        case .DELETE:  return AppColors.methodDelete
        case .PATCH:   return AppColors.methodPatch
        case .OPTIONS: return AppColors.methodOptions
        case .HEAD:    return AppColors.methodHead
        }
    }

    private func createWorkspace() {
        appState.showCreateWorkspace = true
    }

    private func importPostmanCollection() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a Postman collection JSON file"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let folder = try PostmanImporter.importCollection(from: url)
            appState.importPostmanFolder(folder)
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
    }


}
