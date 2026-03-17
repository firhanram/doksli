import Testing
import Foundation
@testable import doksli

// MARK: - Workspace + Collection + Item round-trip

@Test func workspaceRoundTrip() throws {
    let original = Workspace(
        id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
        name: "Personal",
        collections: [
            Collection(id: UUID(), name: "Auth APIs", items: []),
            Collection(id: UUID(), name: "User APIs", items: [])
        ]
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Workspace.self, from: data)
    #expect(decoded.id == original.id)
    #expect(decoded.name == "Personal")
    #expect(decoded.collections.count == 2)
    #expect(decoded.collections[0].name == "Auth APIs")
    #expect(decoded.collections[1].name == "User APIs")
}

@Test func deepNestedItemRoundTrip() throws {
    let request = Request(
        id: UUID(),
        name: "Get User",
        method: .GET,
        url: "https://api.example.com/users/1",
        params: [],
        headers: [],
        body: .none,
        auth: .none
    )
    let innerFolder = Folder(id: UUID(), name: "Folder B", items: [.request(request)])
    let outerFolder = Folder(id: UUID(), name: "Folder A", items: [.folder(innerFolder)])
    let collection = Collection(id: UUID(), name: "Nested", items: [.folder(outerFolder)])
    let workspace = Workspace(id: UUID(), name: "Deep", collections: [collection])

    let data = try JSONEncoder().encode(workspace)
    let decoded = try JSONDecoder().decode(Workspace.self, from: data)

    guard case .folder(let decodedOuter) = decoded.collections[0].items[0] else {
        Issue.record("Expected .folder at depth 1")
        return
    }
    #expect(decodedOuter.name == "Folder A")

    guard case .folder(let decodedInner) = decodedOuter.items[0] else {
        Issue.record("Expected .folder at depth 2")
        return
    }
    #expect(decodedInner.name == "Folder B")

    guard case .request(let decodedRequest) = decodedInner.items[0] else {
        Issue.record("Expected .request at depth 3")
        return
    }
    #expect(decodedRequest.name == "Get User")
    #expect(decodedRequest.method == .GET)
}

// MARK: - Request + KVPair round-trip

@Test func requestAllBodyCasesRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let bodies: [RequestBody] = [
        .none,
        .json("{\"name\":\"Alice\"}"),
        .formData([KVPair(id: UUID(), key: "username", value: "alice", enabled: true),
                   KVPair(id: UUID(), key: "role", value: "admin", enabled: false)]),
        .urlEncoded([KVPair(id: UUID(), key: "q", value: "hello world", enabled: true)])
    ]

    for body in bodies {
        let data = try encoder.encode(body)
        _ = try decoder.decode(RequestBody.self, from: data)
    }
}

@Test func requestAllAuthCasesRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let auths: [Auth] = [
        .none,
        .bearer("sk_live_abc123"),
        .basic("user@example.com", "p@ssw0rd"),
        .apiKey("X-API-Key", "secret-key-value")
    ]

    for auth in auths {
        let data = try encoder.encode(auth)
        _ = try decoder.decode(Auth.self, from: data)
    }
}

@Test func requestPostWithBearerRoundTrip() throws {
    let original = Request(
        id: UUID(),
        name: "Create User",
        method: .POST,
        url: "https://api.example.com/users",
        params: [],
        headers: [KVPair(id: UUID(), key: "Content-Type", value: "application/json", enabled: true)],
        body: .json("{\"name\":\"Alice\"}"),
        auth: .bearer("sk_live_abc123")
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Request.self, from: data)
    #expect(decoded.method == .POST)
    #expect(decoded.url == "https://api.example.com/users")
    #expect(decoded.headers.count == 1)
    #expect(decoded.headers[0].key == "Content-Type")
    if case .json(let body) = decoded.body {
        #expect(body == "{\"name\":\"Alice\"}")
    } else {
        Issue.record("Expected .json body")
    }
    if case .bearer(let token) = decoded.auth {
        #expect(token == "sk_live_abc123")
    } else {
        Issue.record("Expected .bearer auth")
    }
}

@Test func kvPairEnabledFalsePreserved() throws {
    let pair = KVPair(id: UUID(), key: "token", value: "secret", enabled: false)
    let data = try JSONEncoder().encode(pair)
    let decoded = try JSONDecoder().decode(KVPair.self, from: data)
    #expect(decoded.enabled == false)
    #expect(decoded.key == "token")
}

@Test func httpMethodAllCasesRoundTrip() throws {
    let methods: [HTTPMethod] = [.GET, .POST, .PUT, .DELETE, .PATCH, .OPTIONS, .HEAD]
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for method in methods {
        let data = try encoder.encode(method)
        let decoded = try decoder.decode(HTTPMethod.self, from: data)
        #expect(decoded == method)
    }
}

// MARK: - Response round-trip

@Test func responseBodyDataRoundTrip() throws {
    let binaryBytes = Data([0x00, 0xFF, 0xFE, 0x80, 0x7F])
    let original = Response(
        statusCode: 200,
        headers: [KVPair(id: UUID(), key: "Content-Type", value: "application/octet-stream", enabled: true)],
        body: binaryBytes,
        durationMs: 142.7,
        sizeBytes: 5
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Response.self, from: data)
    #expect(decoded.body == binaryBytes)
    #expect(decoded.statusCode == 200)
    #expect(decoded.sizeBytes == 5)
    #expect(decoded.headers[0].key == "Content-Type")
}

@Test func responseEmptyBodyRoundTrip() throws {
    let original = Response(statusCode: 404, headers: [], body: Data(), durationMs: 38.0, sizeBytes: 0)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Response.self, from: data)
    #expect(decoded.statusCode == 404)
    #expect(decoded.body.isEmpty)
    #expect(decoded.headers.isEmpty)
}

// MARK: - Environment + EnvVar round-trip

@Test func environmentRoundTrip() throws {
    let original = Environment(
        id: UUID(),
        name: "Production",
        variables: [
            EnvVar(id: UUID(), key: "base_url", value: "https://api.example.com", enabled: true),
            EnvVar(id: UUID(), key: "token", value: "sk_live_abc", enabled: false)
        ]
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Environment.self, from: data)
    #expect(decoded.name == "Production")
    #expect(decoded.variables.count == 2)
    #expect(decoded.variables[0].key == "base_url")
    #expect(decoded.variables[0].enabled == true)
    #expect(decoded.variables[1].key == "token")
    #expect(decoded.variables[1].enabled == false)
}

@Test func environmentEmptyVariablesRoundTrip() throws {
    let original = Environment(id: UUID(), name: "Empty Env", variables: [])
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Environment.self, from: data)
    #expect(decoded.name == "Empty Env")
    #expect(decoded.variables.isEmpty)
}

// MARK: - HistoryEntry round-trip

@Test func historyEntryTimestampRoundTrip() throws {
    let ts = Date(timeIntervalSince1970: 1_710_000_000)
    let entry = HistoryEntry(
        id: UUID(),
        request: Request(
            id: UUID(),
            name: "Get Users",
            method: .GET,
            url: "https://api.example.com/users",
            params: [],
            headers: [],
            body: .none,
            auth: .none
        ),
        response: Response(
            statusCode: 200,
            headers: [],
            body: Data("{\"users\":[]}".utf8),
            durationMs: 50.0,
            sizeBytes: 12
        ),
        timestamp: ts
    )
    let data = try JSONEncoder().encode(entry)
    let decoded = try JSONDecoder().decode(HistoryEntry.self, from: data)
    #expect(decoded.timestamp.timeIntervalSince1970 == ts.timeIntervalSince1970)
    #expect(decoded.request.method == .GET)
    #expect(decoded.response.statusCode == 200)
}

@Test func historyEntryIsValueSnapshot() throws {
    var request = Request(
        id: UUID(),
        name: "Original",
        method: .GET,
        url: "https://example.com",
        params: [], headers: [], body: .none, auth: .none
    )
    let entry = HistoryEntry(
        id: UUID(),
        request: request,
        response: Response(statusCode: 200, headers: [], body: Data(), durationMs: 10.0, sizeBytes: 0),
        timestamp: Date()
    )
    request.name = "Mutated"
    #expect(entry.request.name == "Original")
}
