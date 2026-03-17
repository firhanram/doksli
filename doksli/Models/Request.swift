import Foundation

// MARK: - KVPair

struct KVPair: Codable, Identifiable, Equatable {
    var id: UUID
    var key: String
    var value: String
    var enabled: Bool
    var valueType: ValueType

    init(id: UUID = UUID(), key: String = "", value: String = "", enabled: Bool = true, valueType: ValueType = .text) {
        self.id = id
        self.key = key
        self.value = value
        self.enabled = enabled
        self.valueType = valueType
    }

    enum ValueType: String, Codable, Equatable {
        case text
        case file
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

// MARK: - RequestBody

enum RequestBody: Codable, Equatable {
    case none
    case raw(String)
    case formData([KVPair])
    case urlEncoded([KVPair])

    private enum CodingKeys: String, CodingKey {
        case type, value
    }

    private enum BodyType: String, Codable {
        case none, raw, formData, urlEncoded
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bodyType = try container.decode(BodyType.self, forKey: .type)
        switch bodyType {
        case .none:
            self = .none
        case .raw:
            let string = try container.decode(String.self, forKey: .value)
            self = .raw(string)
        case .formData:
            let pairs = try container.decode([KVPair].self, forKey: .value)
            self = .formData(pairs)
        case .urlEncoded:
            let pairs = try container.decode([KVPair].self, forKey: .value)
            self = .urlEncoded(pairs)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode(BodyType.none, forKey: .type)
        case .raw(let string):
            try container.encode(BodyType.raw, forKey: .type)
            try container.encode(string, forKey: .value)
        case .formData(let pairs):
            try container.encode(BodyType.formData, forKey: .type)
            try container.encode(pairs, forKey: .value)
        case .urlEncoded(let pairs):
            try container.encode(BodyType.urlEncoded, forKey: .type)
            try container.encode(pairs, forKey: .value)
        }
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
