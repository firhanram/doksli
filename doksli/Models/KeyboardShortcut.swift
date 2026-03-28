import SwiftUI

// MARK: - ShortcutAction

enum ShortcutAction: String, CaseIterable, Identifiable, Codable {
    case sendRequest
    case newRequest
    case newFolder
    case newWorkspace
    case duplicateRequest
    case quickSearch
    case clearResponse
    case environments
    case toggleSidebar
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sendRequest:      return "Send Request"
        case .newRequest:       return "New Request"
        case .newFolder:        return "New Folder"
        case .newWorkspace:     return "New Workspace"
        case .duplicateRequest: return "Duplicate Request"
        case .quickSearch:      return "Quick Search"
        case .clearResponse:    return "Clear Response"
        case .environments:     return "Environments"
        case .toggleSidebar:    return "Toggle Sidebar"
        case .settings:         return "Settings"
        }
    }

    var defaultShortcut: KeyShortcut {
        switch self {
        case .sendRequest:      return KeyShortcut(key: .return, modifiers: .command)
        case .newRequest:       return KeyShortcut(key: .character("n"), modifiers: .command)
        case .newFolder:        return KeyShortcut(key: .character("n"), modifiers: [.command, .shift])
        case .newWorkspace:     return KeyShortcut(key: .character("w"), modifiers: [.command, .shift])
        case .duplicateRequest: return KeyShortcut(key: .character("d"), modifiers: .command)
        case .quickSearch:      return KeyShortcut(key: .character("p"), modifiers: .command)
        case .clearResponse:    return KeyShortcut(key: .character("k"), modifiers: .command)
        case .environments:     return KeyShortcut(key: .character("e"), modifiers: .command)
        case .toggleSidebar:    return KeyShortcut(key: .character("b"), modifiers: .command)
        case .settings:         return KeyShortcut(key: .character(","), modifiers: .command)
        }
    }
}

// MARK: - KeyShortcut

struct KeyShortcut: Codable, Equatable {
    var key: ShortcutKey
    var modifiers: ShortcutModifiers

    var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("\u{2303}") }
        if modifiers.contains(.option)  { parts.append("\u{2325}") }
        if modifiers.contains(.shift)   { parts.append("\u{21E7}") }
        if modifiers.contains(.command) { parts.append("\u{2318}") }
        parts.append(key.displayString)
        return parts.joined(separator: " ")
    }

    var swiftUIKey: KeyEquivalent? {
        switch key {
        case .character(let c): return KeyEquivalent(Character(c))
        case .return:           return .return
        case .delete:           return .delete
        case .escape:           return .escape
        case .tab:              return .tab
        case .space:            return KeyEquivalent(" ")
        case .upArrow:          return .upArrow
        case .downArrow:        return .downArrow
        case .leftArrow:        return .leftArrow
        case .rightArrow:       return .rightArrow
        }
    }

    var swiftUIModifiers: EventModifiers {
        var result: EventModifiers = []
        if modifiers.contains(.command) { result.insert(.command) }
        if modifiers.contains(.shift)   { result.insert(.shift) }
        if modifiers.contains(.option)  { result.insert(.option) }
        if modifiers.contains(.control) { result.insert(.control) }
        return result
    }
}

// MARK: - ShortcutKey

enum ShortcutKey: Codable, Equatable {
    case character(String)
    case `return`
    case delete
    case escape
    case tab
    case space
    case upArrow
    case downArrow
    case leftArrow
    case rightArrow

    var displayString: String {
        switch self {
        case .character(let c): return c.uppercased()
        case .return:           return "\u{21A9}"
        case .delete:           return "\u{232B}"
        case .escape:           return "\u{238B}"
        case .tab:              return "\u{21E5}"
        case .space:            return "\u{2423}"
        case .upArrow:          return "\u{2191}"
        case .downArrow:        return "\u{2193}"
        case .leftArrow:        return "\u{2190}"
        case .rightArrow:       return "\u{2192}"
        }
    }
}

// MARK: - ShortcutModifiers

struct ShortcutModifiers: OptionSet, Codable, Equatable {
    let rawValue: Int

    static let command = ShortcutModifiers(rawValue: 1 << 0)
    static let shift   = ShortcutModifiers(rawValue: 1 << 1)
    static let option  = ShortcutModifiers(rawValue: 1 << 2)
    static let control = ShortcutModifiers(rawValue: 1 << 3)

    static func from(nsFlags: NSEvent.ModifierFlags) -> ShortcutModifiers {
        var result = ShortcutModifiers()
        if nsFlags.contains(.command) { result.insert(.command) }
        if nsFlags.contains(.shift)   { result.insert(.shift) }
        if nsFlags.contains(.option)  { result.insert(.option) }
        if nsFlags.contains(.control) { result.insert(.control) }
        return result
    }
}

// MARK: - ShortcutStore

class ShortcutStore: ObservableObject {
    @Published var customShortcuts: [ShortcutAction: KeyShortcut] = [:]

    private static let userDefaultsKey = "customKeyboardShortcuts"

    init() {
        load()
    }

    func shortcut(for action: ShortcutAction) -> KeyShortcut {
        customShortcuts[action] ?? action.defaultShortcut
    }

    func setShortcut(_ shortcut: KeyShortcut, for action: ShortcutAction) {
        customShortcuts[action] = shortcut
        save()
    }

    func resetToDefault(for action: ShortcutAction) {
        customShortcuts.removeValue(forKey: action)
        save()
    }

    func resetAll() {
        customShortcuts.removeAll()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(customShortcuts) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
              let decoded = try? JSONDecoder().decode([ShortcutAction: KeyShortcut].self, from: data)
        else { return }
        customShortcuts = decoded
    }
}
