import SwiftUI
import AppKit

// MARK: - SidebarSearchResultsView
// Extracted from SidebarView to reduce type checker memory during Release builds.

struct SidebarSearchResultsView: View {
    let results: [SearchResult]
    @Binding var selectedIndex: Int
    var onSelect: (SearchResult) -> Void

    var body: some View {
        if results.isEmpty {
            emptyResults
        } else {
            resultsList
        }
    }

    private var emptyResults: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundColor(AppColors.textFaint)
            Text("No results found")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                        resultRow(result, index: index)
                            .id(index)
                    }
                }
                .padding(.vertical, AppSpacing.sm)
            }
            .onChange(of: selectedIndex) { newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    private func resultRow(_ result: SearchResult, index: Int) -> some View {
        Button {
            onSelect(result)
        } label: {
            resultRowContent(result, index: index)
        }
        .buttonStyle(.plain)
    }

    private func resultRowContent(_ result: SearchResult, index: Int) -> some View {
        HStack(spacing: AppSpacing.sm) {
            resultIcon(result)
            resultLabels(result)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(index == selectedIndex ? AppColors.subtle : Color.clear)
        .cornerRadius(AppSpacing.radiusCard)
    }

    @ViewBuilder
    private func resultIcon(_ result: SearchResult) -> some View {
        if let method = result.method {
            MethodBadge(method: method)
        } else {
            Image(systemName: "folder")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 42)
        }
    }

    private func resultLabels(_ result: SearchResult) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if result.matchedField == .name {
                nameMatchLabels(result)
            } else {
                urlMatchLabels(result)
            }
            breadcrumbLabel(result)
        }
    }

    @ViewBuilder
    private func nameMatchLabels(_ result: SearchResult) -> some View {
        highlightedText(result.name, matchedIndices: Set(result.matchedIndices))
            .font(AppFonts.body)
            .lineLimit(1)
        if let url = result.url, !url.isEmpty {
            Text(url)
                .font(AppFonts.eyebrow)
                .foregroundColor(AppColors.textFaint)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func urlMatchLabels(_ result: SearchResult) -> some View {
        Text(result.name)
            .font(AppFonts.body)
            .foregroundColor(AppColors.textPrimary)
            .lineLimit(1)
        if let url = result.url {
            highlightedText(url, matchedIndices: Set(result.matchedIndices))
                .font(AppFonts.eyebrow)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func breadcrumbLabel(_ result: SearchResult) -> some View {
        if !result.breadcrumb.isEmpty {
            Text(result.breadcrumb)
                .font(AppFonts.eyebrow)
                .foregroundColor(AppColors.textPlaceholder)
                .lineLimit(1)
        }
    }

    private func highlightedText(_ text: String, matchedIndices: Set<Int>) -> Text {
        var result = Text("")
        for (i, char) in text.enumerated() {
            let charText: Text
            if matchedIndices.contains(i) {
                charText = Text(String(char))
                    .foregroundColor(AppColors.brand)
                    .bold()
            } else {
                charText = Text(String(char))
                    .foregroundColor(AppColors.textPrimary)
            }
            result = result + charText
        }
        return result
    }
}
