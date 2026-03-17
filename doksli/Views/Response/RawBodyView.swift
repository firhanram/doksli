import SwiftUI

// MARK: - RawBodyView

struct RawBodyView: View {
    let data: Data

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                copyAllButton
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xs)

            Divider()
                .foregroundColor(AppColors.subtle)

            ScrollView {
                Text(bodyText)
                    .font(AppFonts.mono)
                    .foregroundColor(AppColors.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.lg)
            }
        }
    }

    private var bodyText: String {
        if let text = String(data: data, encoding: .utf8) {
            return text
        }
        // Hex fallback for non-UTF8 data
        return data.map { String(format: "%02X ", $0) }.joined()
    }

    private var copyAllButton: some View {
        Button {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(bodyText, forType: .string)
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "doc.on.doc")
                Text("Copy")
                    .font(AppFonts.body)
            }
            .foregroundColor(AppColors.textTertiary)
        }
        .buttonStyle(.plain)
    }
}
