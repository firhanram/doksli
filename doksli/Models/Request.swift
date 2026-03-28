import Foundation

// MARK: - KVPair

struct KVPair: Codable, Identifiable, Equatable {
    var id: UUID
    var key: String
    var value: String
    var enabled: Bool
    var valueType: ValueType
    var children: [KVPair]?

    static let maxNestingDepth = 4

    var isContainer: Bool { valueType == .array || valueType == .object }

    init(id: UUID = UUID(), key: String = "", value: String = "", enabled: Bool = true, valueType: ValueType = .text, children: [KVPair]? = nil) {
        self.id = id
        self.key = key
        self.value = value
        self.enabled = enabled
        self.valueType = valueType
        self.children = children
    }

    enum ValueType: String, Codable, Equatable {
        case text
        case file
        case array
        case object
    }
}

// MARK: - HTTPMethod

enum HTTPMethod: String, Codable {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
    case OPTIONS
    case HEAD
}

// MARK: - BodyMode

enum BodyMode: String, Codable, Equatable, CaseIterable {
    case none, json, formData, urlEncoded
    case raw // backward compat — decodes old data as .json

    var label: String {
        switch self {
        case .none: return "None"
        case .json, .raw: return "JSON"
        case .formData: return "Form Data"
        case .urlEncoded: return "URL Encoded"
        }
    }

    /// Normalized mode (maps .raw → .json)
    var normalized: BodyMode {
        self == .raw ? .json : self
    }
}

// MARK: - RequestBody

/// Stores all body data simultaneously so switching modes never loses data.
/// `mode` selects which data is active; `jsonBody`, `formDataPairs`, `urlEncodedPairs`
/// always retain their values.
struct RequestBody: Codable, Equatable {
    var mode: BodyMode
    var jsonBody: String
    var formDataPairs: [KVPair]
    var urlEncodedPairs: [KVPair]

    static let none = RequestBody(mode: .none)

    // MARK: - Convenience constructors (backward compat)

    static func json(_ text: String) -> RequestBody {
        RequestBody(mode: .json, jsonBody: text)
    }

    static func formData(_ pairs: [KVPair]) -> RequestBody {
        RequestBody(mode: .formData, formDataPairs: pairs)
    }

    static func urlEncoded(_ pairs: [KVPair]) -> RequestBody {
        RequestBody(mode: .urlEncoded, urlEncodedPairs: pairs)
    }

    // MARK: - Backward-compatible Codable

    private enum CodingKeys: String, CodingKey {
        case type, value
        case jsonBody, formDataPairs, urlEncodedPairs
    }

    init(mode: BodyMode, jsonBody: String = "", formDataPairs: [KVPair] = [], urlEncodedPairs: [KVPair] = []) {
        self.mode = mode.normalized
        self.jsonBody = jsonBody
        self.formDataPairs = formDataPairs
        self.urlEncodedPairs = urlEncodedPairs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // New format: has all three fields
        if let jsonBody = try container.decodeIfPresent(String.self, forKey: .jsonBody) {
            self.mode = (try container.decode(BodyMode.self, forKey: .type)).normalized
            self.jsonBody = jsonBody
            self.formDataPairs = try container.decodeIfPresent([KVPair].self, forKey: .formDataPairs) ?? []
            self.urlEncodedPairs = try container.decodeIfPresent([KVPair].self, forKey: .urlEncodedPairs) ?? []
            return
        }

        // Legacy format: { type, value }
        let bodyType = try container.decode(BodyMode.self, forKey: .type)
        self.mode = bodyType.normalized
        self.jsonBody = ""
        self.formDataPairs = []
        self.urlEncodedPairs = []

        switch bodyType {
        case .none:
            break
        case .json, .raw:
            self.jsonBody = try container.decode(String.self, forKey: .value)
        case .formData:
            self.formDataPairs = try container.decode([KVPair].self, forKey: .value)
        case .urlEncoded:
            self.urlEncodedPairs = try container.decode([KVPair].self, forKey: .value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mode, forKey: .type)
        try container.encode(jsonBody, forKey: .jsonBody)
        try container.encode(formDataPairs, forKey: .formDataPairs)
        try container.encode(urlEncodedPairs, forKey: .urlEncodedPairs)
    }
}

// MARK: - Auth

enum Auth: Codable, Equatable {
    case none
    case bearer(String)
    case basic(String, String)
    case apiKey(String, String)

    private enum CodingKeys: String, CodingKey {
        case type, token, username, password, keyName, keyValue
    }

    private enum AuthType: String, Codable {
        case none, bearer, basic, apiKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let authType = try container.decode(AuthType.self, forKey: .type)
        switch authType {
        case .none:
            self = .none
        case .bearer:
            let token = try container.decode(String.self, forKey: .token)
            self = .bearer(token)
        case .basic:
            let username = try container.decode(String.self, forKey: .username)
            let password = try container.decode(String.self, forKey: .password)
            self = .basic(username, password)
        case .apiKey:
            let keyName = try container.decode(String.self, forKey: .keyName)
            let keyValue = try container.decode(String.self, forKey: .keyValue)
            self = .apiKey(keyName, keyValue)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode(AuthType.none, forKey: .type)
        case .bearer(let token):
            try container.encode(AuthType.bearer, forKey: .type)
            try container.encode(token, forKey: .token)
        case .basic(let username, let password):
            try container.encode(AuthType.basic, forKey: .type)
            try container.encode(username, forKey: .username)
            try container.encode(password, forKey: .password)
        case .apiKey(let keyName, let keyValue):
            try container.encode(AuthType.apiKey, forKey: .type)
            try container.encode(keyName, forKey: .keyName)
            try container.encode(keyValue, forKey: .keyValue)
        }
    }
}

// MARK: - Request

struct Request: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var method: HTTPMethod
    var url: String
    var params: [KVPair]
    var headers: [KVPair]
    var body: RequestBody
    var auth: Auth
}
