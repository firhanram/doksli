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
                .preferredColorScheme(.light)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Request") { appState.addNewRequest() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("New Folder") { appState.addNewFolder() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                Divider()
                Button("New Workspace") { appState.createWorkspace() }
                    .keyboardShortcut("w", modifiers: [.command, .shift])
            }

            CommandMenu("Request") {
                Button("Send Request") { appState.sendCurrentRequest() }
                    .keyboardShortcut(.return, modifiers: .command)
                Button("Duplicate Request") { appState.duplicateSelectedRequest() }
                    .keyboardShortcut("d", modifiers: .command)
                Divider()
                Button("Clear Response") { appState.clearResponse() }
                    .keyboardShortcut("k", modifiers: .command)
                Button("Environments") { appState.showEnvEditor = true }
                    .keyboardShortcut("e", modifiers: .command)
            }
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
