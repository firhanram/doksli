import SwiftUI

// MARK: - URLBarView

struct URLBarView: View {
    @Binding var request: Request
    @EnvironmentObject var appState: AppState
    @State private var showSuggestions = false
    @State private var varQuery = ""
    @State private var selectedIndex = 0
    @State private var keyMonitor: Any? = nil
    @State private var showMethodPicker = false
    @State private var hoveredMethod: HTTPMethod? = nil
    @State private var methodKeyMonitor: Any? = nil
    @State private var methodSelectedIndex = 0

    private let allMethods: [HTTPMethod] = [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS, .HEAD]

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
        Button {
            if showMethodPicker {
                closeMethodPicker()
            } else {
                openMethodPicker()
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                MethodBadge(method: request.method)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showMethodPicker, arrowEdge: .bottom) {
            methodDropdown
        }
        .onChange(of: showMethodPicker) { showing in
            if !showing {
                closeMethodPicker()
            }
        }
    }

    private var methodDropdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(allMethods.enumerated()), id: \.element) { index, method in
                let isSelected = request.method == method
                let isHighlighted = methodSelectedIndex == index

                Button {
                    request.method = method
                    closeMethodPicker()
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Circle()
                            .fill(methodColor(method))
                            .frame(width: 8, height: 8)
                        Text(method.rawValue)
                            .font(AppFonts.mono)
                            .fontWeight(isSelected ? .medium : .regular)
                            .foregroundColor(isHighlighted ? .white : isSelected ? AppColors.brand : AppColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(isHighlighted ? AppColors.brand : isSelected ? AppColors.brandTint50 : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        methodSelectedIndex = index
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .frame(width: 120)
    }

    private func methodColor(_ method: HTTPMethod) -> Color {
        switch method {
        case .GET:     return AppColors.methodGet.text
        case .POST:    return AppColors.methodPost.text
        case .PUT:     return AppColors.methodPut.text
        case .PATCH:   return AppColors.methodPatch.text
        case .DELETE:  return AppColors.methodDelete.text
        case .OPTIONS: return AppColors.methodOptions.text
        case .HEAD:    return AppColors.methodHead.text
        }
    }

    private func openMethodPicker() {
        methodSelectedIndex = allMethods.firstIndex(of: request.method) ?? 0
        showMethodPicker = true
        methodKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 125: // Arrow down
                methodSelectedIndex = min(methodSelectedIndex + 1, allMethods.count - 1)
                return nil
            case 126: // Arrow up
                methodSelectedIndex = max(methodSelectedIndex - 1, 0)
                return nil
            case 36: // Enter
                request.method = allMethods[methodSelectedIndex]
                closeMethodPicker()
                return nil
            case 53: // Escape
                closeMethodPicker()
                return nil
            default:
                return event
            }
        }
    }

    private func closeMethodPicker() {
        showMethodPicker = false
        if let monitor = methodKeyMonitor {
            NSEvent.removeMonitor(monitor)
            methodKeyMonitor = nil
        }
    }

    // MARK: - URL field

    private var displayURL: Binding<String> {
        Binding(
            get: {
                let base = request.url
                let flatParams = HTTPClient.flattenPairs(request.params)
                guard !flatParams.isEmpty else { return base }
                let queryString = flatParams
                    .map { "\($0.name)=\($0.pair.value)" }
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
                    .lineLimit(1)
                    .allowsHitTesting(false)
            }

            // Actual editable TextField
            TextField("Enter URL...", text: displayURL)
                .font(AppFonts.mono)
                .textFieldStyle(.plain)
                .lineLimit(1)
                .truncationMode(.tail)
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
        appState.sendCurrentRequest()
    }
}
