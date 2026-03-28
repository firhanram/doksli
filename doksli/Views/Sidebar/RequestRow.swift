import SwiftUI

// MARK: - RequestRow

struct RequestRow: View {
    let stub: RequestStub
    let isActive: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            MethodBadge(method: stub.method)
            Text(stub.name)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? AppColors.subtle : Color.clear)
        .cornerRadius(AppSpacing.radiusCard)
    }
}
