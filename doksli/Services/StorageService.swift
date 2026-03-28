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

    /// Loads workspaces, migrating from legacy format (full Request in tree) if needed.
    static func loadWorkspaces(from directory: URL = defaultStorageURL) -> [Workspace] {
        let requestsDir = directory.appendingPathComponent("requests", isDirectory: true)
        let hasMigrated = FileManager.default.fileExists(atPath: requestsDir.path)

        if hasMigrated {
            // New format: tree has RequestStubs, detail files in requests/
            return load(filename: "workspaces.json", from: directory) ?? []
        }

        // Try legacy format: tree has full Request objects
        guard let legacy: [LegacyWorkspace] = load(filename: "workspaces.json", from: directory),
              !legacy.isEmpty else {
            return load(filename: "workspaces.json", from: directory) ?? []
        }

        // Migrate: extract requests, save detail files, convert tree to stubs
        var allRequests: [Request] = []
        let migrated = legacy.map { legacyWS -> Workspace in
            let collections = legacyWS.collections.map { legacyCol -> Collection in
                Collection(
                    id: legacyCol.id,
                    name: legacyCol.name,
                    items: migrateItems(legacyCol.items, collecting: &allRequests)
                )
            }
            return Workspace(
                id: legacyWS.id,
                name: legacyWS.name,
                collections: collections,
                activeEnvironmentId: legacyWS.activeEnvironmentId
            )
        }

        // Save all request detail files first
        for request in allRequests {
            try? saveRequest(request, to: directory)
        }

        // Save migrated workspaces.json (now with stubs)
        try? save(migrated, filename: "workspaces.json", to: directory)

        return migrated
    }

    static func saveWorkspaces(_ workspaces: [Workspace], to directory: URL = defaultStorageURL) throws {
        try save(workspaces, filename: "workspaces.json", to: directory)
    }

    // MARK: - Per-request detail files

    private static func requestsDirectory(in directory: URL) -> URL {
        directory.appendingPathComponent("requests", isDirectory: true)
    }

    static func loadRequest(id: UUID, from directory: URL = defaultStorageURL) -> Request? {
        let url = requestsDirectory(in: directory)
            .appendingPathComponent("\(id.uuidString).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Request.self, from: data)
    }

    static func saveRequest(_ request: Request, to directory: URL = defaultStorageURL) throws {
        let dir = requestsDirectory(in: directory)
        try save(request, filename: "\(request.id.uuidString).json", to: dir)
    }

    static func deleteRequest(id: UUID, from directory: URL = defaultStorageURL) {
        let url = requestsDirectory(in: directory)
            .appendingPathComponent("\(id.uuidString).json")
        try? FileManager.default.removeItem(at: url)
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

    // MARK: - Legacy migration types

    private struct LegacyWorkspace: Codable {
        var id: UUID
        var name: String
        var collections: [LegacyCollection]
        var activeEnvironmentId: UUID?
    }

    private struct LegacyCollection: Codable {
        var id: UUID
        var name: String
        var items: [LegacyItem]
    }

    private struct LegacyFolder: Codable {
        var id: UUID
        var name: String
        var items: [LegacyItem]
    }

    private indirect enum LegacyItem: Codable {
        case folder(LegacyFolder)
        case request(Request)

        private enum CodingKeys: String, CodingKey {
            case type, folder, request
        }

        private enum ItemType: String, Codable {
            case folder, request
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let itemType = try container.decode(ItemType.self, forKey: .type)
            switch itemType {
            case .folder:
                self = .folder(try container.decode(LegacyFolder.self, forKey: .folder))
            case .request:
                self = .request(try container.decode(Request.self, forKey: .request))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .folder(let folder):
                try container.encode(ItemType.folder, forKey: .type)
                try container.encode(folder, forKey: .folder)
            case .request(let request):
                try container.encode(ItemType.request, forKey: .type)
                try container.encode(request, forKey: .request)
            }
        }
    }

    /// Recursively converts legacy items (full Request) to new items (RequestStub),
    /// collecting extracted Request objects for saving to individual files.
    private static func migrateItems(_ items: [LegacyItem], collecting requests: inout [Request]) -> [Item] {
        items.map { legacyItem in
            switch legacyItem {
            case .folder(let f):
                let folder = Folder(
                    id: f.id,
                    name: f.name,
                    items: migrateItems(f.items, collecting: &requests)
                )
                return .folder(folder)
            case .request(let r):
                requests.append(r)
                return .request(RequestStub(from: r))
            }
        }
    }
}
