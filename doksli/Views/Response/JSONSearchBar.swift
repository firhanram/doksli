import SwiftUI

// MARK: - JSONSearchBar

struct JSONSearchBar: View {
    @Binding var query: String
    let matchCount: Int
    let currentIndex: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onClose: () -> Void

    @FocusState private var isFocused: Bool
    @State private var keyMonitor: Any?

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPlaceholder)

            TextField("Search…", text: $query)
                .font(AppFonts.body)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit { onNext() }
                .frame(maxWidth: .infinity)

            if !query.isEmpty {
                matchCountLabel
            }

            Button { onPrevious() } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(matchCount > 0 ? AppColors.textSecondary : AppColors.muted)
            }
            .buttonStyle(.plain)
            .disabled(matchCount == 0)

            Button { onNext() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(matchCount > 0 ? AppColors.textSecondary : AppColors.muted)
            }
            .buttonStyle(.plain)
            .disabled(matchCount == 0)

            Button { onClose() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.canvas)
        .cornerRadius(AppSpacing.radiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
        .frame(width: 300)
        .onAppear {
            isFocused = true
            installKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
        .onExitCommand { onClose() }
    }

    // MARK: - Match count label

    private var matchCountLabel: some View {
        Group {
            if matchCount > 0 {
                Text("\(currentIndex + 1) of \(matchCount)")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textTertiary)
            } else {
                Text("No results")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.errorText)
            }
        }
        .fixedSize()
    }

    // MARK: - Key monitor for Shift+Enter

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isFocused else { return event }

            if event.keyCode == 36 && event.modifierFlags.contains(.shift) {
                // Shift+Enter → previous match
                onPrevious()
                return nil
            }

            if event.keyCode == 53 {
                // Esc
                onClose()
                return nil
            }

            return event
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}
