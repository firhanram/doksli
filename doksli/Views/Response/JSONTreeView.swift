import SwiftUI

// MARK: - JSONRow

struct JSONRow: Identifiable {
    let id: Int
    let key: String?
    let depth: Int
    let kind: Kind
    let path: String

    enum Kind {
        case objectOpen(count: Int)      // "{ 3 keys }" or "{"
        case arrayOpen(count: Int)       // "[ 5 items ]" or "["
        case closingBracket(String)      // "}" or "]"
        case stringValue(String)
        case numberValue(NSNumber)
        case boolValue(Bool)
        case nullValue
        case unknownValue(String)
    }

    /// Text representation of the value (for search matching)
    var valueText: String {
        switch kind {
        case .stringValue(let s): return s
        case .numberValue(let n): return "\(n)"
        case .boolValue(let b): return b ? "true" : "false"
        case .nullValue: return "null"
        case .unknownValue(let s): return s
        case .objectOpen, .arrayOpen, .closingBracket: return ""
        }
    }
}

// MARK: - JSONSearchMatch

struct JSONSearchMatch: Identifiable {
    let id: Int
    let rowPath: String
    let field: MatchField
    let range: Range<String.Index>

    enum MatchField { case key, value }
}

// MARK: - computeAllRows (for search)

/// Walks the entire JSON tree regardless of expansion state. Skips closing brackets.
/// Returns rows in DFS order for position-priority search results.
func computeAllRows(_ root: Any) -> [JSONRow] {
    var rows: [JSONRow] = []
    var index = 0

    func walk(key: String?, value: Any, depth: Int, path: String) {
        if let dict = value as? [String: Any] {
            rows.append(JSONRow(id: index, key: key, depth: depth,
                                kind: .objectOpen(count: dict.count), path: path))
            index += 1
            for childKey in dict.keys.sorted() {
                let childPath = path.isEmpty ? childKey : "\(path).\(childKey)"
                walk(key: childKey, value: dict[childKey]!, depth: depth + 1, path: childPath)
            }
        } else if let array = value as? [Any] {
            rows.append(JSONRow(id: index, key: key, depth: depth,
                                kind: .arrayOpen(count: array.count), path: path))
            index += 1
            for (i, element) in array.enumerated() {
                let childPath = "\(path).\(i)"
                walk(key: "\(i)", value: element, depth: depth + 1, path: childPath)
            }
        } else if let string = value as? String {
            rows.append(JSONRow(id: index, key: key, depth: depth,
                                kind: .stringValue(string), path: path))
            index += 1
        } else if let number = value as? NSNumber {
            if CFBooleanGetTypeID() == CFGetTypeID(number) {
                rows.append(JSONRow(id: index, key: key, depth: depth,
                                    kind: .boolValue(number.boolValue), path: path))
            } else {
                rows.append(JSONRow(id: index, key: key, depth: depth,
                                    kind: .numberValue(number), path: path))
            }
            index += 1
        } else if value is NSNull {
            rows.append(JSONRow(id: index, key: key, depth: depth,
                                kind: .nullValue, path: path))
            index += 1
        } else {
            rows.append(JSONRow(id: index, key: key, depth: depth,
                                kind: .unknownValue(String(describing: value)), path: path))
            index += 1
        }
    }

    walk(key: nil, value: root, depth: 0, path: "")
    return rows
}

// MARK: - JSONTreeView

struct JSONTreeView: View {
    let data: Data
    @Binding var expandedPaths: Set<String>
    var searchQuery: String = ""
    var currentMatchPath: String? = nil
    var scrollToPath: String? = nil

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if let parsed = parseJSON() {
                    let rows = computeVisibleRows(parsed)
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(rows) { row in
                            rowView(row)
                                .id(rowScrollID(row))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    RawBodyView(data: data)
                }
            }
            .onChange(of: scrollToPath) { path in
                if let path {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(path, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Scroll ID

    private func rowScrollID(_ row: JSONRow) -> String {
        if case .closingBracket = row.kind {
            return "__close__\(row.id)"
        }
        return row.path
    }

    // MARK: - JSON parsing

    private func parseJSON() -> Any? {
        try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    // MARK: - Visible rows computation

    private func computeVisibleRows(_ root: Any) -> [JSONRow] {
        var rows: [JSONRow] = []
        var index = 0

        func walk(key: String?, value: Any, depth: Int, path: String) {
            if let dict = value as? [String: Any] {
                let isExpanded = expandedPaths.contains(path)
                rows.append(JSONRow(id: index, key: key, depth: depth,
                                    kind: .objectOpen(count: dict.count), path: path))
                index += 1
                if isExpanded {
                    for childKey in dict.keys.sorted() {
                        let childPath = path.isEmpty ? childKey : "\(path).\(childKey)"
                        walk(key: childKey, value: dict[childKey]!, depth: depth + 1, path: childPath)
                    }
                    rows.append(JSONRow(id: index, key: nil, depth: depth,
                                        kind: .closingBracket("}"), path: ""))
                    index += 1
                }
            } else if let array = value as? [Any] {
                let isExpanded = expandedPaths.contains(path)
                rows.append(JSONRow(id: index, key: key, depth: depth,
                                    kind: .arrayOpen(count: array.count), path: path))
                index += 1
                if isExpanded {
                    for (i, element) in array.enumerated() {
                        let childPath = "\(path).\(i)"
                        walk(key: "\(i)", value: element, depth: depth + 1, path: childPath)
                    }
                    rows.append(JSONRow(id: index, key: nil, depth: depth,
                                        kind: .closingBracket("]"), path: ""))
                    index += 1
                }
            } else if let string = value as? String {
                rows.append(JSONRow(id: index, key: key, depth: depth,
                                    kind: .stringValue(string), path: path))
                index += 1
            } else if let number = value as? NSNumber {
                if CFBooleanGetTypeID() == CFGetTypeID(number) {
                    rows.append(JSONRow(id: index, key: key, depth: depth,
                                        kind: .boolValue(number.boolValue), path: path))
                } else {
                    rows.append(JSONRow(id: index, key: key, depth: depth,
                                        kind: .numberValue(number), path: path))
                }
                index += 1
            } else if value is NSNull {
                rows.append(JSONRow(id: index, key: key, depth: depth,
                                    kind: .nullValue, path: path))
                index += 1
            } else {
                rows.append(JSONRow(id: index, key: key, depth: depth,
                                    kind: .unknownValue(String(describing: value)), path: path))
                index += 1
            }
        }

        walk(key: nil, value: root, depth: 0, path: "")
        return rows
    }

    // MARK: - Row view

    private func rowView(_ row: JSONRow) -> some View {
        let isActiveMatch = row.path == currentMatchPath && !row.path.isEmpty
        let isPassiveMatch = !searchQuery.isEmpty && rowContainsQuery(row)

        return HStack(spacing: AppSpacing.xs) {
            // Expand toggle or spacer
            if isExpandable(row.kind) {
                Image(systemName: expandedPaths.contains(row.path) ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 12, height: 12)
            } else if case .closingBracket = row.kind {
                Color.clear.frame(width: 12, height: 12)
            } else {
                Color.clear.frame(width: 12, height: 12)
            }

            // Key + value as a single selectable Text
            keyValueText(for: row, isActive: isActiveMatch)
                .font(AppFonts.mono)
                .textSelection(.enabled)
        }
        .padding(.leading, CGFloat(row.depth) * AppSpacing.lg)
        .padding(.vertical, AppSpacing.xs)
        .padding(.horizontal, AppSpacing.lg)
        .background(
            isActiveMatch ? AppColors.searchHighlightActive :
            isPassiveMatch ? AppColors.searchHighlight :
            Color.clear
        )
        .cornerRadius(AppSpacing.radiusBadge)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap(row)
        }
    }

    // MARK: - Key + value text

    private func keyValueText(for row: JSONRow, isActive: Bool) -> Text {
        var result = Text("")

        if let key = row.key {
            result = result
                + highlightedText("\"\(key)\"", query: searchQuery, baseColor: AppColors.jsonKey, isActive: isActive)
                + Text(" : ").foregroundColor(AppColors.jsonPunctuation)
        }

        result = result + valueLabelText(for: row, isActive: isActive)
        return result
    }

    // MARK: - Row contains query check

    private func rowContainsQuery(_ row: JSONRow) -> Bool {
        let q = searchQuery.lowercased()
        if let key = row.key, key.lowercased().contains(q) { return true }
        let val = row.valueText
        if !val.isEmpty && val.lowercased().contains(q) { return true }
        return false
    }

    // MARK: - Highlighted text

    private func highlightedText(_ text: String, query: String, baseColor: Color, isActive: Bool) -> Text {
        guard !query.isEmpty else {
            return Text(text).foregroundColor(baseColor)
        }

        let lowerText = text.lowercased()
        let lowerQuery = query.lowercased()

        var result = Text("")
        var searchStart = lowerText.startIndex

        while searchStart < lowerText.endIndex {
            guard let range = lowerText.range(of: lowerQuery, range: searchStart..<lowerText.endIndex) else {
                // Append remaining text
                let remaining = String(text[searchStart...])
                result = result + Text(remaining).foregroundColor(baseColor)
                break
            }

            // Append text before match
            if range.lowerBound > searchStart {
                let before = String(text[searchStart..<range.lowerBound])
                result = result + Text(before).foregroundColor(baseColor)
            }

            // Append matched text with highlight
            let matched = String(text[range])
            result = result + Text(matched)
                .foregroundColor(AppColors.brand)
                .bold()
                .underline(true, color: AppColors.brand)

            searchStart = range.upperBound
        }

        return result
    }

    // MARK: - Value label

    private func valueLabelText(for row: JSONRow, isActive: Bool) -> Text {
        switch row.kind {
        case .objectOpen(let count):
            let expanded = expandedPaths.contains(row.path)
            return Text(expanded ? "{" : "{ \(count) keys }")
                .foregroundColor(AppColors.jsonPunctuation)
        case .arrayOpen(let count):
            let expanded = expandedPaths.contains(row.path)
            return Text(expanded ? "[" : "[ \(count) items ]")
                .foregroundColor(AppColors.jsonPunctuation)
        case .closingBracket(let bracket):
            return Text(bracket)
                .foregroundColor(AppColors.jsonPunctuation)
        case .stringValue(let string):
            return highlightedText("\"\(string)\"", query: searchQuery, baseColor: AppColors.jsonString, isActive: isActive)
        case .numberValue(let number):
            return highlightedText("\(number)", query: searchQuery, baseColor: AppColors.jsonNumber, isActive: isActive)
        case .boolValue(let bool):
            return highlightedText(bool ? "true" : "false", query: searchQuery, baseColor: AppColors.jsonBoolean, isActive: isActive)
        case .nullValue:
            return highlightedText("null", query: searchQuery, baseColor: AppColors.jsonNull, isActive: isActive)
        case .unknownValue(let desc):
            return highlightedText(desc, query: searchQuery, baseColor: AppColors.textSecondary, isActive: isActive)
        }
    }

    // MARK: - Helpers

    private func isExpandable(_ kind: JSONRow.Kind) -> Bool {
        switch kind {
        case .objectOpen, .arrayOpen: return true
        default: return false
        }
    }

    private func handleTap(_ row: JSONRow) {
        if isExpandable(row.kind) {
            if expandedPaths.contains(row.path) {
                // Collapse: remove this path and all children
                expandedPaths = expandedPaths.filter { p in
                    p != row.path && !p.hasPrefix(row.path + ".")
                }
            } else {
                expandedPaths.insert(row.path)
            }
        } else if case .closingBracket = row.kind {
            // no-op
        } else {
            copyValue(row)
        }
    }

    private func copyValue(_ row: JSONRow) {
        let text: String
        switch row.kind {
        case .stringValue(let s): text = s
        case .numberValue(let n): text = "\(n)"
        case .boolValue(let b): text = b ? "true" : "false"
        case .nullValue: text = "null"
        case .unknownValue(let s): text = s
        default: return
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
