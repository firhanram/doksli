import AppKit

// MARK: - GutterView

final class GutterView: NSView {

    weak var textView: NSTextView?

    /// Current diagnostics keyed by 1-based visual line number. Highest severity per line.
    var diagnosticsByLine: [Int: DiagnosticSeverity] = [:]

    private let gutterFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
    private let lineNumberColor = AppColors.NS.textFaint
    private let gutterBackground = AppColors.NS.canvas

    /// Cached diagnostic icons — avoids allocating NSImage + SymbolConfiguration on every draw().
    private static let cachedIcons: [DiagnosticSeverity: NSImage] = {
        var icons: [DiagnosticSeverity: NSImage] = [:]
        let entries: [(DiagnosticSeverity, String, NSColor)] = [
            (.error, "exclamationmark.circle.fill", AppColors.NS.errorText),
            (.warning, "exclamationmark.triangle.fill", AppColors.NS.warningText),
            (.hint, "info.circle", AppColors.NS.textFaint),
        ]
        for (severity, name, color) in entries {
            if let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
                let config = NSImage.SymbolConfiguration(pointSize: 10, weight: .regular)
                    .applying(.init(paletteColors: [color]))
                icons[severity] = image.withSymbolConfiguration(config) ?? image
            }
        }
        return icons
    }()

    /// Minimum gutter width based on line count.
    var gutterWidth: CGFloat {
        guard let textView = textView else { return 36 }
        let count = Self.lineCount(in: textView.string)
        let digitWidth = String(count).size(withAttributes: [.font: gutterFont]).width
        return max(36, digitWidth + 20)
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

        let nsString = textView.string as NSString
        let visibleRect = textView.enclosingScrollView?.documentVisibleRect ?? textView.visibleRect
        let textOrigin = textView.textContainerOrigin

        // Use logical line counting — O(1) per line, no layout enumeration for off-screen lines
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let visibleCharRange = layoutManager.characterRange(forGlyphRange: visibleGlyphRange, actualGlyphRange: nil)

        // Count logical lines before the visible range
        var startingLine = 1
        if visibleCharRange.location > 0 {
            let prefix = nsString.substring(to: visibleCharRange.location)
            for ch in prefix where ch == "\n" {
                startingLine += 1
            }
        }

        // Draw line numbers for each visible line fragment
        var lineNumber = startingLine
        var lastFragmentRect: NSRect?
        layoutManager.enumerateLineFragments(forGlyphRange: visibleGlyphRange) {
            rect, _, _, _, _ in

            let y = rect.origin.y + textOrigin.y - visibleRect.origin.y
            self.drawLineNumber(lineNumber, at: y, lineHeight: rect.height)
            self.drawDiagnosticMarker(forLine: lineNumber, at: y, lineHeight: rect.height)
            lastFragmentRect = rect
            lineNumber += 1
        }

        // Handle trailing empty line after final newline — enumerateLineFragments doesn't
        // produce a fragment for the empty line after a trailing \n
        if nsString.length > 0 && nsString.character(at: nsString.length - 1) == 0x0A {
            let lastRect = lastFragmentRect ?? .zero
            let lineHeight = lastRect.height > 0 ? lastRect.height : (gutterFont.ascender - gutterFont.descender + gutterFont.leading + 4)
            let y = lastRect.maxY + textOrigin.y - visibleRect.origin.y
            if y >= 0 && y < bounds.height {
                drawLineNumber(lineNumber, at: y, lineHeight: lineHeight)
                drawDiagnosticMarker(forLine: lineNumber, at: y, lineHeight: lineHeight)
            }
        }
    }

    // MARK: - Drawing helpers

    private func drawLineNumber(_ lineNumber: Int, at y: CGFloat, lineHeight: CGFloat) {
        let lineStr = "\(lineNumber)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: gutterFont,
            .foregroundColor: lineNumberColor
        ]
        let size = lineStr.size(withAttributes: attrs)
        let x = gutterWidth - size.width - 8
        lineStr.draw(at: NSPoint(x: x, y: y + (lineHeight - size.height) / 2),
                     withAttributes: attrs)
    }

    private func drawDiagnosticMarker(forLine lineNumber: Int, at y: CGFloat, lineHeight: CGFloat) {
        guard let severity = diagnosticsByLine[lineNumber],
              let tinted = Self.cachedIcons[severity] else { return }
        let iconSize = NSSize(width: 12, height: 12)
        let iconY = y + (lineHeight - iconSize.height) / 2
        let iconRect = NSRect(x: 2, y: iconY, width: iconSize.width, height: iconSize.height)
        tinted.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    // MARK: - Helpers

    /// Returns 1-based logical line number for a UTF-16 offset.
    func visualLineNumber(forUTF16Offset offset: Int) -> Int {
        return Self.lineNumber(forCharOffset: offset, in: textView?.string ?? "")
    }

    /// Counts total visual lines (line fragments) in the layout.
    static func visualLineCount(layoutManager: NSLayoutManager, textContainer: NSTextContainer) -> Int {
        layoutManager.ensureLayout(for: textContainer)
        let fullRange = layoutManager.glyphRange(for: textContainer)
        guard fullRange.length > 0 else { return 1 }
        var count = 0
        layoutManager.enumerateLineFragments(forGlyphRange: fullRange) { _, _, _, _, _ in
            count += 1
        }
        return max(1, count)
    }

    /// Returns 1-based logical line number for a character offset (used as fallback).
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

    /// Returns 1-based line number for a UTF-16 offset (visual if layout available, logical otherwise).
    static func lineNumber(forUTF16Offset offset: Int, in string: String) -> Int {
        return lineNumber(forCharOffset: offset, in: string)
    }

    /// Counts total logical lines in a string (fallback when no layout manager).
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
