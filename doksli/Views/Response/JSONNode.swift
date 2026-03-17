import SwiftUI

// MARK: - JSONNode

struct JSONNode: View {
    let key: String?
    let value: Any
    let depth: Int

    @State private var isExpanded: Bool

    init(key: String?, value: Any, depth: Int) {
        self.key = key
        self.value = value
        self.depth = depth
        self._isExpanded = State(initialValue: depth == 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            nodeRow
            if isExpanded {
                childrenView
            }
        }
    }

    // MARK: - Node row

    private var nodeRow: some View {
        HStack(spacing: AppSpacing.xs) {
            if isExpandable {
                expandToggle
            } else {
                Color.clear
                    .frame(width: 12, height: 12)
            }

            if let key = key {
                Text("\"\(key)\"")
                    .font(AppFonts.mono)
                    .foregroundColor(AppColors.jsonKey)
                Text(":")
                    .font(AppFonts.mono)
                    .foregroundColor(AppColors.jsonPunctuation)
            }

            valueLabel
        }
        .padding(.leading, CGFloat(depth) * AppSpacing.lg)
        .padding(.vertical, AppSpacing.xs)
        .padding(.horizontal, AppSpacing.lg)
        .contentShape(Rectangle())
        .onTapGesture {
            if isExpandable {
                isExpanded.toggle()
            } else {
                copyValue()
            }
        }
    }

    // MARK: - Expand toggle

    private var expandToggle: some View {
        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(AppColors.textTertiary)
            .frame(width: 12, height: 12)
    }

    // MARK: - Value label

    @ViewBuilder
    private var valueLabel: some View {
        if let dict = value as? [String: Any] {
            Text(isExpanded ? "{" : "{ \(dict.count) keys }")
                .font(AppFonts.mono)
                .foregroundColor(AppColors.jsonPunctuation)
        } else if let array = value as? [Any] {
            Text(isExpanded ? "[" : "[ \(array.count) items ]")
                .font(AppFonts.mono)
                .foregroundColor(AppColors.jsonPunctuation)
        } else if let string = value as? String {
            Text("\"\(string)\"")
                .font(AppFonts.mono)
                .foregroundColor(AppColors.jsonString)
                .lineLimit(1)
        } else if let number = value as? NSNumber {
            if isBoolNumber(number) {
                Text(number.boolValue ? "true" : "false")
                    .font(AppFonts.mono)
                    .foregroundColor(AppColors.jsonBoolean)
            } else {
                Text("\(number)")
                    .font(AppFonts.mono)
                    .foregroundColor(AppColors.jsonNumber)
            }
        } else if value is NSNull {
            Text("null")
                .font(AppFonts.mono)
                .foregroundColor(AppColors.jsonNull)
        } else {
            Text(String(describing: value))
                .font(AppFonts.mono)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - Children

    private var isExpandable: Bool {
        value is [String: Any] || value is [Any]
    }

    @ViewBuilder
    private var childrenView: some View {
        if let dict = value as? [String: Any] {
            ForEach(dict.keys.sorted(), id: \.self) { childKey in
                JSONNode(key: childKey, value: dict[childKey]!, depth: depth + 1)
            }
            closingBracket("}")
        } else if let array = value as? [Any] {
            ForEach(Array(array.enumerated()), id: \.offset) { index, element in
                JSONNode(key: "\(index)", value: element, depth: depth + 1)
            }
            closingBracket("]")
        }
    }

    private func closingBracket(_ bracket: String) -> some View {
        Text(bracket)
            .font(AppFonts.mono)
            .foregroundColor(AppColors.jsonPunctuation)
            .padding(.leading, CGFloat(depth) * AppSpacing.lg + 12 + AppSpacing.xs)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Helpers

    private func isBoolNumber(_ number: NSNumber) -> Bool {
        CFBooleanGetTypeID() == CFGetTypeID(number)
    }

    private func copyValue() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let text: String
        if let string = value as? String {
            text = string
        } else if let number = value as? NSNumber {
            if isBoolNumber(number) {
                text = number.boolValue ? "true" : "false"
            } else {
                text = "\(number)"
            }
        } else if value is NSNull {
            text = "null"
        } else {
            text = String(describing: value)
        }
        pasteboard.setString(text, forType: .string)
    }
}
