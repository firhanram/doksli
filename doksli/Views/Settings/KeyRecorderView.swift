import AppKit
import SwiftUI

// MARK: - KeyRecorderOverlay

struct KeyRecorderOverlay: ViewModifier {
    @Binding var recordingAction: ShortcutAction?
    var store: ShortcutStore

    func body(content: Content) -> some View {
        content
            .onAppear { KeyEventMonitor.shared.store = store }
            .onChange(of: recordingAction) { newValue in
                if let action = newValue {
                    KeyEventMonitor.shared.startRecording(for: action) { recorded in
                        if recorded {
                            // Force UI refresh
                            store.objectWillChange.send()
                        }
                        recordingAction = nil
                    }
                } else {
                    KeyEventMonitor.shared.stopRecording()
                }
            }
            .onDisappear {
                KeyEventMonitor.shared.stopRecording()
                recordingAction = nil
            }
    }
}

// MARK: - KeyEventMonitor

class KeyEventMonitor {
    static let shared = KeyEventMonitor()

    var store: ShortcutStore?
    private var monitor: Any?
    private var currentAction: ShortcutAction?
    private var completion: ((Bool) -> Void)?

    func startRecording(for action: ShortcutAction, completion: @escaping (Bool) -> Void) {
        stopRecording()
        currentAction = action
        self.completion = completion

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Escape cancels
            if event.keyCode == 53 {
                let cb = self.completion
                self.stopRecording()
                cb?(false)
                return nil
            }

            let modifiers = ShortcutModifiers.from(nsFlags: event.modifierFlags)

            // Require at least one modifier
            guard modifiers.contains(.command) || modifiers.contains(.control) || modifiers.contains(.option) else {
                return nil
            }

            guard let key = self.shortcutKey(from: event),
                  let action = self.currentAction else { return nil }

            let shortcut = KeyShortcut(key: key, modifiers: modifiers)
            self.store?.setShortcut(shortcut, for: action)

            let cb = self.completion
            self.stopRecording()
            cb?(true)
            return nil
        }
    }

    func stopRecording() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        currentAction = nil
        completion = nil
    }

    private func shortcutKey(from event: NSEvent) -> ShortcutKey? {
        switch event.keyCode {
        case 36:  return .return
        case 51:  return .delete
        case 48:  return .tab
        case 49:  return .space
        case 126: return .upArrow
        case 125: return .downArrow
        case 123: return .leftArrow
        case 124: return .rightArrow
        default:
            if let chars = event.charactersIgnoringModifiers?.lowercased(), !chars.isEmpty {
                let char = String(chars.prefix(1))
                if char.unicodeScalars.allSatisfy({ $0.value >= 32 && $0.value < 127 }) {
                    return .character(char)
                }
            }
            return nil
        }
    }
}
