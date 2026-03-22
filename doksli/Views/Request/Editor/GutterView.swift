import AppKit

// MARK: - GutterView

final class GutterView: NSView {

    weak var textView: NSTextView?

    /// Current diagnostics keyed by 1-based line number. Highest severity per line.
    var diagnosticsByLine: [Int: DiagnosticSeverity] = [:]

    private let gutterFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
    private let lineNumberColor = AppColors.NS.textFaint
    private let gutterBackground = AppColors.NS.canvas

    /// Minimum gutter width.
    var gutterWidth: CGFloat {
        guard let textView = textView else { return 36 }
        let lineCount = Self.lineCount(in: textView.string)
        let digitWidth = String(lineCount).size(withAttributes: [.font: gutterFont]).width
        return max(36, digitWidth + 20) // 12 left padding + 8 right padding
    }

    /// Called when the text view scrolls or text changes.
    func invalidate() {
        needsDisplay = true
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        gutterBackground.setFill()
        dirtyRect.fill()

        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let visibleRect = textView.enclosingScrollView?.documentVisibleRect ?? textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        let string = textView.string
        let nsString = string as NSString
        let textOrigin = textView.textContainerOrigin

        var lineNumber = Self.lineNumber(forCharOffset: charRange.location, in: string)

        var index = charRange.location
        while index < NSMaxRange(charRange) {
            let lineRange = nsString.lineRange(for: NSRange(location: index, length: 0))

            let glyphIdx = layoutManager.glyphIndexForCharacter(at: lineRange.location)
            var lineRect = NSRect.zero
            layoutManager.lineFragmentRect(forGlyphAt: glyphIdx, effectiveRange: nil,
                                           withoutAdditionalLayout: true)
            lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIdx, effectiveRange: nil)

            let y = lineRect.origin.y + textOrigin.y - visibleRect.origin.y

            // Draw line number
            let lineStr = "\(lineNumber)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: gutterFont,
                .foregroundColor: lineNumberColor
            ]
            let size = lineStr.size(withAttributes: attrs)
            let x = gutterWidth - size.width - 8
            lineStr.draw(at: NSPoint(x: x, y: y + (lineRect.height - size.height) / 2),
                         withAttributes: attrs)

            // Draw diagnostic marker
            if let severity = diagnosticsByLine[lineNumber] {
                let iconName: String
                let iconColor: NSColor
                switch severity {
                case .error:
                    iconName = "exclamationmark.circle.fill"
                    iconColor = AppColors.NS.errorText
                case .warning:
                    iconName = "exclamationmark.triangle.fill"
                    iconColor = AppColors.NS.warningText
                case .hint:
                    iconName = "info.circle"
                    iconColor = AppColors.NS.textFaint
                }
                if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
                    let config = NSImage.SymbolConfiguration(pointSize: 10, weight: .regular)
                    let tinted = image.withSymbolConfiguration(config) ?? image
                    let iconSize = NSSize(width: 12, height: 12)
                    let iconY = y + (lineRect.height - iconSize.height) / 2
                    let iconRect = NSRect(x: 2, y: iconY, width: iconSize.width, height: iconSize.height)
                    iconColor.set()
                    tinted.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
                }
            }

            lineNumber += 1
            index = NSMaxRange(lineRange)
        }
    }

    // MARK: - Helpers

    /// Returns 1-based line number for a character offset in a string.
    static func lineNumber(forCharOffset offset: Int, in string: String) -> Int {
        guard offset > 0 else { return 1 }
        let nsString = string as NSString
        let searchEnd = min(offset, nsString.length)
        var line = 1
        var i = 0
        while i < searchEnd {
            let lineRange = nsString.lineRange(for: NSRange(location: i, length: 0))
            if NSMaxRange(lineRange) <= offset {
                line += 1
            }
            i = NSMaxRange(lineRange)
        }
        return line
    }

    /// Returns 1-based line number for a UTF-16 offset.
    static func lineNumber(forUTF16Offset offset: Int, in string: String) -> Int {
        return lineNumber(forCharOffset: offset, in: string)
    }

    /// Counts total lines in a string.
    static func lineCount(in string: String) -> Int {
        guard !string.isEmpty else { return 1 }
        let nsString = string as NSString
        var count = 0
        var i = 0
        while i < nsString.length {
            let lineRange = nsString.lineRange(for: NSRange(location: i, length: 0))
            count += 1
            i = NSMaxRange(lineRange)
        }
        return count
    }
}
