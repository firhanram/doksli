import SwiftUI

// MARK: - KVEditor

struct KVEditor: View {
    @Binding var pairs: [KVPair]
    var keyPlaceholder: String = "Key"
    var valuePlaceholder: String = "Value"
    var showValueType: Bool = false
    var showFileOption: Bool = true
    var depth: Int = 0
    var parentValueType: KVPair.ValueType? = nil

    var body: some View {
        VStack(spacing: 0) {
            if depth == 0 && !pairs.isEmpty {
                toggleAllRow
                Divider().foregroundColor(AppColors.subtle)
            }

            ForEach($pairs) { $pair in
                KVRow(
                    pair: $pair,
                    index: rowIndex(for: pair.id),
                    depth: depth,
                    parentValueType: parentValueType,
                    keyPlaceholder: keyPlaceholder,
                    valuePlaceholder: valuePlaceholder,
                    showValueType: showValueType,
                    showFileOption: showFileOption,
                    onDelete: { pairs.removeAll { $0.id == pair.id } }
                )

                // Render children inline for container types
                if pair.isContainer, pair.children != nil {
                    KVEditor(
                        pairs: $pair.children.toNonOptional(),
                        keyPlaceholder: pair.valueType == .array ? "#" : "Key",
                        valuePlaceholder: "Value",
                        showValueType: true,
                        showFileOption: showFileOption,
                        depth: depth + 1,
                        parentValueType: pair.valueType
                    )
                    .opacity(pair.enabled ? 1 : 0.5)
                }

                Divider()
                    .foregroundColor(AppColors.subtle)
            }

            addButton
        }
    }

    // MARK: - Helpers

    private func rowIndex(for id: UUID) -> Int {
        pairs.firstIndex(where: { $0.id == id }) ?? 0
    }

    // MARK: - Toggle all

    private var allEnabled: Bool {
        pairs.allSatisfy { $0.enabled }
    }

    private var toggleAllRow: some View {
        HStack(spacing: AppSpacing.sm) {
            Toggle("", isOn: Binding(
                get: { allEnabled },
                set: { newValue in
                    for i in pairs.indices {
                        pairs[i].enabled = newValue
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            Text(allEnabled ? "Deselect All" : "Select All")
                .font(AppFonts.eyebrow)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
    }

    // MARK: - Add button

    private var addButton: some View {
        Button {
            pairs.append(KVPair(id: UUID(), key: "", value: "", enabled: true))
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "plus")
                Text("Add")
                    .font(AppFonts.body)
            }
            .foregroundColor(AppColors.textTertiary)
            .padding(.leading, AppSpacing.lg + CGFloat(depth) * AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Optional Binding Helper

private extension Binding where Value == [KVPair]? {
    func toNonOptional() -> Binding<[KVPair]> {
        Binding<[KVPair]>(
            get: { self.wrappedValue ?? [] },
            set: { self.wrappedValue = $0 }
        )
    }
}

// MARK: - KVRow

private struct KVRow: View {
    @Binding var pair: KVPair
    let index: Int
    let depth: Int
    let parentValueType: KVPair.ValueType?
    let keyPlaceholder: String
    let valuePlaceholder: String
    let showValueType: Bool
    let showFileOption: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Toggle("", isOn: $pair.enabled)
                .toggleStyle(.checkbox)
                .labelsHidden()

            // Array children: show read-only index instead of editable key
            if parentValueType == .array {
                Text("\(index)")
                    .font(AppFonts.mono)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 30, alignment: .center)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.surfacePlus)
                    .cornerRadius(AppSpacing.radiusInput)
            } else {
                kvTextField(keyPlaceholder, text: $pair.key)
            }

            if showValueType {
                valueTypeMenu
            }

            if pair.isContainer {
                // Container: show item count instead of value field
                Text("\(pair.children?.count ?? 0) items")
                    .font(AppFonts.eyebrow)
                    .foregroundColor(AppColors.textPlaceholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if pair.valueType == .file {
                fileValueField
            } else {
                kvTextField(valuePlaceholder, text: $pair.value)
            }

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, AppSpacing.lg + CGFloat(depth) * AppSpacing.lg)
        .padding(.trailing, AppSpacing.lg)
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - KV TextField with visible selection

    private func kvTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(AppFonts.mono)
            .textFieldStyle(.plain)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.radiusInput)
                    .fill(AppColors.surfacePlus)
            )
    }

    // MARK: - Value type menu

    private var valueTypeMenu: some View {
        Menu {
            Button {
                pair.valueType = .text
                pair.children = nil
                pair.value = ""
            } label: {
                Label("Text", systemImage: "text.cursor")
            }

            if showFileOption {
                Button {
                    pair.valueType = .file
                    pair.children = nil
                    pair.value = ""
                } label: {
                    Label("File", systemImage: "doc")
                }
            }

            if depth < KVPair.maxNestingDepth - 1 {
                Divider()

                Button {
                    pair.valueType = .array
                    pair.value = ""
                    if pair.children == nil {
                        pair.children = []
                    }
                } label: {
                    Label("Array", systemImage: "list.number")
                }

                Button {
                    pair.valueType = .object
                    pair.value = ""
                    if pair.children == nil {
                        pair.children = []
                    }
                } label: {
                    Label("Object", systemImage: "curlybraces")
                }
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: iconForType(pair.valueType))
                    .font(.caption)
                Text(labelForType(pair.valueType))
                    .font(AppFonts.eyebrow)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .foregroundColor(AppColors.textTertiary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.surfacePlus)
            .cornerRadius(AppSpacing.radiusBadge)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func iconForType(_ type: KVPair.ValueType) -> String {
        switch type {
        case .text: return "text.cursor"
        case .file: return "doc"
        case .array: return "list.number"
        case .object: return "curlybraces"
        }
    }

    private func labelForType(_ type: KVPair.ValueType) -> String {
        switch type {
        case .text: return "Text"
        case .file: return "File"
        case .array: return "Array"
        case .object: return "Object"
        }
    }

    // MARK: - File value field

    private var fileValueField: some View {
        HStack(spacing: AppSpacing.sm) {
            Button {
                selectFile()
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "folder")
                        .font(.caption)
                    Text("Choose File")
                        .font(AppFonts.eyebrow)
                }
                .foregroundColor(AppColors.brand)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.brandTint50)
                .cornerRadius(AppSpacing.radiusBadge)
            }
            .buttonStyle(.plain)

            if !pair.value.isEmpty {
                Text(fileDisplayName(pair.value))
                    .font(AppFonts.mono)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text("No file selected")
                    .font(AppFonts.mono)
                    .foregroundColor(AppColors.textPlaceholder)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.surfacePlus)
        .cornerRadius(AppSpacing.radiusInput)
    }

    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            pair.value = url.path
        }
    }

    private func fileDisplayName(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }
}
