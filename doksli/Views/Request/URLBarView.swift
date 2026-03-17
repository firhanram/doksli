import SwiftUI

// MARK: - URLBarView

struct URLBarView: View {
    @Binding var request: Request
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            methodPicker
            urlField
            sendButton
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Method picker

    private var methodPicker: some View {
        Menu {
            ForEach([HTTPMethod.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS, .HEAD], id: \.self) { method in
                Button(method.rawValue) {
                    request.method = method
                }
            }
        } label: {
            MethodBadge(method: request.method)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    // MARK: - URL field

    private var displayURL: Binding<String> {
        Binding(
            get: {
                let base = request.url
                let enabledParams = request.params.filter { $0.enabled && !$0.key.isEmpty }
                guard !enabledParams.isEmpty else { return base }
                let queryString = enabledParams
                    .map { "\($0.key)=\($0.value)" }
                    .joined(separator: "&")
                if base.contains("?") {
                    return "\(base)&\(queryString)"
                } else {
                    return "\(base)?\(queryString)"
                }
            },
            set: { newValue in
                // Strip query params from URL when user edits directly
                if let questionMark = newValue.range(of: "?") {
                    request.url = String(newValue[..<questionMark.lowerBound])
                } else {
                    request.url = newValue
                }
            }
        )
    }

    private var urlField: some View {
        TextField("Enter URL...", text: displayURL)
            .font(AppFonts.mono)
            .textFieldStyle(.plain)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.surfacePlus)
            .cornerRadius(AppSpacing.radiusInput)
            .onSubmit { sendRequest() }
    }

    // MARK: - Send button

    private var sendButton: some View {
        Button {
            sendRequest()
        } label: {
            Group {
                if appState.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
            .frame(width: 16, height: 16)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(canSend ? AppColors.brand : AppColors.muted)
            .cornerRadius(AppSpacing.radiusInput)
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
    }

    private var canSend: Bool {
        !request.url.trimmingCharacters(in: .whitespaces).isEmpty && !appState.isLoading
    }

    // MARK: - Send

    private func sendRequest() {
        guard canSend else { return }
        appState.isLoading = true
        appState.pendingResponse = nil
        Task {
            do {
                let response = try await HTTPClient.send(request, environment: appState.activeEnvironment)
                await MainActor.run {
                    appState.pendingResponse = response
                    appState.isLoading = false
                }
            } catch {
                await MainActor.run {
                    appState.isLoading = false
                }
            }
        }
    }
}
