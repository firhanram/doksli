import SwiftUI

// MARK: - RawBodyView

struct RawBodyView: View {
    let data: Data
    private let bodyString: String
    private let lines: [String]

    init(data: Data) {
        self.data = data
        // Compute once at init, not on every body evaluation
        let str: String
        if let obj = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
           let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
           let text = String(data: pretty, encoding: .utf8) {
            str = text
        } else if let text = String(data: data, encoding: .utf8) {
            str = text
        } else {
            str = data.map { String(format: "%02X ", $0) }.joined()
        }
        self.bodyString = str
        self.lines = str.components(separatedBy: "\n")
    }

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
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        Text(line.isEmpty ? " " : line)
                            .font(AppFonts.mono)
                            .foregroundColor(AppColors.textPrimary)
                            .textSelection(.enabled)
                    }
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var copyAllButton: some View {
        Button {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(bodyString, forType: .string)
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
