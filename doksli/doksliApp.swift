//
//  doksliApp.swift
//  doksli
//
//  Created by Firhan Ramadhan on 16/03/26.
//

import SwiftUI

@main
struct doksliApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var shortcutStore = ShortcutStore()

    init() {
        setupStorageDirectory()

        // Disable smart quotes/dashes so JSON and code stay valid
        UserDefaults.standard.set(false, forKey: "NSAutomaticQuoteSubstitutionEnabled")
        UserDefaults.standard.set(false, forKey: "NSAutomaticDashSubstitutionEnabled")
        UserDefaults.standard.set(false, forKey: "NSAutomaticTextReplacementEnabled")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(shortcutStore)
                .preferredColorScheme(appState.preferredScheme)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                shortcutButton(.newRequest, "New Request") { appState.addNewRequest() }
                shortcutButton(.newFolder, "New Folder") { appState.addNewFolder() }
                Divider()
                shortcutButton(.newWorkspace, "New Workspace") { appState.showCreateWorkspace = true }
            }

            CommandGroup(after: .sidebar) {
                shortcutButton(.toggleSidebar, "Toggle Sidebar") {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(
                        #selector(NSSplitViewController.toggleSidebar(_:)), with: nil
                    )
                }
            }

            CommandMenu("View") {
                shortcutButton(.settings, "Settings...") { appState.showSettings = true }
            }

            CommandMenu("Request") {
                shortcutButton(.sendRequest, "Send Request") { appState.sendCurrentRequest() }
                shortcutButton(.duplicateRequest, "Duplicate Request") { appState.duplicateSelectedRequest() }
                Divider()
                shortcutButton(.quickSearch, "Quick Search") { appState.showQuickSearch = true }
                shortcutButton(.clearResponse, "Clear Response") { appState.clearResponse() }
                shortcutButton(.environments, "Environments") { appState.showEnvEditor = true }
            }
        }
    }

    @ViewBuilder
    private func shortcutButton(_ action: ShortcutAction, _ label: String, perform: @escaping () -> Void) -> some View {
        let ks = shortcutStore.shortcut(for: action)
        if let key = ks.swiftUIKey {
            Button(label, action: perform)
                .keyboardShortcut(key, modifiers: ks.swiftUIModifiers)
        } else {
            Button(label, action: perform)
        }
    }

    private func setupStorageDirectory() {
        let fm = FileManager.default
        let storageURL = fm.homeDirectoryForCurrentUser
            .appendingPathComponent(".doksli/v1", isDirectory: true)
        try? fm.createDirectory(at: storageURL, withIntermediateDirectories: true)
        let versionURL = storageURL.appendingPathComponent("VERSION")
        if !fm.fileExists(atPath: versionURL.path) {
            try? "1".write(to: versionURL, atomically: true, encoding: .utf8)
        }
    }
}
