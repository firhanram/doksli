import SwiftUI

// MARK: - FolderRow

struct FolderRow: View {
    let folder: Folder

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "folder")
                .foregroundColor(AppColors.textTertiary)
                .font(AppFonts.body)
            Text(folder.name)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
    }
}
