import SwiftUI

// MARK: - StatsBarView

struct StatsBarView: View {
    let response: Response
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            statusChip
            durationChip
            sizeChip

            Spacer()

            copyButton
            curlButton
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surface)
    }

    // MARK: - Status chip

    private var statusChip: some View {
        Text("\(response.statusCode)")
            .font(AppFonts.mono)
            .foregroundColor(statusColor.text)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(statusColor.bg)
            .cornerRadius(AppSpacing.radiusBadge)
    }

    private var statusColor: (bg: Color, text: Color) {
        switch response.statusCode {
        case 200..<300:
            return (AppColors.successBg, AppColors.successText)
        case 300..<400:
            return (AppColors.warningBg, AppColors.warningText)
        default:
            return (AppColors.errorBg, AppColors.errorText)
        }
    }

    // MARK: - Duration chip

    private var durationChip: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundColor(AppColors.textTertiary)
            Text("\(Int(response.durationMs)) ms")
                .font(AppFonts.mono)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - Size chip

    private var sizeChip: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "doc")
                .font(.caption2)
                .foregroundColor(AppColors.textTertiary)
            Text(String(format: "%.1f KB", Double(response.sizeBytes) / 1000))
                .font(AppFonts.mono)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - Action buttons

    private var copyButton: some View {
        Button {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            if let text = String(data: response.body, encoding: .utf8) {
                pasteboard.setString(text, forType: .string)
            }
        } label: {
            Image(systemName: "doc.on.doc")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
        }
        .buttonStyle(.plain)
        .help("Copy response body")
    }

    private var curlButton: some View {
        Button {
            if let request = appState.selectedRequest {
                let curl = CurlBuilder.build(from: request)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(curl, forType: .string)
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "terminal")
                    .font(AppFonts.body)
                Text("cURL")
                    .font(AppFonts.mono)
            }
            .foregroundColor(AppColors.textTertiary)
        }
        .buttonStyle(.plain)
        .help("Copy as cURL")
    }

}

// MARK: - CurlBuilder

enum CurlBuilder {
    static func build(from request: Request) -> String {
        var parts = ["curl"]

        // Method
        if request.method != .GET {
            parts.append("-X \(request.method.rawValue)")
        }

        // URL with query params
        var url = request.url
        let enabledParams = request.params.filter { $0.enabled && !$0.key.isEmpty }
        if !enabledParams.isEmpty {
            let query = enabledParams
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            url += (url.contains("?") ? "&" : "?") + query
        }
        parts.append("'\(url)'")

        // Headers
        for header in request.headers where header.enabled && !header.key.isEmpty {
            parts.append("-H '\(header.key): \(header.value)'")
        }

        // Auth header
        switch request.auth {
        case .bearer(let token):
            parts.append("-H 'Authorization: Bearer \(token)'")
        case .basic(let username, let password):
            parts.append("-u '\(username):\(password)'")
        case .apiKey(let key, let value):
            parts.append("-H '\(key): \(value)'")
        case .none:
            break
        }

        // Body
        switch request.body {
        case .raw(let text):
            if !text.isEmpty {
                let escaped = text.replacingOccurrences(of: "'", with: "'\\''")
                parts.append("-d '\(escaped)'")
            }
        case .formData(let pairs):
            for pair in pairs where pair.enabled && !pair.key.isEmpty {
                parts.append("-F '\(pair.key)=\(pair.value)'")
            }
        case .urlEncoded(let pairs):
            let enabledPairs = pairs.filter { $0.enabled && !$0.key.isEmpty }
            if !enabledPairs.isEmpty {
                let body = enabledPairs
                    .map { "\($0.key)=\($0.value)" }
                    .joined(separator: "&")
                parts.append("-d '\(body)'")
            }
        case .none:
            break
        }

        return parts.joined(separator: " ")
    }
}
