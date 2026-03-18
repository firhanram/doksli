import Foundation

// MARK: - StorageService

struct StorageService {

    private static let historyLimit = 100

    // MARK: - Default storage URL

    static var defaultStorageURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".doksli/v1", isDirectory: true)
    }

    // MARK: - Workspaces

    static func loadWorkspaces(from directory: URL = defaultStorageURL) -> [Workspace] {
        load(filename: "workspaces.json", from: directory) ?? []
    }

    static func saveWorkspaces(_ workspaces: [Workspace], to directory: URL = defaultStorageURL) throws {
        try save(workspaces, filename: "workspaces.json", to: directory)
    }

    // MARK: - Environments

    static func loadEnvironments(from directory: URL = defaultStorageURL) -> [Environment] {
        load(filename: "environments.json", from: directory) ?? []
    }

    static func saveEnvironments(_ environments: [Environment], to directory: URL = defaultStorageURL) throws {
        try save(environments, filename: "environments.json", to: directory)
    }

    // MARK: - Response cache

    static func loadResponseCache(from directory: URL = defaultStorageURL) -> [UUID: Response] {
        load(filename: "responses.json", from: directory) ?? [:]
    }

    static func saveResponseCache(_ cache: [UUID: Response], to directory: URL = defaultStorageURL) throws {
        try save(cache, filename: "responses.json", to: directory)
    }

    // MARK: - History (ring buffer, newest-first, capped at 100)

    static func loadHistory(from directory: URL = defaultStorageURL) -> [HistoryEntry] {
        load(filename: "history.json", from: directory) ?? []
    }

    static func appendHistory(_ entry: HistoryEntry, to directory: URL = defaultStorageURL) throws {
        var entries = loadHistory(from: directory)
        entries.insert(entry, at: 0)
        if entries.count > historyLimit {
            entries = Array(entries.prefix(historyLimit))
        }
        try save(entries, filename: "history.json", to: directory)
    }

    // MARK: - Generic helpers

    private static func load<T: Decodable>(filename: String, from directory: URL) -> T? {
        let url = directory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func save<T: Encodable>(_ value: T, filename: String, to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(value)
        let target = directory.appendingPathComponent(filename)
        let temp = directory.appendingPathComponent(filename + ".tmp")
        try data.write(to: temp)
        if FileManager.default.fileExists(atPath: target.path) {
            _ = try FileManager.default.replaceItemAt(target, withItemAt: temp)
        } else {
            try FileManager.default.moveItem(at: temp, to: target)
        }
    }
}
