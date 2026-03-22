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

        // Update text if changed externally (e.g., format button)
        if textStorage.string != text && !coordinator.isUpdatingFromBinding {
            coordinator.isUpdatingFromSwiftUI = true
            let selectedRanges = textView.selectedRanges
            textStorage.replaceCharacters(
                in: NSRange(location: 0, length: textStorage.length),
                with: text
            )
            SyntaxHighlighter.apply(tokens: tokens, to: textStorage)
            // Restore selection if possible
            for range in selectedRanges {
                let r = range.rangeValue
                if r.location + r.length <= textStorage.length {
                    textView.setSelectedRange(r)
                }
            }
            coordinator.isUpdatingFromSwiftUI = false
        } else {
            // Just update highlighting and diagnostics
            SyntaxHighlighter.apply(tokens: tokens, to: textStorage)
        }

        // Update gutter
        if let gutter = coordinator.gutterView {
            let markers = JSONEditorBridge.gutterMarkers(from: diagnostics, in: text)
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

        /// Prevents feedback loop when binding update triggers updateNSView.
        var isUpdatingFromBinding = false

        init(parent: EditorEngine) {
            self.parent = parent
        }

        // MARK: NSTextViewDelegate

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromSwiftUI,
                  let textView = textView,
                  let textStorage = textView.textStorage else { return }

            isUpdatingFromBinding = true
            parent.text = textStorage.string
            isUpdatingFromBinding = false

            gutterView?.invalidate()
        }

        // MARK: Scroll sync

        @objc func scrollViewDidScroll(_ notification: Notification) {
            gutterView?.invalidate()
        }
    }
}
