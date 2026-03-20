import SwiftUI
import AppKit

// MARK: - QuickSearchView

struct QuickSearchView: View {
    @EnvironmentObject var appState: AppState
    @State private var query = ""
    @State private var searchResults: [SearchResult]?
    @State private var selectedIndex = 0
    @State private var searchTask: Task<Void, Never>?
    @State private var keyMonitor: Any?
    @FocusState private var isSearchFocused: Bool
    private let searchService = SidebarSearchService()

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(spacing: 0) {
                searchField
                Divider()
                resultsList
            }
            .frame(width: 500)
            .frame(maxHeight: 400)
            .background(AppColors.canvas)
            .cornerRadius(AppSpacing.radiusPanel)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusPanel)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 4)
            .padding(.top, 100)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            isSearchFocused = true
            selectedIndex = 0
            installKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
        .onExitCommand { close() }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPlaceholder)

            TextField("Search requests...", text: $query)
                .font(AppFonts.body)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .onSubmit { confirmSelection() }

            if !query.isEmpty {
                Button {
                    query = ""
                    searchResults = nil
                    selectedIndex = 0
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPlaceholder)
                }
                .buttonStyle(.plain)
            }

            Text("⌘P")
                .font(AppFonts.eyebrow)
                .foregroundColor(AppColors.textFaint)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, 2)
                .background(AppColors.subtle)
                .cornerRadius(AppSpacing.radiusBadge)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .onChange(of: query) { newValue in
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    searchResults = nil
                } else if let workspace = appState.selectedWorkspace {
                    let results = searchService.search(query: newValue, in: workspace)
                    searchResults = Array(results.prefix(20))
                }
                selectedIndex = 0
            }
        }
    }

    // MARK: - Results list

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if query.trimmingCharacters(in: .whitespaces).isEmpty {
                        recentsList
                    } else if let results = searchResults {
                        if results.isEmpty {
                            emptyResultsView
                        } else {
                            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                                searchResultRow(result, index: index)
                                    .id(index)
                            }
                        }
                    }
                }
            }
            .onChange(of: selectedIndex) { newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    // MARK: - Recents

    private var recentsList: some View {
        Group {
            if appState.recentSearchSelections.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Spacer()
                    Text("Type to search requests, folders, and endpoints")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPlaceholder)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("RECENT")
                        .font(AppFonts.eyebrow)
                        .tracking(AppFonts.eyebrowTracking)
                        .foregroundColor(AppColors.textFaint)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)

                    ForEach(Array(appState.recentSearchSelections.enumerated()), id: \.element.id) { index, item in
                        recentRow(item, index: index)
                            .id(index)
                    }
                }
            }
        }
    }

    private func recentRow(_ item: RecentSearchItem, index: Int) -> some View {
        Button {
            selectRecentItem(item)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if let method = item.method {
                    MethodBadge(method: method)
                } else {
                    Image(systemName: "folder")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 42)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    if let url = item.url, !url.isEmpty {
                        Text(url)
                            .font(AppFonts.eyebrow)
                            .foregroundColor(AppColors.textFaint)
                            .lineLimit(1)
                    }

                    if !item.breadcrumb.isEmpty {
                        Text(item.breadcrumb)
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
            .background(index == selectedIndex ? AppColors.subtle : Color.clear)
            .cornerRadius(AppSpacing.radiusCard)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search result row

    private func searchResultRow(_ result: SearchResult, index: Int) -> some View {
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
            .background(index == selectedIndex ? AppColors.subtle : Color.clear)
            .cornerRadius(AppSpacing.radiusCard)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyResultsView: some View {
        VStack(spacing: AppSpacing.sm) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundColor(AppColors.textFaint)
            Text("No results found")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }

    // MARK: - Highlighting

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

    // MARK: - Actions

    private func selectSearchResult(_ result: SearchResult) {
        navigateToItem(id: result.id, isRequest: result.method != nil)

        appState.addRecentSearch(RecentSearchItem(
            id: result.id,
            name: result.name,
            url: result.url,
            method: result.method,
            breadcrumb: result.breadcrumb
        ))

        close()
    }

    private func selectRecentItem(_ item: RecentSearchItem) {
        navigateToItem(id: item.id, isRequest: item.method != nil)
        appState.addRecentSearch(item)
        close()
    }

    private func navigateToItem(id: UUID, isRequest: Bool) {
        guard let workspace = appState.selectedWorkspace else { return }

        // Expand parent folders
        appState.revealItem(id: id)

        if isRequest {
            if let request = findRequest(id: id, in: workspace) {
                appState.selectedRequest = request
            }
            // Trigger scroll in sidebar
            appState.scrollToRequestId = id
        } else {
            appState.expandedFolders.insert(id)
        }
    }

    private func confirmSelection() {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            // Selecting from recents
            let recents = appState.recentSearchSelections
            guard selectedIndex < recents.count else { return }
            selectRecentItem(recents[selectedIndex])
        } else if let results = searchResults {
            guard selectedIndex < results.count else { return }
            selectSearchResult(results[selectedIndex])
        }
    }

    private var currentItemCount: Int {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return appState.recentSearchSelections.count
        }
        return searchResults?.count ?? 0
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.specialKey {
            case .downArrow:
                let count = currentItemCount
                if count > 0 {
                    selectedIndex = min(selectedIndex + 1, count - 1)
                }
                return nil
            case .upArrow:
                selectedIndex = max(selectedIndex - 1, 0)
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func close() {
        removeKeyMonitor()
        appState.showQuickSearch = false
    }

    // MARK: - Find request

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
}
