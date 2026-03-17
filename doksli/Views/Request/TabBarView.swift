import SwiftUI

// MARK: - TabBarView

struct TabBarView<Tab: Hashable>: View {
    let tabs: [Tab]
    @Binding var activeTab: Tab
    let label: (Tab) -> String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    tabButton(tab)
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)

            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
        }
    }

    private func tabButton(_ tab: Tab) -> some View {
        Button {
            activeTab = tab
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Text(label(tab))
                    .font(AppFonts.body)
                    .foregroundColor(activeTab == tab ? AppColors.brand : AppColors.textTertiary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)

                Rectangle()
                    .fill(activeTab == tab ? AppColors.brand : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
}
