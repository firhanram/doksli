import Foundation

// MARK: - Item

indirect enum Item: Codable {
    case folder(Folder)
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
            let folder = try container.decode(Folder.self, forKey: .folder)
            self = .folder(folder)
        case .request:
            let request = try container.decode(Request.self, forKey: .request)
            self = .request(request)
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

// MARK: - Folder

struct Folder: Codable, Identifiable {
    var id: UUID
    var name: String
    var items: [Item]
}

// MARK: - Collection

struct Collection: Codable, Identifiable {
    var id: UUID
    var name: String
    var items: [Item]
}

// MARK: - Workspace

struct Workspace: Codable, Identifiable {
    var id: UUID
    var name: String
    var collections: [Collection]
}
