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
        LazyVStack(spacing: 0) {
            ForEach(Array(pairs.enumerated()), id: \.element.id) { index, pair in
                let pairBinding = $pairs[safeIndex(for: pair)]

                kvRow(pair: pairBinding, index: index)

                // Render children inline for container types
                if pair.isContainer, pair.children != nil {
                    KVEditor(
                        pairs: childrenBinding(for: pairBinding),
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

    // MARK: - Safe index lookup

    private func safeIndex(for pair: KVPair) -> Int {
        pairs.firstIndex(where: { $0.id == pair.id }) ?? 0
    }

    // MARK: - Row

    private func kvRow(pair: Binding<KVPair>, index: Int) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Toggle("", isOn: pair.enabled)
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
                TextField(keyPlaceholder, text: pair.key)
                    .font(AppFonts.mono)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.surfacePlus)
                    .cornerRadius(AppSpacing.radiusInput)
            }

            if showValueType {
                valueTypeMenu(pair: pair)
            }

            if pair.wrappedValue.isContainer {
                // Container: show item count instead of value field
                Text("\(pair.wrappedValue.children?.count ?? 0) items")
                    .font(AppFonts.eyebrow)
                    .foregroundColor(AppColors.textPlaceholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if pair.wrappedValue.valueType == .file {
                fileValueField(pair: pair)
            } else {
                TextField(valuePlaceholder, text: pair.value)
                    .font(AppFonts.mono)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.surfacePlus)
                    .cornerRadius(AppSpacing.radiusInput)
            }

            Button {
                pairs.removeAll { $0.id == pair.wrappedValue.id }
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

    // MARK: - Value type menu

    private func valueTypeMenu(pair: Binding<KVPair>) -> some View {
        Menu {
            Button {
                pair.wrappedValue.valueType = .text
                pair.wrappedValue.children = nil
                pair.wrappedValue.value = ""
            } label: {
                Label("Text", systemImage: "text.cursor")
            }

            if showFileOption {
                Button {
                    pair.wrappedValue.valueType = .file
                    pair.wrappedValue.children = nil
                    pair.wrappedValue.value = ""
                } label: {
                    Label("File", systemImage: "doc")
                }
            }

            if depth < KVPair.maxNestingDepth - 1 {
                Divider()

                Button {
                    pair.wrappedValue.valueType = .array
                    pair.wrappedValue.value = ""
                    if pair.wrappedValue.children == nil {
                        pair.wrappedValue.children = []
                    }
                } label: {
                    Label("Array", systemImage: "list.number")
                }

                Button {
                    pair.wrappedValue.valueType = .object
                    pair.wrappedValue.value = ""
                    if pair.wrappedValue.children == nil {
                        pair.wrappedValue.children = []
                    }
                } label: {
                    Label("Object", systemImage: "curlybraces")
                }
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: iconForType(pair.wrappedValue.valueType))
                    .font(.caption)
                Text(labelForType(pair.wrappedValue.valueType))
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

    private func fileValueField(pair: Binding<KVPair>) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Button {
                selectFile(for: pair)
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

            if !pair.wrappedValue.value.isEmpty {
                Text(fileDisplayName(pair.wrappedValue.value))
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

    private func selectFile(for pair: Binding<KVPair>) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            pair.wrappedValue.value = url.path
        }
    }

    private func fileDisplayName(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }

    // MARK: - Children binding

    private func childrenBinding(for pair: Binding<KVPair>) -> Binding<[KVPair]> {
        Binding(
            get: { pair.wrappedValue.children ?? [] },
            set: { pair.wrappedValue.children = $0 }
        )
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
