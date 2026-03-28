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

    /// Modes shown in the picker (excludes .raw legacy)
    private static let pickerModes: [BodyMode] = [.none, .json, .formData, .urlEncoded]

    private var modePicker: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(Self.pickerModes, id: \.self) { mode in
                Button {
                    requestBody.mode = mode
                } label: {
                    Text(mode.label)
                        .font(AppFonts.body)
                        .foregroundColor(requestBody.mode == mode ? AppColors.brand : AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(requestBody.mode == mode ? AppColors.brandTint50 : Color.clear)
                        .cornerRadius(AppSpacing.radiusBadge)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Body content

    @ViewBuilder
    private var bodyContent: some View {
        switch requestBody.mode {
        case .none:
            ScrollView {
                placeholderView("This request has no body.")
            }

        case .json, .raw:
            RawBodyEditor(text: $requestBody.jsonBody)

        case .formData:
            ScrollView {
                KVEditor(pairs: $requestBody.formDataPairs, showValueType: true)
            }

        case .urlEncoded:
            ScrollView {
                KVEditor(pairs: $requestBody.urlEncodedPairs, showValueType: true, showFileOption: false)
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
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.errorBg)
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
