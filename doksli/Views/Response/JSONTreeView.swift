import SwiftUI

// MARK: - JSONRow

private struct JSONRow: Identifiable {
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
}

// MARK: - JSONTreeView

struct JSONTreeView: View {
    let data: Data
    @State private var expandedPaths: Set<String> = [""]

    var body: some View {
        ScrollView {
            if let parsed = parseJSON() {
                let rows = computeVisibleRows(parsed)
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        rowView(row)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                RawBodyView(data: data)
            }
        }
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
        HStack(spacing: AppSpacing.xs) {
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

            // Key label
            if let key = row.key {
                Text("\"\(key)\"")
                    .font(AppFonts.mono)
                    .foregroundColor(AppColors.jsonKey)
                Text(":")
                    .font(AppFonts.mono)
                    .foregroundColor(AppColors.jsonPunctuation)
            }

            // Value label
            valueLabel(for: row)
        }
        .padding(.leading, CGFloat(row.depth) * AppSpacing.lg)
        .padding(.vertical, AppSpacing.xs)
        .padding(.horizontal, AppSpacing.lg)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap(row)
        }
    }

    // MARK: - Value label

    @ViewBuilder
    private func valueLabel(for row: JSONRow) -> some View {
        switch row.kind {
        case .objectOpen(let count):
            let expanded = expandedPaths.contains(row.path)
            Text(expanded ? "{" : "{ \(count) keys }")
                .font(AppFonts.mono)
                .foregroundColor(AppColors.jsonPunctuation)
        case .arrayOpen(let count):
            let expanded = expandedPaths.contains(row.path)
            Text(expanded ? "[" : "[ \(count) items ]")
                .font(AppFonts.mono)
                .foregroundColor(AppColors.jsonPunctuation)
        case .closingBracket(let bracket):
            Text(bracket)
                .font(AppFonts.mono)
                .foregroundColor(AppColors.jsonPunctuation)
        case .stringValue(let string):
            Text("\"\(string)\"")
                .font(AppFonts.mono)
                .foregroundColor(AppColors.jsonString)
                .fixedSize(horizontal: false, vertical: true)
        case .numberValue(let number):
            Text("\(number)")
                .font(AppFonts.mono)
                .foregroundColor(AppColors.jsonNumber)
        case .boolValue(let bool):
            Text(bool ? "true" : "false")
                .font(AppFonts.mono)
                .foregroundColor(AppColors.jsonBoolean)
        case .nullValue:
            Text("null")
                .font(AppFonts.mono)
                .foregroundColor(AppColors.jsonNull)
        case .unknownValue(let desc):
            Text(desc)
                .font(AppFonts.mono)
                .foregroundColor(AppColors.textSecondary)
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
