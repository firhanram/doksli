import SwiftUI

// MARK: - KVEditor

struct KVEditor: View {
    @Binding var pairs: [KVPair]
    var keyPlaceholder: String = "Key"
    var valuePlaceholder: String = "Value"

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

            TextField(valuePlaceholder, text: pair.value)
                .font(AppFonts.mono)
                .textFieldStyle(.plain)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.surfacePlus)
                .cornerRadius(AppSpacing.radiusInput)

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
