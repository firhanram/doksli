import SwiftUI

// MARK: - HistoryView

struct HistoryView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.historyEntries.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedEntries, id: \.date) { group in
                        sectionHeader(group.label)

                        ForEach(group.entries) { entry in
                            historyRow(entry)
                            Divider().foregroundColor(AppColors.subtle)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "clock")
                .font(.title)
                .foregroundColor(AppColors.textFaint)
            Text("No history yet")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Section header

    private func sectionHeader(_ label: String) -> some View {
        Text(label.uppercased())
            .font(AppFonts.eyebrow)
            .tracking(AppFonts.eyebrowTracking)
            .foregroundColor(AppColors.textFaint)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - History row

    private func historyRow(_ entry: HistoryEntry) -> some View {
        Button {
            appState.selectedRequest = entry.request
            appState.pendingResponse = entry.response
            appState.lastError = nil
        } label: {
            HStack(spacing: AppSpacing.sm) {
                MethodBadge(method: entry.request.method)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayURL(entry.request))
                        .font(AppFonts.mono)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: AppSpacing.sm) {
                        statusChip(entry.response.statusCode)

                        Text("\(Int(entry.response.durationMs)) ms")
                            .font(AppFonts.eyebrow)
                            .foregroundColor(AppColors.textTertiary)

                        Spacer()

                        Text(timeString(entry.timestamp))
                            .font(AppFonts.eyebrow)
                            .foregroundColor(AppColors.textPlaceholder)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func displayURL(_ request: Request) -> String {
        let url = request.url
        if url.isEmpty { return request.name }
        // Strip protocol prefix for compact display
        return url
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
    }

    private func statusChip(_ code: Int) -> some View {
        Text("\(code)")
            .font(AppFonts.eyebrow)
            .foregroundColor(statusColor(code).text)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 1)
            .background(statusColor(code).bg)
            .cornerRadius(AppSpacing.radiusBadge)
    }

    private func statusColor(_ code: Int) -> (bg: Color, text: Color) {
        switch code {
        case 200..<300:
            return (AppColors.successBg, AppColors.successText)
        case 300..<400:
            return (AppColors.warningBg, AppColors.warningText)
        default:
            return (AppColors.errorBg, AppColors.errorText)
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Date grouping

    private struct DateGroup {
        let date: String
        let label: String
        let entries: [HistoryEntry]
    }

    private var groupedEntries: [DateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: appState.historyEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }

        return grouped.keys.sorted(by: >).map { date in
            let label = dateLabel(for: date)
            let entries = grouped[date]!.sorted { $0.timestamp > $1.timestamp }
            return DateGroup(date: date.ISO8601Format(), label: label, entries: entries)
        }
    }

    private func dateLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}
