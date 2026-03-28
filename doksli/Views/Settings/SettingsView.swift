import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var shortcutStore: ShortcutStore
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
        case .shortcuts:
            ShortcutsSettingsView(store: shortcutStore)
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

// MARK: - ShortcutsSettingsView

struct ShortcutsSettingsView: View {
    @ObservedObject var store: ShortcutStore
    @State private var recordingAction: ShortcutAction? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                Text("Shortcuts")
                    .font(AppFonts.display)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Button("Reset All") {
                    store.resetAll()
                }
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
                .buttonStyle(.plain)
            }

            Text("Click a shortcut to record a new key combination. Press Escape to cancel.")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(ShortcutAction.allCases) { action in
                        shortcutRow(action)
                        if action != ShortcutAction.allCases.last {
                            Divider()
                                .padding(.horizontal, AppSpacing.sm)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusPanel)
                        .fill(AppColors.surfacePlus)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusPanel)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
        .modifier(KeyRecorderOverlay(recordingAction: $recordingAction, store: store))
    }

    private func shortcutRow(_ action: ShortcutAction) -> some View {
        let isRecording = recordingAction == action
        let currentShortcut = store.shortcut(for: action)
        let isCustom = store.customShortcuts[action] != nil

        return HStack {
            Text(action.label)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            if isCustom {
                Button {
                    store.resetToDefault(for: action)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
                .help("Reset to default")
            }

            shortcutBadge(action: action, shortcut: currentShortcut, isRecording: isRecording)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .contentShape(Rectangle())
    }

    private func shortcutBadge(action: ShortcutAction, shortcut: KeyShortcut, isRecording: Bool) -> some View {
        Group {
            if isRecording {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.brand)
                    Text("Recording...")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.brand)
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusBadge)
                        .fill(AppColors.brandTint50)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusBadge)
                        .stroke(AppColors.brand, lineWidth: 1)
                )
            } else {
                Button {
                    recordingAction = action
                } label: {
                    Text(shortcut.displayString)
                        .font(AppFonts.mono)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusBadge)
                                .fill(AppColors.subtle)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - SettingsSection

enum SettingsSection: String, CaseIterable, Identifiable {
    case appearance
    case shortcuts

    var id: String { rawValue }

    var label: String {
        switch self {
        case .appearance: return "Appearance"
        case .shortcuts:  return "Shortcuts"
        }
    }

    var icon: String {
        switch self {
        case .appearance: return "sun.max"
        case .shortcuts:  return "keyboard"
        }
    }
}
