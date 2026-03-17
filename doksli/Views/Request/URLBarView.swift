import SwiftUI

// MARK: - URLBarView

struct URLBarView: View {
    @Binding var request: Request
    @EnvironmentObject var appState: AppState
    @State private var showSuggestions = false
    @State private var varQuery = ""
    @State private var selectedIndex = 0
    @State private var keyMonitor: Any? = nil

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            methodPicker
            urlFieldWithSuggestions
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

    private var urlFieldWithSuggestions: some View {
        urlField
            .popover(isPresented: $showSuggestions, arrowEdge: .bottom) {
                suggestionsList
            }
    }

    private var urlField: some View {
        ZStack(alignment: .leading) {
            // Highlighted overlay — only {{vars}} are colored, rest is transparent
            if hasVariables {
                Text(highlightedURL)
                    .font(AppFonts.mono)
                    .allowsHitTesting(false)
            }

            // Actual editable TextField
            TextField("Enter URL...", text: displayURL)
                .font(AppFonts.mono)
                .textFieldStyle(.plain)
                .foregroundColor(AppColors.textPrimary)
                .onSubmit {
                    if showSuggestions && !filteredVariables.isEmpty {
                        let clamped = min(selectedIndex, filteredVariables.count - 1)
                        insertVariable(filteredVariables[clamped].key)
                    } else {
                        sendRequest()
                    }
                }
                .onChange(of: request.url) { newValue in
                    checkForVariableTrigger(newValue)
                }
                .onChange(of: showSuggestions) { showing in
                    if showing {
                        installKeyMonitor()
                    } else {
                        removeKeyMonitor()
                    }
                }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surfacePlus)
        .cornerRadius(AppSpacing.radiusInput)
        .help(variableTooltip)
    }

    // MARK: - Variable highlighting

    private var hasVariables: Bool {
        displayURL.wrappedValue.contains("{{")
    }

    private var highlightedURL: AttributedString {
        let urlString = displayURL.wrappedValue
        var result = AttributedString()
        let pattern = try! NSRegularExpression(pattern: #"\{\{\w*\}\}"#)
        let nsString = urlString as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        let matches = pattern.matches(in: urlString, range: fullRange)

        var lastEnd = urlString.startIndex

        for match in matches {
            guard let matchRange = Range(match.range, in: urlString) else { continue }

            // Non-variable text — transparent so TextField text shows through
            if lastEnd < matchRange.lowerBound {
                var segment = AttributedString(urlString[lastEnd..<matchRange.lowerBound])
                segment.foregroundColor = .clear
                result += segment
            }

            // The {{var}} part — colored on top, hides the TextField text underneath
            var varSegment = AttributedString(urlString[matchRange])
            varSegment.foregroundColor = AppColors.brandHover
            varSegment.backgroundColor = AppColors.surfacePlus
            result += varSegment

            lastEnd = matchRange.upperBound
        }

        // Remaining text — transparent
        if lastEnd < urlString.endIndex {
            var segment = AttributedString(urlString[lastEnd...])
            segment.foregroundColor = .clear
            result += segment
        }

        return result
    }

    private var variableTooltip: String {
        VariableResolver.tooltipText(for: displayURL.wrappedValue, environment: appState.activeEnvironment) ?? ""
    }

    // MARK: - Autocomplete

    private func checkForVariableTrigger(_ url: String) {
        guard appState.activeEnvironment != nil else {
            showSuggestions = false
            return
        }

        if let openRange = url.range(of: "{{", options: .backwards) {
            let afterOpen = url[openRange.upperBound...]
            if !afterOpen.contains("}}") {
                varQuery = String(afterOpen).lowercased()
                selectedIndex = 0
                showSuggestions = true
                return
            }
        }
        showSuggestions = false
    }

    private var filteredVariables: [EnvVar] {
        guard let env = appState.activeEnvironment else { return [] }
        let enabled = env.variables.filter { $0.enabled && !$0.key.isEmpty }
        if varQuery.isEmpty { return enabled }
        return enabled.filter { $0.key.lowercased().contains(varQuery) }
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if filteredVariables.isEmpty {
                Text("No matching variables")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPlaceholder)
                    .padding(AppSpacing.md)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredVariables.enumerated()), id: \.element.id) { index, envVar in
                            Button {
                                insertVariable(envVar.key)
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Text(envVar.key)
                                        .font(AppFonts.mono)
                                        .foregroundColor(index == selectedIndex ? .white : AppColors.brand)
                                    Spacer()
                                    Text(envVar.value)
                                        .font(AppFonts.mono)
                                        .foregroundColor(index == selectedIndex ? .white.opacity(0.7) : AppColors.textTertiary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .background(index == selectedIndex ? AppColors.brand : Color.clear)
                                .cornerRadius(AppSpacing.radiusBadge)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
        }
        .frame(minWidth: 280, maxHeight: 200)
    }

    private func insertVariable(_ key: String) {
        var url = request.url
        if let openRange = url.range(of: "{{", options: .backwards) {
            url = String(url[..<openRange.lowerBound]) + "{{\(key)}}"
        }
        request.url = url
        showSuggestions = false
    }

    // MARK: - Keyboard navigation

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard showSuggestions else { return event }
            let vars = filteredVariables

            switch event.keyCode {
            case 125: // Arrow down
                if !vars.isEmpty {
                    selectedIndex = min(selectedIndex + 1, vars.count - 1)
                }
                return nil
            case 126: // Arrow up
                if !vars.isEmpty {
                    selectedIndex = max(selectedIndex - 1, 0)
                }
                return nil
            case 53: // Escape
                showSuggestions = false
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
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
