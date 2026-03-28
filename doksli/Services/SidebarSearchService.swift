import Foundation

// MARK: - MatchedField

enum MatchedField {
    case name
    case url
}

// MARK: - SearchResult

struct SearchResult: Identifiable {
    let id: UUID
    let name: String
    let url: String?
    let method: HTTPMethod?
    let score: Int
    let matchedIndices: [Int]
    let matchedField: MatchedField
    let breadcrumb: String
}

// MARK: - RecentSearchItem

struct RecentSearchItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let url: String?
    let method: HTTPMethod?
    let breadcrumb: String

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

// MARK: - SearchableItem

private struct SearchableItem {
    let id: UUID
    let name: String
    let url: String?
    let method: HTTPMethod?
    let breadcrumb: String
}

// MARK: - SidebarSearchService

final class SidebarSearchService {
    private let scorer = FuzzyScorer()
    private var resultCache: [String: [SearchResult]] = [:]

    func search(query: String, in workspace: Workspace) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        // Check result cache
        if let cached = resultCache[trimmed] {
            return cached
        }

        // Collect all searchable items
        let items = collectItems(from: workspace)

        // Score each item
        var results: [SearchResult] = []
        for item in items {
            if Task.isCancelled { return [] }

            // Score against name
            let nameMatch = scorer.score(query: trimmed, target: item.name)

            // Score against URL (requests only)
            var urlMatch: FuzzyMatch?
            if let url = item.url, !url.isEmpty {
                urlMatch = scorer.score(query: trimmed, target: url)
            }

            // Pick best match
            let bestField: MatchedField
            let bestMatch: FuzzyMatch

            switch (nameMatch, urlMatch) {
            case let (.some(nm), .some(um)):
                if nm.score >= um.score {
                    bestField = .name
                    bestMatch = nm
                } else {
                    bestField = .url
                    bestMatch = um
                }
            case let (.some(nm), .none):
                bestField = .name
                bestMatch = nm
            case let (.none, .some(um)):
                bestField = .url
                bestMatch = um
            case (.none, .none):
                continue
            }

            guard bestMatch.score > 0 else { continue }

            results.append(SearchResult(
                id: item.id,
                name: item.name,
                url: item.url,
                method: item.method,
                score: bestMatch.score,
                matchedIndices: bestMatch.matchedIndices,
                matchedField: bestField,
                breadcrumb: item.breadcrumb
            ))
        }

        // Sort by score descending, then alphabetically
        results.sort { a, b in
            if a.score != b.score { return a.score > b.score }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }

        resultCache[trimmed] = results
        return results
    }

    func clearCache() {
        resultCache.removeAll()
        scorer.clearCache()
    }

    // MARK: - Item collection

    private func collectItems(from workspace: Workspace) -> [SearchableItem] {
        var items: [SearchableItem] = []
        for collection in workspace.collections {
            collectRecursive(items: collection.items, breadcrumb: "", into: &items)
        }
        return items
    }

    private func collectRecursive(items: [Item], breadcrumb: String, into result: inout [SearchableItem]) {
        for item in items {
            switch item {
            case .folder(let folder):
                result.append(SearchableItem(
                    id: folder.id,
                    name: folder.name,
                    url: nil,
                    method: nil,
                    breadcrumb: breadcrumb
                ))
                let childBreadcrumb = breadcrumb.isEmpty ? folder.name : "\(breadcrumb) > \(folder.name)"
                collectRecursive(items: folder.items, breadcrumb: childBreadcrumb, into: &result)

            case .request(let stub):
                result.append(SearchableItem(
                    id: stub.id,
                    name: stub.name,
                    url: stub.url.isEmpty ? nil : stub.url,
                    method: stub.method,
                    breadcrumb: breadcrumb
                ))
            }
        }
    }
}
