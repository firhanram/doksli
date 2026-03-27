import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSection: SettingsSection = .appearance

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            content
        }
        .frame(minWidth: 700, idealWidth: 750, minHeight: 450)
        .background(AppColors.canvas)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SETTINGS")
                    .font(AppFonts.eyebrow)
                    .foregroundColor(AppColors.textFaint)
                    .tracking(1)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            Divider()

            ScrollView {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(SettingsSection.allCases) { section in
                        sectionRow(section)
                    }
                }
                .padding(AppSpacing.sm)
            }

            Spacer()
        }
        .frame(width: 180)
        .background(AppColors.surface)
    }

    private func sectionRow(_ section: SettingsSection) -> some View {
        Button {
            selectedSection = section
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: section.icon)
                    .frame(width: 16)
                    .foregroundColor(
                        selectedSection == section ? AppColors.brand : AppColors.textTertiary
                    )
                Text(section.label)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                    .fill(selectedSection == section ? AppColors.brandTint50 : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch selectedSection {
        case .appearance:
            appearanceContent
        }
    }

    // MARK: - Appearance

    private var appearanceContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            Text("Appearance")
                .font(AppFonts.display)
                .foregroundColor(AppColors.textPrimary)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Color Mode")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)

                Picker("", selection: $appState.colorMode) {
                    Text("Automatic").tag(AppColorMode.system)
                    Text("Light").tag(AppColorMode.light)
                    Text("Dark").tag(AppColorMode.dark)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 200)
            }

            Spacer()
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
    }
}

// MARK: - SettingsSection

enum SettingsSection: String, CaseIterable, Identifiable {
    case appearance

    var id: String { rawValue }

    var label: String {
        switch self {
        case .appearance: return "Appearance"
        }
    }

    var icon: String {
        switch self {
        case .appearance: return "sun.max"
        }
    }
}
