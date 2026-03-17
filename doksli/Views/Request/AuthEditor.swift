import SwiftUI

// MARK: - AuthEditor

struct AuthEditor: View {
    @Binding var auth: Auth

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            modePicker
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)

            Divider()
                .foregroundColor(AppColors.subtle)

            authContent

            Spacer(minLength: 0)
        }
    }

    // MARK: - Mode picker

    private var currentMode: AuthMode {
        switch auth {
        case .none: return .none
        case .bearer: return .bearer
        case .basic: return .basic
        case .apiKey: return .apiKey
        }
    }

    private var modePicker: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(AuthMode.allCases, id: \.self) { mode in
                Button {
                    switchMode(to: mode)
                } label: {
                    Text(mode.label)
                        .font(AppFonts.body)
                        .foregroundColor(currentMode == mode ? AppColors.brand : AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(currentMode == mode ? AppColors.brandTint50 : Color.clear)
                        .cornerRadius(AppSpacing.radiusBadge)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Auth content

    @ViewBuilder
    private var authContent: some View {
        switch auth {
        case .none:
            placeholderView("No authentication.")

        case .bearer:
            fieldSection(label: "Token") {
                TextField("Bearer token", text: bearerTokenBinding)
                    .font(AppFonts.mono)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.surfacePlus)
                    .cornerRadius(AppSpacing.radiusInput)
            }

        case .basic:
            VStack(spacing: AppSpacing.md) {
                fieldSection(label: "Username") {
                    TextField("Username", text: basicUsernameBinding)
                        .font(AppFonts.mono)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.surfacePlus)
                        .cornerRadius(AppSpacing.radiusInput)
                }

                fieldSection(label: "Password") {
                    SecureField("Password", text: basicPasswordBinding)
                        .font(AppFonts.mono)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.surfacePlus)
                        .cornerRadius(AppSpacing.radiusInput)
                }
            }

        case .apiKey:
            VStack(spacing: AppSpacing.md) {
                fieldSection(label: "Header Name") {
                    TextField("X-API-Key", text: apiKeyNameBinding)
                        .font(AppFonts.mono)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.surfacePlus)
                        .cornerRadius(AppSpacing.radiusInput)
                }

                fieldSection(label: "Value") {
                    TextField("API key value", text: apiKeyValueBinding)
                        .font(AppFonts.mono)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.surfacePlus)
                        .cornerRadius(AppSpacing.radiusInput)
                }
            }
        }
    }

    private func fieldSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFonts.eyebrow)
                .tracking(AppFonts.eyebrowTracking)
                .foregroundColor(AppColors.textFaint)
                .textCase(.uppercase)

            content()
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    private func placeholderView(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPlaceholder)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Mode switching

    private func switchMode(to mode: AuthMode) {
        switch mode {
        case .none: auth = .none
        case .bearer: auth = .bearer("")
        case .basic: auth = .basic("", "")
        case .apiKey: auth = .apiKey("", "")
        }
    }

    // MARK: - Bindings to enum associated values

    private var bearerTokenBinding: Binding<String> {
        Binding(
            get: { if case .bearer(let t) = auth { return t } else { return "" } },
            set: { auth = .bearer($0) }
        )
    }

    private var basicUsernameBinding: Binding<String> {
        Binding(
            get: { if case .basic(let u, _) = auth { return u } else { return "" } },
            set: { newVal in
                let password = { if case .basic(_, let p) = auth { return p } else { return "" } }()
                auth = .basic(newVal, password)
            }
        )
    }

    private var basicPasswordBinding: Binding<String> {
        Binding(
            get: { if case .basic(_, let p) = auth { return p } else { return "" } },
            set: { newVal in
                let username = { if case .basic(let u, _) = auth { return u } else { return "" } }()
                auth = .basic(username, newVal)
            }
        )
    }

    private var apiKeyNameBinding: Binding<String> {
        Binding(
            get: { if case .apiKey(let n, _) = auth { return n } else { return "" } },
            set: { newVal in
                let value = { if case .apiKey(_, let v) = auth { return v } else { return "" } }()
                auth = .apiKey(newVal, value)
            }
        )
    }

    private var apiKeyValueBinding: Binding<String> {
        Binding(
            get: { if case .apiKey(_, let v) = auth { return v } else { return "" } },
            set: { newVal in
                let name = { if case .apiKey(let n, _) = auth { return n } else { return "" } }()
                auth = .apiKey(name, newVal)
            }
        )
    }
}

// MARK: - AuthMode

private enum AuthMode: CaseIterable {
    case none, bearer, basic, apiKey

    var label: String {
        switch self {
        case .none: return "None"
        case .bearer: return "Bearer"
        case .basic: return "Basic"
        case .apiKey: return "API Key"
        }
    }
}
