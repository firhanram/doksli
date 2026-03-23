import SwiftUI
import AppKit

// MARK: - EditorEngine

struct EditorEngine: NSViewRepresentable {
    @Binding var text: String
    var tokens: [JSONToken]
    var diagnostics: [JSONDiagnostic]

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSView {
        // Container holds gutter + scroll view side by side
        let container = NSView()
        container.wantsLayer = true

        // --- Text system ---
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        textContainer.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        layoutManager.addTextContainer(textContainer)

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.font = SyntaxHighlighter.font
        textView.textColor = AppColors.NS.textPrimary
        textView.backgroundColor = AppColors.NS.surfacePlus
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.delegate = context.coordinator

        // --- Scroll view ---
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = AppColors.NS.surfacePlus
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // --- Gutter ---
        let gutter = GutterView()
        gutter.textView = textView
        gutter.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(gutter)
        container.addSubview(scrollView)

        let gutterW = gutter.gutterWidth
        let gutterWidthConstraint = gutter.widthAnchor.constraint(equalToConstant: gutterW)

        NSLayoutConstraint.activate([
            // Gutter: left column, full height
            gutter.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            gutter.topAnchor.constraint(equalTo: container.topAnchor),
            gutter.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            gutterWidthConstraint,

            // Scroll view: fills remaining width
            scrollView.leadingAnchor.constraint(equalTo: gutter.trailingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        // Store references
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.gutterView = gutter
        context.coordinator.gutterWidthConstraint = gutterWidthConstraint
        context.coordinator.containerView = container
        textStorage.delegate = context.coordinator

        // Set initial text
        context.coordinator.isUpdatingFromSwiftUI = true
        textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: text)
        SyntaxHighlighter.apply(tokens: tokens, to: textStorage)
        context.coordinator.isUpdatingFromSwiftUI = false

        // Observe scroll for gutter sync
        if let clipView = scrollView.contentView as? NSClipView {
            clipView.postsBoundsChangedNotifications = true
            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(Coordinator.scrollViewDidScroll),
                name: NSView.boundsDidChangeNotification,
                object: clipView
            )
        }

        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        guard let textView = context.coordinator.textView,
              let textStorage = textView.textStorage else { return }

        let coordinator = context.coordinator

        // Sync check: when textStorage matches the binding, pending edits are resolved.
        if textStorage.string == text {
            coordinator.hasPendingEdits = false
        } else if !coordinator.hasPendingEdits {
            // No pending user edits and text differs — this is an external change
            // (e.g., switching requests). Replace the editor content.
            coordinator.isUpdatingFromSwiftUI = true
            let selectedRanges = textView.selectedRanges
            textStorage.replaceCharacters(
                in: NSRange(location: 0, length: textStorage.length),
                with: text
            )
            SyntaxHighlighter.apply(tokens: tokens, to: textStorage)
            for range in selectedRanges {
                let r = range.rangeValue
                if r.location + r.length <= textStorage.length {
                    textView.setSelectedRange(r)
                }
            }
            coordinator.isUpdatingFromSwiftUI = false
            coordinator.lastAppliedTokens = tokens
        }

        // Apply highlighting only when tokens actually change (after debounced analysis)
        if coordinator.lastAppliedTokens != tokens {
            coordinator.lastAppliedTokens = tokens
            coordinator.scheduleHighlight()
        }

        // Update gutter
        if let gutter = coordinator.gutterView {
            let markers = JSONEditorBridge.gutterMarkers(from: diagnostics, in: text, gutter: gutter)
            gutter.diagnosticsByLine = markers

            // Update gutter width if line count changed
            let newWidth = gutter.gutterWidth
            if let constraint = coordinator.gutterWidthConstraint,
               constraint.constant != newWidth {
                constraint.constant = newWidth
            }

            gutter.invalidate()
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextStorageDelegate, NSTextViewDelegate {
        var parent: EditorEngine
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        weak var gutterView: GutterView?
        weak var containerView: NSView?
        var gutterWidthConstraint: NSLayoutConstraint?

        /// Prevents feedback loop when SwiftUI updates the text binding.
        var isUpdatingFromSwiftUI = false

        /// True when user has edited text that hasn't been fully synced to the binding yet.
        /// Prevents updateNSView from replacing text with a stale binding value.
        var hasPendingEdits = false

        /// Last tokens applied to avoid redundant highlighting.
        var lastAppliedTokens: [JSONToken] = []

        /// Debounced highlight work item.
        private var highlightWorkItem: DispatchWorkItem?

        /// Debounced binding sync work item.
        private var bindingSyncWorkItem: DispatchWorkItem?

        init(parent: EditorEngine) {
            self.parent = parent
        }

        /// Schedules syntax highlighting with a short debounce to avoid blocking input.
        func scheduleHighlight() {
            highlightWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self, let textView = self.textView,
                      let textStorage = textView.textStorage else { return }
                SyntaxHighlighter.apply(tokens: self.lastAppliedTokens, to: textStorage)
            }
            highlightWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
        }

        /// Debounces the SwiftUI binding update to avoid re-render on every keystroke.
        private func scheduleBindingSync() {
            bindingSyncWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self, let textView = self.textView,
                      let textStorage = textView.textStorage else { return }
                self.parent.text = textStorage.string
            }
            bindingSyncWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
        }

        // MARK: NSTextViewDelegate — commands

        func textView(_ textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) {
                return handleNewline(textView)
            }
            if selector == #selector(NSResponder.insertTab(_:)) {
                textView.insertText("    ", replacementRange: textView.selectedRange())
                return true
            }
            return false
        }

        // MARK: NSTextViewDelegate — auto-close pairs

        func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange,
                       replacementString replacement: String?) -> Bool {
            guard let replacement = replacement, replacement.count == 1,
                  let ch = replacement.first else { return true }

            let nsString = (textView.string as NSString)
            let nextChar: Character? = range.location < nsString.length
                ? Character(UnicodeScalar(nsString.character(at: range.location))!)
                : nil

            // Skip-over closing character
            if (ch == "}" || ch == "]" || ch == "\""), nextChar == ch, range.length == 0 {
                textView.setSelectedRange(NSRange(location: range.location + 1, length: 0))
                return false
            }

            // Auto-close pairs
            let pair: String? = {
                switch ch {
                case "{": return "{}"
                case "[": return "[]"
                case "\"":
                    // Don't auto-close if inside a string token
                    if isInsideString(at: range.location) { return nil }
                    return "\"\""
                default: return nil
                }
            }()

            if let pair = pair, range.length == 0 {
                if textView.shouldChangeText(in: range, replacementString: pair) {
                    textView.replaceCharacters(in: range, with: pair)
                    textView.didChangeText()
                    textView.setSelectedRange(NSRange(location: range.location + 1, length: 0))
                }
                return false
            }

            // Auto-dedent closing bracket at line start
            if (ch == "}" || ch == "]"), range.length == 0 {
                let lineStart = nsString.lineRange(for: NSRange(location: range.location, length: 0)).location
                let prefix = nsString.substring(with: NSRange(location: lineStart, length: range.location - lineStart))
                if prefix.allSatisfy({ $0 == " " }) && prefix.count >= 4 {
                    let dedentRange = NSRange(location: lineStart, length: min(4, prefix.count))
                    if textView.shouldChangeText(in: dedentRange, replacementString: "") {
                        textView.replaceCharacters(in: dedentRange, with: "")
                        textView.didChangeText()
                    }
                }
            }

            return true
        }

        // MARK: NSTextViewDelegate — text changed

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromSwiftUI else { return }

            // Mark that we have unsynced edits — prevents updateNSView from
            // replacing text with a stale binding value during rapid typing.
            hasPendingEdits = true

            // Debounce the SwiftUI binding update to avoid blocking input
            scheduleBindingSync()

            // Ensure cursor stays visible after text changes
            if let textView = textView {
                textView.scrollRangeToVisible(textView.selectedRange())
            }

            gutterView?.invalidate()
        }

        // MARK: Scroll sync

        @objc func scrollViewDidScroll(_ notification: Notification) {
            gutterView?.invalidate()
        }

        // MARK: - Auto-indent helpers

        private func handleNewline(_ textView: NSTextView) -> Bool {
            let nsString = (textView.string as NSString)
            let pos = textView.selectedRange().location

            // Get current line's leading whitespace
            let lineRange = nsString.lineRange(for: NSRange(location: pos, length: 0))
            let lineStart = lineRange.location
            var wsEnd = lineStart
            while wsEnd < nsString.length {
                let c = nsString.character(at: wsEnd)
                if c == 0x20 || c == 0x09 { wsEnd += 1 } else { break } // space or tab
            }
            let currentIndent = nsString.substring(with: NSRange(location: lineStart, length: wsEnd - lineStart))

            // Check char before cursor on this line only
            let before = nonWhitespaceChar(in: nsString, before: pos, limit: lineStart)
            // Check char after cursor (skip whitespace)
            let after = nonWhitespaceChar(in: nsString, after: pos)

            let shouldIncrease = (before == "{" || before == "[")
            let shouldSplit = shouldIncrease && (after == "}" || after == "]")

            if shouldSplit {
                // Insert: \n + indent+4 + \n + indent, cursor on middle line
                let innerIndent = currentIndent + "    "
                let insertion = "\n" + innerIndent + "\n" + currentIndent
                let cursorPos = pos + 1 + innerIndent.count // after first \n + innerIndent
                if textView.shouldChangeText(in: textView.selectedRange(), replacementString: insertion) {
                    textView.replaceCharacters(in: textView.selectedRange(), with: insertion)
                    textView.didChangeText()
                    textView.setSelectedRange(NSRange(location: cursorPos, length: 0))
                    textView.scrollRangeToVisible(NSRange(location: cursorPos, length: 0))
                }
            } else {
                let indent = shouldIncrease ? currentIndent + "    " : currentIndent
                let insertion = "\n" + indent
                textView.insertText(insertion, replacementRange: textView.selectedRange())
                textView.scrollRangeToVisible(textView.selectedRange())
            }

            return true
        }

        /// Returns the first non-whitespace character before `location`, or nil.
        /// When `limit` is provided, stops searching at that position (inclusive).
        private func nonWhitespaceChar(in nsString: NSString, before location: Int, limit: Int = 0) -> Character? {
            var i = location - 1
            while i >= limit {
                let c = nsString.character(at: i)
                if c != 0x20 && c != 0x09 && c != 0x0A && c != 0x0D { // not space/tab/newline
                    return Character(UnicodeScalar(c)!)
                }
                i -= 1
            }
            return nil
        }

        /// Returns the first non-whitespace character at or after `location`, or nil.
        private func nonWhitespaceChar(in nsString: NSString, after location: Int) -> Character? {
            var i = location
            while i < nsString.length {
                let c = nsString.character(at: i)
                if c != 0x20 && c != 0x09 && c != 0x0A && c != 0x0D {
                    return Character(UnicodeScalar(c)!)
                }
                i += 1
            }
            return nil
        }

        /// Checks if `location` is inside a string token.
        private func isInsideString(at location: Int) -> Bool {
            for token in parent.tokens where token.kind == .string {
                // Inside means between the opening and closing quotes (exclusive of both)
                if location > token.span.start && location < token.span.end {
                    return true
                }
            }
            return false
        }
    }
}
