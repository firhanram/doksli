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
        }
    }

    // MARK: - Mode picker

    private var currentMode: BodyMode {
        switch requestBody {
        case .none: return .none
        case .json: return .json
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
            ScrollView {
                placeholderView("This request has no body.")
            }

        case .json:
            RawBodyEditor(text: rawTextBinding)

        case .formData:
            ScrollView {
                KVEditor(pairs: formDataBinding, showValueType: true)
            }

        case .urlEncoded:
            ScrollView {
                KVEditor(pairs: urlEncodedBinding, showValueType: true, showFileOption: false)
            }
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
        case .json: requestBody = .json("")
        case .formData: requestBody = .formData([])
        case .urlEncoded: requestBody = .urlEncoded([])
        }
    }

    // MARK: - Bindings to enum associated values

    private var rawTextBinding: Binding<String> {
        Binding(
            get: { if case .json(let s) = requestBody { return s } else { return "" } },
            set: { requestBody = .json($0) }
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
    @State private var analysis = JSONEditorBridge.AnalysisResult.empty
    @State private var analysisWorkItem: DispatchWorkItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            editorToolbar

            GeometryReader { _ in
                EditorEngine(text: $text, tokens: analysis.tokens, diagnostics: analysis.diagnostics)
            }
            .clipped()
            .onChange(of: text) { _ in analyzeDebounced() }
            .onAppear { analyzeDebounced() }

            if let error = analysis.firstError {
                errorBanner(error)
            }
        }
    }

    // MARK: - Toolbar

    private var editorToolbar: some View {
        HStack(spacing: AppSpacing.sm) {
            validationIndicator
            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    @ViewBuilder
    private var validationIndicator: some View {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            EmptyView()
        } else if analysis.isValid {
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

    // MARK: - Analysis

    private func analyzeDebounced() {
        analysisWorkItem?.cancel()
        let workItem = DispatchWorkItem { [text] in
            analysis = JSONEditorBridge.analyze(text)
        }
        analysisWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
}

// MARK: - BodyMode

private enum BodyMode: CaseIterable {
    case none, json, formData, urlEncoded

    var label: String {
        switch self {
        case .none: return "None"
        case .json: return "JSON"
        case .formData: return "Form Data"
        case .urlEncoded: return "URL Encoded"
        }
    }
}
