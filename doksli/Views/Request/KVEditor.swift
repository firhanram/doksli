import SwiftUI

// MARK: - KVEditor

struct KVEditor: View {
    @Binding var pairs: [KVPair]
    var keyPlaceholder: String = "Key"
    var valuePlaceholder: String = "Value"
    var showValueType: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ForEach($pairs) { $pair in
                kvRow(pair: $pair)
                Divider()
                    .foregroundColor(AppColors.subtle)
            }

            addButton
        }
    }

    private func kvRow(pair: Binding<KVPair>) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Toggle("", isOn: pair.enabled)
                .toggleStyle(.checkbox)
                .labelsHidden()

            TextField(keyPlaceholder, text: pair.key)
                .font(AppFonts.mono)
                .textFieldStyle(.plain)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.surfacePlus)
                .cornerRadius(AppSpacing.radiusInput)

            if showValueType {
                valueTypeMenu(pair: pair)
            }

            if pair.wrappedValue.valueType == .file {
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
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Value type menu

    private func valueTypeMenu(pair: Binding<KVPair>) -> some View {
        Menu {
            Button {
                pair.wrappedValue.valueType = .text
                pair.wrappedValue.value = ""
            } label: {
                Label("Text", systemImage: "text.cursor")
            }
            Button {
                pair.wrappedValue.valueType = .file
                pair.wrappedValue.value = ""
            } label: {
                Label("File", systemImage: "doc")
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: pair.wrappedValue.valueType == .file ? "doc" : "text.cursor")
                    .font(.caption)
                Text(pair.wrappedValue.valueType == .file ? "File" : "Text")
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
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
