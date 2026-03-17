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
    #expect(curl == "curl -g 'https://api.example.com/users'")
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
        body: .json("{\"name\": \"John\"}"), auth: .none
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
        body: .json(""), auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(!curl.contains("-d"))
}

// MARK: - Nested params tests

@Test func nestedObjectParamsInUrl() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com/search",
        params: [
            KVPair(key: "filter", valueType: .object, children: [
                KVPair(key: "status", value: "active", enabled: true),
                KVPair(key: "role", value: "admin", enabled: true)
            ])
        ],
        headers: [], body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("filter[status]=active"))
    #expect(curl.contains("filter[role]=admin"))
}

@Test func nestedArrayParamsInUrl() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com/search",
        params: [
            KVPair(key: "ids", valueType: .array, children: [
                KVPair(value: "1", enabled: true),
                KVPair(value: "2", enabled: true)
            ])
        ],
        headers: [], body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("ids[0]=1"))
    #expect(curl.contains("ids[1]=2"))
}

@Test func deeplyNestedParamsInUrl() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com/search",
        params: [
            KVPair(key: "user", valueType: .object, children: [
                KVPair(key: "address", valueType: .object, children: [
                    KVPair(key: "city", value: "London", enabled: true)
                ])
            ])
        ],
        headers: [], body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("user[address][city]=London"))
}

@Test func globoffFlagPresent() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com",
        params: [], headers: [], body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("curl -g"))
}

// MARK: - Variable resolution tests

private func testEnv() -> Environment {
    Environment(id: UUID(), name: "Test", variables: [
        EnvVar(id: UUID(), key: "base_url", value: "https://api.prod.com", enabled: true),
        EnvVar(id: UUID(), key: "token", value: "sk_live_abc", enabled: true),
        EnvVar(id: UUID(), key: "disabled_var", value: "nope", enabled: false)
    ])
}

@Test func variablesResolvedInUrl() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "{{base_url}}/v1/users",
        params: [], headers: [], body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request, environment: testEnv())
    #expect(curl.contains("'https://api.prod.com/v1/users'"))
    #expect(!curl.contains("{{base_url}}"))
}

@Test func variablesResolvedInBearerAuth() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com",
        params: [], headers: [],
        body: .none, auth: .bearer("{{token}}")
    )
    let curl = CurlBuilder.build(from: request, environment: testEnv())
    #expect(curl.contains("-H 'Authorization: Bearer sk_live_abc'"))
    #expect(!curl.contains("{{token}}"))
}

@Test func variablesResolvedInHeaders() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "https://api.example.com",
        params: [],
        headers: [
            KVPair(id: UUID(), key: "Authorization", value: "Bearer {{token}}", enabled: true)
        ],
        body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request, environment: testEnv())
    #expect(curl.contains("-H 'Authorization: Bearer sk_live_abc'"))
}

@Test func variablesResolvedInRawBody() {
    let request = Request(
        id: UUID(), name: "Test", method: .POST,
        url: "https://api.example.com",
        params: [], headers: [],
        body: .json("{\"url\": \"{{base_url}}\"}"), auth: .none
    )
    let curl = CurlBuilder.build(from: request, environment: testEnv())
    #expect(curl.contains("https://api.prod.com"))
    #expect(!curl.contains("{{base_url}}"))
}

@Test func disabledVariablesNotResolved() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "{{disabled_var}}/api",
        params: [], headers: [], body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request, environment: testEnv())
    #expect(curl.contains("{{disabled_var}}"))
}

@Test func noEnvironmentLeavesVariablesAsIs() {
    let request = Request(
        id: UUID(), name: "Test", method: .GET,
        url: "{{base_url}}/api",
        params: [], headers: [], body: .none, auth: .none
    )
    let curl = CurlBuilder.build(from: request)
    #expect(curl.contains("{{base_url}}"))
}
