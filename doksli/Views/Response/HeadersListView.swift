import SwiftUI

// MARK: - HeadersListView

struct HeadersListView: View {
    let headers: [KVPair]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(headers) { header in
                    headerRow(header)
                    Divider()
                        .foregroundColor(AppColors.subtle)
                }
            }
        }
    }

    private func headerRow(_ header: KVPair) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Text(header.key)
                .font(AppFonts.mono)
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(header.value)
                .font(AppFonts.mono)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(header.value, forType: .string)
        }
    }
}
