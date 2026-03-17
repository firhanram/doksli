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

            ScrollView {
                bodyContent
            }
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
            RawBodyEditor(text: rawTextBinding)

        case .formData:
            KVEditor(pairs: formDataBinding, showValueType: true)

        case .urlEncoded:
            KVEditor(pairs: urlEncodedBinding, showValueType: true, showFileOption: false)
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

// MARK: - RawBodyEditor

private struct RawBodyEditor: View {
    @Binding var text: String
    @State private var validationResult = JSONValidator.ValidationResult(
        isValid: true, errorMessage: nil, errorPosition: nil
    )
    @State private var validationWorkItem: DispatchWorkItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            editorToolbar

            TextEditor(text: $text)
                .font(AppFonts.mono)
                .scrollContentBackground(.hidden)
                .background(AppColors.surfacePlus)
                .cornerRadius(AppSpacing.radiusInput)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .onChange(of: text) { _ in validateDebounced() }
                .onAppear { validateDebounced() }

            if let errorMessage = validationResult.errorMessage {
                errorBanner(errorMessage)
            }
        }
    }

    // MARK: - Toolbar

    private var editorToolbar: some View {
        HStack(spacing: AppSpacing.sm) {
            validationIndicator

            Spacer()

            Button {
                text = JSONValidator.prettyPrint(text)
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "text.alignleft")
                    Text("Format")
                        .font(AppFonts.eyebrow)
                }
                .foregroundColor(formatButtonEnabled ? AppColors.brand : AppColors.muted)
            }
            .buttonStyle(.plain)
            .disabled(!formatButtonEnabled)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    private var formatButtonEnabled: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && validationResult.isValid
    }

    @ViewBuilder
    private var validationIndicator: some View {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            EmptyView()
        } else if validationResult.isValid {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.successText)
                Text("Valid JSON")
                    .font(AppFonts.eyebrow)
                    .foregroundColor(AppColors.successText)
            }
        } else {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(AppColors.errorText)
                Text("Invalid JSON")
                    .font(AppFonts.eyebrow)
                    .foregroundColor(AppColors.errorText)
            }
        }
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            Text(message)
                .font(AppFonts.eyebrow)
                .lineLimit(2)
        }
        .foregroundColor(AppColors.errorText)
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.errorBg)
        .cornerRadius(AppSpacing.radiusBadge)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.sm)
    }

    // MARK: - Validation

    private func validateDebounced() {
        validationWorkItem?.cancel()
        let workItem = DispatchWorkItem { [text] in
            validationResult = JSONValidator.validate(text)
        }
        validationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
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
