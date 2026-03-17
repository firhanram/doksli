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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
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
