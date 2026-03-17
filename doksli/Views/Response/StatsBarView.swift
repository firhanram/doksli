import SwiftUI

// MARK: - StatsBarView

struct StatsBarView: View {
    let response: Response
    @EnvironmentObject var appState: AppState
    @State private var copiedFeedback: String? = nil

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            statusChip
            durationChip
            sizeChip

            Spacer()

            if let feedback = copiedFeedback {
                Text(feedback)
                    .font(AppFonts.eyebrow)
                    .foregroundColor(AppColors.successText)
                    .transition(.opacity)
            }

            copyButton
            curlButton
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surface)
        .animation(.easeInOut(duration: 0.2), value: copiedFeedback)
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
            showCopiedFeedback("Copied!")
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
                let curl = CurlBuilder.build(from: request, environment: appState.activeEnvironment)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(curl, forType: .string)
                showCopiedFeedback("cURL copied!")
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

    // MARK: - Feedback

    private func showCopiedFeedback(_ message: String) {
        copiedFeedback = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedFeedback = nil
        }
    }
}

// MARK: - CurlBuilder

enum CurlBuilder {
    static func build(from request: Request, environment: Environment? = nil) -> String {
        let resolve: (String) -> String = { VariableResolver.resolve($0, environment: environment) }
        var parts = ["curl"]

        // Method
        if request.method != .GET {
            parts.append("-X \(request.method.rawValue)")
        }

        // URL with query params
        var url = resolve(request.url)
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
            parts.append("-H '\(header.key): \(resolve(header.value))'")
        }

        // Auth header
        switch request.auth {
        case .bearer(let token):
            let resolved = resolve(token)
            let cleanToken = resolved.hasPrefix("Bearer ") ? String(resolved.dropFirst(7)) : resolved
            parts.append("-H 'Authorization: Bearer \(cleanToken)'")
        case .basic(let username, let password):
            parts.append("-u '\(resolve(username)):\(resolve(password))'")
        case .apiKey(let key, let value):
            parts.append("-H '\(key): \(resolve(value))'")
        case .none:
            break
        }

        // Body
        switch request.body {
        case .raw(let text):
            if !text.isEmpty {
                let resolved = resolve(text)
                let escaped = resolved.replacingOccurrences(of: "'", with: "'\\''")
                parts.append("-d '\(escaped)'")
            }
        case .formData(let pairs):
            let flattened = HTTPClient.flattenPairs(pairs)
            for item in flattened where !item.name.isEmpty {
                if item.pair.valueType == .file {
                    parts.append("-F '\(item.name)=@\(item.pair.value)'")
                } else {
                    parts.append("-F '\(item.name)=\(item.pair.value)'")
                }
            }
        case .urlEncoded(let pairs):
            let flattened = HTTPClient.flattenPairs(pairs)
            if !flattened.isEmpty {
                let body = flattened
                    .map { "\($0.name)=\($0.pair.value)" }
                    .joined(separator: "&")
                parts.append("-d '\(body)'")
            }
        case .none:
            break
        }

        return parts.joined(separator: " ")
    }
}
