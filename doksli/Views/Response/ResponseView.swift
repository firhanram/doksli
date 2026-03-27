import SwiftUI

// MARK: - ResponseTab

enum ResponseTab: Hashable {
    case body
    case headers
    case raw

    var label: String {
        switch self {
        case .body: return "Body"
        case .headers: return "Headers"
        case .raw: return "Raw"
        }
    }
}

// MARK: - ResponseView

struct ResponseView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeTab: ResponseTab = .body
    @State private var jsonExpandedPaths: Set<String> = [""]

    // Search state
    @State private var isSearchVisible: Bool = false
    @State private var searchQuery: String = ""
    @State private var searchMatches: [JSONSearchMatch] = []
    @State private var currentMatchIndex: Int = 0
    @State private var savedExpandedPaths: Set<String>? = nil
    @State private var cachedAllRows: [JSONRow] = []
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var scrollToPath: String? = nil
    @State private var cmdFMonitor: Any?

    var body: some View {
        Group {
            if appState.isLoading {
                loadingView
            } else if let response = appState.pendingResponse {
                responseContent(response)
            } else if let error = appState.lastError {
                errorView(error)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.canvas)
        .onChange(of: appState.pendingResponse) { _ in
            jsonExpandedPaths = [""]
            closeSearch()
            cacheAllRows()
        }
        .onChange(of: searchQuery) { newQuery in
            performSearch(query: newQuery)
        }
        .onAppear { installCmdFMonitor() }
        .onDisappear { removeCmdFMonitor() }
    }

    // MARK: - Response content

    private func responseContent(_ response: Response) -> some View {
        VStack(spacing: 0) {
            StatsBarView(response: response)

            TabBarView(
                tabs: [ResponseTab.body, .headers, .raw],
                activeTab: $activeTab,
                label: { $0.label }
            )

            tabContent(response)
        }
    }

    // MARK: - Tab content

    @ViewBuilder
    private func tabContent(_ response: Response) -> some View {
        switch activeTab {
        case .body:
            if isJSONResponse(response) {
                ZStack(alignment: .topTrailing) {
                    JSONTreeView(
                        data: response.body,
                        expandedPaths: $jsonExpandedPaths,
                        searchQuery: isSearchVisible ? searchQuery : "",
                        currentMatchPath: currentMatchPath,
                        scrollToPath: scrollToPath
                    )

                    if isSearchVisible {
                        JSONSearchBar(
                            query: $searchQuery,
                            matchCount: searchMatches.count,
                            currentIndex: currentMatchIndex,
                            onNext: navigateNext,
                            onPrevious: navigatePrevious,
                            onClose: closeSearch
                        )
                        .padding(.top, AppSpacing.sm)
                        .padding(.trailing, AppSpacing.md)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            } else {
                RawBodyView(data: response.body)
            }
        case .headers:
            HeadersListView(headers: response.headers)
        case .raw:
            RawBodyView(data: response.body)
        }
    }

    // MARK: - Current match path

    private var currentMatchPath: String? {
        guard !searchMatches.isEmpty, currentMatchIndex < searchMatches.count else { return nil }
        return searchMatches[currentMatchIndex].rowPath
    }

    // MARK: - Search logic

    private func performSearch(query: String) {
        searchTask?.cancel()

        guard !query.isEmpty else {
            searchMatches = []
            currentMatchIndex = 0
            restoreExpandedPaths()
            scrollToPath = nil
            return
        }

        searchTask = Task {
            // Debounce 200ms
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }

            let lowerQuery = query.lowercased()
            var matches: [JSONSearchMatch] = []
            var matchId = 0

            for row in cachedAllRows {
                // Search in key
                if let key = row.key {
                    let lowerKey = key.lowercased()
                    var searchStart = lowerKey.startIndex
                    while searchStart < lowerKey.endIndex,
                          let range = lowerKey.range(of: lowerQuery, range: searchStart..<lowerKey.endIndex) {
                        matches.append(JSONSearchMatch(id: matchId, rowPath: row.path, field: .key, range: range))
                        matchId += 1
                        searchStart = range.upperBound
                    }
                }

                // Search in value
                let val = row.valueText
                if !val.isEmpty {
                    let lowerVal = val.lowercased()
                    var searchStart = lowerVal.startIndex
                    while searchStart < lowerVal.endIndex,
                          let range = lowerVal.range(of: lowerQuery, range: searchStart..<lowerVal.endIndex) {
                        matches.append(JSONSearchMatch(id: matchId, rowPath: row.path, field: .value, range: range))
                        matchId += 1
                        searchStart = range.upperBound
                    }
                }
            }

            guard !Task.isCancelled else { return }

            searchMatches = matches
            currentMatchIndex = 0

            if !matches.isEmpty {
                expandToMatches(matches)
                scrollToCurrentMatch()
            }
        }
    }

    private func cacheAllRows() {
        guard let response = appState.pendingResponse,
              isJSONResponse(response),
              let parsed = try? JSONSerialization.jsonObject(with: response.body, options: [.fragmentsAllowed]) else {
            cachedAllRows = []
            return
        }
        cachedAllRows = computeAllRows(parsed)
    }

    // MARK: - Auto-expand ancestors

    private func expandToMatches(_ matches: [JSONSearchMatch]) {
        if savedExpandedPaths == nil {
            savedExpandedPaths = jsonExpandedPaths
        }

        var pathsToExpand = jsonExpandedPaths
        for match in matches {
            let ancestors = ancestorPaths(of: match.rowPath)
            for ancestor in ancestors {
                pathsToExpand.insert(ancestor)
            }
        }
        jsonExpandedPaths = pathsToExpand
    }

    private func ancestorPaths(of path: String) -> [String] {
        guard !path.isEmpty else { return [] }
        var ancestors: [String] = [""]
        let components = path.split(separator: ".")
        for i in 0..<(components.count - 1) {
            ancestors.append(components[0...i].joined(separator: "."))
        }
        return ancestors
    }

    private func restoreExpandedPaths() {
        if let saved = savedExpandedPaths {
            jsonExpandedPaths = saved
            savedExpandedPaths = nil
        }
    }

    // MARK: - Navigation

    private func navigateNext() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % searchMatches.count
        scrollToCurrentMatch()
    }

    private func navigatePrevious() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + searchMatches.count) % searchMatches.count
        scrollToCurrentMatch()
    }

    private func scrollToCurrentMatch() {
        guard !searchMatches.isEmpty, currentMatchIndex < searchMatches.count else { return }
        let path = searchMatches[currentMatchIndex].rowPath
        // Force a change even if same path (for re-scroll)
        scrollToPath = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            scrollToPath = path
        }
    }

    // MARK: - Close search

    private func closeSearch() {
        isSearchVisible = false
        searchQuery = ""
        searchMatches = []
        currentMatchIndex = 0
        scrollToPath = nil
        restoreExpandedPaths()
    }

    // MARK: - Cmd+F monitor

    private func installCmdFMonitor() {
        cmdFMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Cmd+F
            if event.keyCode == 3 && event.modifierFlags.contains(.command) {
                if activeTab == .body, appState.pendingResponse != nil {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearchVisible = true
                    }
                    if cachedAllRows.isEmpty {
                        cacheAllRows()
                    }
                    return nil
                }
            }
            return event
        }
    }

    private func removeCmdFMonitor() {
        if let monitor = cmdFMonitor {
            NSEvent.removeMonitor(monitor)
            cmdFMonitor = nil
        }
    }

    // MARK: - JSON detection

    private func isJSONResponse(_ response: Response) -> Bool {
        if let contentType = response.headers.first(where: {
            $0.key.lowercased() == "content-type"
        }) {
            return contentType.value.lowercased().contains("json")
        }
        // Try parsing as JSON as fallback
        return (try? JSONSerialization.jsonObject(with: response.body)) != nil
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "paperplane")
                .font(.system(size: 32))
                .foregroundColor(AppColors.textPlaceholder)
            Text("Send a request to see the response")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPlaceholder)
        }
    }

    // MARK: - Error state

    private func errorView(_ message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(AppColors.errorText)
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(AppColors.errorText)
                .multilineTextAlignment(.center)

            Button {
                appState.sendCurrentRequest()
            } label: {
                Text("Retry")
                    .font(AppFonts.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.brand)
                    .cornerRadius(AppSpacing.radiusBadge)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.xl)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .controlSize(.small)
            Text("Sending request…")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
        }
    }
}
