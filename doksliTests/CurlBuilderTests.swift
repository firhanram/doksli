import Testing
import Foundation
@testable import doksli

// MARK: - CurlBuilder unit tests

@Test func simpleGetRequest() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com/users",
        params: [], headers: [], body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl == "curl 'https://api.example.com/users'")
}

@Test func postRequestIncludesMethod() {
    let request = Request(
        id: UUID(), name: "Test", method: .POST,
        url: "https://api.example.com/users",
        params: [], headers: [], body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("-X POST"))
}

@Test func queryParamsAppendedToUrl() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com/users",
        params: [
            KVPair(id: UUID(), key: "page", value: "1", enabled: true),
            KVPair(id: UUID(), key: "limit", value: "10", enabled: true)
        ],
        headers: [], body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("'https://api.example.com/users?page=1&limit=10'"))
}

@Test func disabledParamsSkipped() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com/users",
        params: [
            KVPair(id: UUID(), key: "page", value: "1", enabled: true),
            KVPair(id: UUID(), key: "debug", value: "true", enabled: false)
        ],
        headers: [], body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("page=1"))
    #expect(!curl.contains("debug"))
}

@Test func headersIncluded() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com",
        params: [],
        headers: [
            KVPair(id: UUID(), key: "Content-Type", value: "application/json", enabled: true),
            KVPair(id: UUID(), key: "X-Disabled", value: "skip", enabled: false)
        ],
        body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("-H 'Content-Type: application/json'"))
    #expect(!curl.contains("X-Disabled"))
}

@Test func bearerAuth() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com",
        params: [], headers: [],
        body: .none, auth: .bearer("my_token_123")
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("-H 'Authorization: Bearer my_token_123'"))
}

@Test func basicAuth() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com",
        params: [], headers: [],
        body: .none, auth: .basic("admin", "secret")
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("-u 'admin:secret'"))
}

@Test func apiKeyAuth() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com",
        params: [], headers: [],
        body: .none, auth: .apiKey("X-API-Key", "abc123")
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("-H 'X-API-Key: abc123'"))
}

@Test func rawBody() {
    let request = Request(
        id: UUID(), name: "Test", method: .POST,
        url: "https://api.example.com",
        params: [], headers: [],
        body: .raw("{\"name\": \"John\"}"), auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("-d '{\"name\": \"John\"}'"))
}

@Test func urlEncodedBody() {
    let request = Request(
        id: UUID(), name: "Test", method: .POST,
        url: "https://api.example.com",
        params: [], headers: [],
        body: .urlEncoded([
            KVPair(id: UUID(), key: "username", value: "admin", enabled: true),
            KVPair(id: UUID(), key: "password", value: "secret", enabled: true)
        ]),
        auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("-d 'username=admin&password=secret'"))
}

@Test func formDataBody() {
    let request = Request(
        id: UUID(), name: "Test", method: .POST,
        url: "https://api.example.com",
        params: [], headers: [],
        body: .formData([
            KVPair(id: UUID(), key: "file", value: "test.txt", enabled: true)
        ]),
        auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("-F 'file=test.txt'"))
}

@Test func noBodyForNone() {
    let request = Request(
        id: UUID(), name: "Test", method: .POST,
        url: "https://api.example.com",
        params: [], headers: [],
        body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(!curl.contains("-d"))
    #expect(!curl.contains("-F"))
}

@Test func emptyRawBodyOmitted() {
    let request = Request(
        id: UUID(), name: "Test", method: .POST,
        url: "https://api.example.com",
        params: [], headers: [],
        body: .raw(""), auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(!curl.contains("-d"))
}
