import Testing
import Foundation
@testable import Doksli

// MARK: - Helpers

/// Creates a fresh temp directory for each test, cleaned up on deinit.
private func makeTempDir() throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("doksli-tests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

private func makeRequest(
    body: RequestBody = .none,
    auth: Auth = .none
) -> Request {
    Request(
        id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
        name: "Test Request",
        method: .GET,
        url: "https://api.example.com/users",
        params: [],
        headers: [KVPair(id: UUID(), key: "Accept", value: "application/json", enabled: true)],
        body: body,
        auth: auth
    )
}

private func makeResponse(body: Data = Data("{\"ok\":true}".utf8)) -> Response {
    Response(
        statusCode: 200,
        headers: [KVPair(id: UUID(), key: "Content-Type", value: "application/json", enabled: true)],
        body: body,
        durationMs: 142.0,
        sizeBytes: body.count
    )
}

// MARK: - Workspaces

@Test func loadWorkspacesWhenFileMissing() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let result = StorageService.loadWorkspaces(from: dir)
    #expect(result.isEmpty)
}

@Test func saveAndLoadWorkspaces() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let ws = Workspace(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        name: "My Workspace",
        collections: [
            Collection(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                name: "Auth APIs",
                items: [
                    .folder(Folder(
                        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                        name: "Login",
                        items: [.request(makeRequest())]
                    ))
                ]
            )
        ]
    )
    try StorageService.saveWorkspaces([ws], to: dir)
    let loaded = StorageService.loadWorkspaces(from: dir)

    #expect(loaded.count == 1)
    #expect(loaded[0].id == ws.id)
    #expect(loaded[0].name == "My Workspace")
    #expect(loaded[0].collections.count == 1)
    #expect(loaded[0].collections[0].name == "Auth APIs")
    #expect(loaded[0].collections[0].items.count == 1)
    if case .folder(let f) = loaded[0].collections[0].items[0] {
        #expect(f.name == "Login")
        #expect(f.items.count == 1)
    } else {
        Issue.record("Expected .folder at items[0]")
    }
}

@Test func saveEmptyWorkspacesReturnsEmpty() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    try StorageService.saveWorkspaces([], to: dir)
    #expect(StorageService.loadWorkspaces(from: dir).isEmpty)
}

@Test func saveWorkspacesCreatesFile() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let ws = Workspace(id: UUID(), name: "W", collections: [])
    try StorageService.saveWorkspaces([ws], to: dir)
    #expect(FileManager.default.fileExists(atPath: dir.appendingPathComponent("workspaces.json").path))
}

@Test func loadWorkspacesWithCorruptFile() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    try "{broken".write(to: dir.appendingPathComponent("workspaces.json"), atomically: true, encoding: .utf8)
    let result = StorageService.loadWorkspaces(from: dir)
    #expect(result.isEmpty)
}

// MARK: - Environments

@Test func loadEnvironmentsWhenFileMissing() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    #expect(StorageService.loadEnvironments(from: dir).isEmpty)
}

@Test func saveAndLoadEnvironments() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let env = Environment(
        id: UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!,
        name: "Production",
        variables: [
            EnvVar(id: UUID(), key: "base_url", value: "https://api.example.com", enabled: true),
            EnvVar(id: UUID(), key: "token", value: "sk_live_abc", enabled: false)
        ]
    )
    try StorageService.saveEnvironments([env], to: dir)
    let loaded = StorageService.loadEnvironments(from: dir)

    #expect(loaded.count == 1)
    #expect(loaded[0].id == env.id)
    #expect(loaded[0].name == "Production")
    #expect(loaded[0].variables.count == 2)
    #expect(loaded[0].variables[0].key == "base_url")
    #expect(loaded[0].variables[1].enabled == false)
}

@Test func environmentsAndWorkspacesAreIndependent() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let ws = Workspace(id: UUID(), name: "WS", collections: [])
    let env = Environment(id: UUID(), name: "Prod", variables: [])
    try StorageService.saveWorkspaces([ws], to: dir)
    try StorageService.saveEnvironments([env], to: dir)

    let loadedWS = StorageService.loadWorkspaces(from: dir)
    let loadedEnv = StorageService.loadEnvironments(from: dir)
    #expect(loadedWS.count == 1)
    #expect(loadedWS[0].name == "WS")
    #expect(loadedEnv.count == 1)
    #expect(loadedEnv[0].name == "Prod")
}

@Test func loadEnvironmentsWithCorruptFile() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    try "{broken".write(to: dir.appendingPathComponent("environments.json"), atomically: true, encoding: .utf8)
    #expect(StorageService.loadEnvironments(from: dir).isEmpty)
}

// MARK: - History ring buffer

@Test func loadHistoryWhenFileMissing() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    #expect(StorageService.loadHistory(from: dir).isEmpty)
}

@Test func appendHistoryNewestFirst() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let idA = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!
    let idB = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!
    let idC = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000003")!

    let entryA = HistoryEntry(id: idA, request: makeRequest(), response: makeResponse(), timestamp: Date())
    let entryB = HistoryEntry(id: idB, request: makeRequest(), response: makeResponse(), timestamp: Date())
    let entryC = HistoryEntry(id: idC, request: makeRequest(), response: makeResponse(), timestamp: Date())

    try StorageService.appendHistory(entryA, to: dir)
    try StorageService.appendHistory(entryB, to: dir)
    try StorageService.appendHistory(entryC, to: dir)

    let loaded = StorageService.loadHistory(from: dir)
    #expect(loaded.count == 3)
    #expect(loaded[0].id == idC)
    #expect(loaded[1].id == idB)
    #expect(loaded[2].id == idA)
}

@Test func historyRingBufferCappedAt100() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    var firstID: UUID = UUID()
    var lastID: UUID = UUID()

    for i in 0...100 {
        let id = UUID()
        if i == 0 { firstID = id }
        if i == 100 { lastID = id }
        let entry = HistoryEntry(id: id, request: makeRequest(), response: makeResponse(), timestamp: Date())
        try StorageService.appendHistory(entry, to: dir)
    }

    let loaded = StorageService.loadHistory(from: dir)
    #expect(loaded.count == 100)
    #expect(loaded[0].id == lastID)
    #expect(!loaded.contains(where: { $0.id == firstID }))
}

@Test func loadHistoryWithCorruptFile() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    try "{broken".write(to: dir.appendingPathComponent("history.json"), atomically: true, encoding: .utf8)
    #expect(StorageService.loadHistory(from: dir).isEmpty)
}

// MARK: - Request body round-trips via StorageService

@Test func requestRawBodyRoundTrip() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let req = makeRequest(body: .json("{\"name\":\"Alice\"}"))
    let ws = Workspace(id: UUID(), name: "W", collections: [
        Collection(id: UUID(), name: "C", items: [.request(req)])
    ])
    try StorageService.saveWorkspaces([ws], to: dir)
    let loaded = StorageService.loadWorkspaces(from: dir)
    guard case .request(let r) = loaded[0].collections[0].items[0] else {
        Issue.record("Expected .request"); return
    }
    #expect(r.body.mode == .json)
    #expect(r.body.jsonBody == "{\"name\":\"Alice\"}")
}

@Test func requestFormDataBodyRoundTrip() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let pairs = [KVPair(id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!, key: "field", value: "val", enabled: true)]
    let req = makeRequest(body: .formData(pairs))
    let ws = Workspace(id: UUID(), name: "W", collections: [
        Collection(id: UUID(), name: "C", items: [.request(req)])
    ])
    try StorageService.saveWorkspaces([ws], to: dir)
    let loaded = StorageService.loadWorkspaces(from: dir)
    guard case .request(let r) = loaded[0].collections[0].items[0] else {
        Issue.record("Expected .request"); return
    }
    #expect(r.body.mode == .formData)
    #expect(r.body.formDataPairs.count == 1)
    #expect(r.body.formDataPairs[0].key == "field")
    #expect(r.body.formDataPairs[0].value == "val")
}

@Test func requestURLEncodedBodyRoundTrip() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let pairs = [KVPair(id: UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!, key: "q", value: "hello", enabled: true)]
    let req = makeRequest(body: .urlEncoded(pairs))
    let ws = Workspace(id: UUID(), name: "W", collections: [
        Collection(id: UUID(), name: "C", items: [.request(req)])
    ])
    try StorageService.saveWorkspaces([ws], to: dir)
    let loaded = StorageService.loadWorkspaces(from: dir)
    guard case .request(let r) = loaded[0].collections[0].items[0] else {
        Issue.record("Expected .request"); return
    }
    #expect(r.body.mode == .urlEncoded)
    #expect(r.body.urlEncodedPairs.count == 1)
    #expect(r.body.urlEncodedPairs[0].key == "q")
    #expect(r.body.urlEncodedPairs[0].value == "hello")
}

@Test func requestNoneBodyRoundTrip() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let req = makeRequest(body: .none)
    let ws = Workspace(id: UUID(), name: "W", collections: [
        Collection(id: UUID(), name: "C", items: [.request(req)])
    ])
    try StorageService.saveWorkspaces([ws], to: dir)
    let loaded = StorageService.loadWorkspaces(from: dir)
    guard case .request(let r) = loaded[0].collections[0].items[0] else {
        Issue.record("Expected .request"); return
    }
    #expect(r.body.mode == .none)
}

// MARK: - Response binary body round-trip

@Test func responseBinaryBodyRoundTrip() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let binaryData = Data([0xFF, 0xFE, 0x00, 0x01, 0xD8, 0xFF])
    let req = makeRequest()
    let res = makeResponse(body: binaryData)
    let entry = HistoryEntry(id: UUID(), request: req, response: res, timestamp: Date(timeIntervalSince1970: 1_700_000_000))

    try StorageService.appendHistory(entry, to: dir)
    let loaded = StorageService.loadHistory(from: dir)

    #expect(loaded.count == 1)
    #expect(loaded[0].response.body == binaryData)
    #expect(loaded[0].response.sizeBytes == binaryData.count)
}
