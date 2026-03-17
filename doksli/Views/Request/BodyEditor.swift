import SwiftUI

// MARK: - BodyEditor

struct BodyEditor: View {
    @Binding var requestBody: RequestBody

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            modePicker
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)

            Divider()
                .foregroundColor(AppColors.subtle)

            bodyContent

            Spacer(minLength: 0)
        }
    }

    // MARK: - Mode picker

    private var currentMode: BodyMode {
        switch requestBody {
        case .none: return .none
        case .raw: return .raw
        case .formData: return .formData
        case .urlEncoded: return .urlEncoded
        }
    }

    private var modePicker: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(BodyMode.allCases, id: \.self) { mode in
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

    // MARK: - Body content

    @ViewBuilder
    private var bodyContent: some View {
        switch requestBody {
        case .none:
            placeholderView("This request has no body.")

        case .raw:
            TextEditor(text: rawTextBinding)
                .font(AppFonts.mono)
                .scrollContentBackground(.hidden)
                .padding(AppSpacing.sm)
                .background(AppColors.surfacePlus)
                .cornerRadius(AppSpacing.radiusInput)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)

        case .formData:
            KVEditor(pairs: formDataBinding)

        case .urlEncoded:
            KVEditor(pairs: urlEncodedBinding)
        }
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

    private func switchMode(to mode: BodyMode) {
        switch mode {
        case .none: requestBody = .none
        case .raw: requestBody = .raw("")
        case .formData: requestBody = .formData([])
        case .urlEncoded: requestBody = .urlEncoded([])
        }
    }

    // MARK: - Bindings to enum associated values

    private var rawTextBinding: Binding<String> {
        Binding(
            get: { if case .raw(let s) = requestBody { return s } else { return "" } },
            set: { requestBody = .raw($0) }
        )
    }

    private var formDataBinding: Binding<[KVPair]> {
        Binding(
            get: { if case .formData(let p) = requestBody { return p } else { return [] } },
            set: { requestBody = .formData($0) }
        )
    }

    private var urlEncodedBinding: Binding<[KVPair]> {
        Binding(
            get: { if case .urlEncoded(let p) = requestBody { return p } else { return [] } },
            set: { requestBody = .urlEncoded($0) }
        )
    }
}

// MARK: - BodyMode

private enum BodyMode: CaseIterable {
    case none, raw, formData, urlEncoded

    var label: String {
        switch self {
        case .none: return "None"
        case .raw: return "Raw"
        case .formData: return "Form Data"
        case .urlEncoded: return "URL Encoded"
        }
    }
}
