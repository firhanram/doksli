import Testing
import Foundation
@testable import Doksli

// MARK: - Helpers

private func makeRequest(
    method: HTTPMethod = .GET,
    url: String = "https://httpbin.org/get",
    params: [KVPair] = [],
    headers: [KVPair] = [],
    body: RequestBody = .none,
    auth: Auth = .none
) -> Request {
    Request(id: UUID(), name: "Test", method: method, url: url,
            params: params, headers: headers, body: body, auth: auth)
}

private func makeEnv(_ vars: [(key: String, value: String, enabled: Bool)]) -> Environment {
    Environment(id: UUID(), name: "Test", variables: vars.map {
        EnvVar(id: UUID(), key: $0.key, value: $0.value, enabled: $0.enabled)
    })
}

// MARK: - buildRequest unit tests (no network)

@Test func buildRequestGET() throws {
    let request = makeRequest(method: .GET, url: "https://httpbin.org/get")
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString == "https://httpbin.org/get")
    #expect(urlRequest.httpBody == nil)
}

@Test func buildRequestAllMethods() throws {
    let methods: [HTTPMethod] = [.GET, .POST, .PUT, .DELETE, .PATCH, .OPTIONS, .HEAD]
    for method in methods {
        let request = makeRequest(method: method)
        let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
        #expect(urlRequest.httpMethod == method.rawValue)
    }
}

@Test func buildRequestWithEnabledAndDisabledParams() throws {
    let params = [
        KVPair(id: UUID(), key: "page", value: "1", enabled: true),
        KVPair(id: UUID(), key: "limit", value: "10", enabled: true),
        KVPair(id: UUID(), key: "debug", value: "true", enabled: false)
    ]
    let request = makeRequest(url: "https://httpbin.org/get", params: params)
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    let urlString = urlRequest.url?.absoluteString ?? ""
    #expect(urlString.contains("page=1"))
    #expect(urlString.contains("limit=10"))
    #expect(!urlString.contains("debug=true"))
}

@Test func buildRequestBearerAuthInjected() throws {
    let request = makeRequest(auth: .bearer("sk_live_abc123"))
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer sk_live_abc123")
}

@Test func buildRequestBasicAuthInjected() throws {
    let request = makeRequest(auth: .basic("user@example.com", "p@ssw0rd"))
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    let expected = "Basic " + Data("user@example.com:p@ssw0rd".utf8).base64EncodedString()
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == expected)
}

@Test func buildRequestAPIKeyAuthInjected() throws {
    let request = makeRequest(auth: .apiKey("X-API-Key", "mysecret"))
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    #expect(urlRequest.value(forHTTPHeaderField: "X-API-Key") == "mysecret")
}

@Test func buildRequestAuthNotInHeaders() throws {
    // Bearer auth must NOT appear in request.headers — it's injected separately
    let request = makeRequest(
        headers: [KVPair(id: UUID(), key: "Accept", value: "application/json", enabled: true)],
        auth: .bearer("token")
    )
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
    #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
}

@Test func buildRequestRawBody() throws {
    let body = "{\"name\":\"Alice\"}"
    let request = makeRequest(body: .json(body))
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    #expect(urlRequest.httpBody == Data(body.utf8))
}

@Test func buildRequestURLEncodedBody() throws {
    let pairs = [
        KVPair(id: UUID(), key: "q", value: "hello world", enabled: true),
        KVPair(id: UUID(), key: "lang", value: "en", enabled: true),
        KVPair(id: UUID(), key: "hidden", value: "skip", enabled: false)
    ]
    let request = makeRequest(body: .urlEncoded(pairs))
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    let bodyString = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
    #expect(bodyString.contains("q=hello%20world"))
    #expect(bodyString.contains("lang=en"))
    #expect(!bodyString.contains("hidden"))
}

@Test func buildRequestFormDataBody() throws {
    let pairs = [KVPair(id: UUID(), key: "username", value: "alice", enabled: true)]
    let request = makeRequest(body: .formData(pairs))
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    let contentType = urlRequest.value(forHTTPHeaderField: "Content-Type") ?? ""
    #expect(contentType.hasPrefix("multipart/form-data; boundary="))
    let bodyString = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
    #expect(bodyString.contains("username"))
    #expect(bodyString.contains("alice"))
}

@Test func buildRequestVariablesResolvedInURL() throws {
    let env = makeEnv([("baseUrl", "https://api.example.com", true)])
    let request = makeRequest(url: "{{baseUrl}}/users")
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: env)
    #expect(urlRequest.url?.absoluteString == "https://api.example.com/users")
}

@Test func buildRequestVariablesResolvedInHeaders() throws {
    let env = makeEnv([("token", "sk_live_abc", true)])
    let headers = [KVPair(id: UUID(), key: "Authorization", value: "Bearer {{token}}", enabled: true)]
    let request = makeRequest(headers: headers)
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: env)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer sk_live_abc")
}

@Test func buildRequestInvalidURLThrows() {
    let request = makeRequest(url: "")
    #expect(throws: HTTPClientError.self) {
        _ = try HTTPClient.buildRequest(from: request, environment: nil)
    }
}

@Test func buildRequestDisabledHeadersExcluded() throws {
    let headers = [
        KVPair(id: UUID(), key: "X-Enabled", value: "yes", enabled: true),
        KVPair(id: UUID(), key: "X-Disabled", value: "no", enabled: false)
    ]
    let request = makeRequest(headers: headers)
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    #expect(urlRequest.value(forHTTPHeaderField: "X-Enabled") == "yes")
    #expect(urlRequest.value(forHTTPHeaderField: "X-Disabled") == nil)
}

// MARK: - Nested params tests

@Test func buildRequestNestedObjectParams() throws {
    let params = [
        KVPair(key: "filter", valueType: .object, children: [
            KVPair(key: "status", value: "active", enabled: true)
        ])
    ]
    let request = makeRequest(params: params)
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    let url = urlRequest.url?.absoluteString ?? ""
    #expect(url.contains("filter%5Bstatus%5D=active") || url.contains("filter[status]=active"))
}

@Test func buildRequestNestedArrayParams() throws {
    let params = [
        KVPair(key: "ids", valueType: .array, children: [
            KVPair(value: "1", enabled: true),
            KVPair(value: "2", enabled: true)
        ])
    ]
    let request = makeRequest(params: params)
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    let url = urlRequest.url?.absoluteString ?? ""
    #expect(url.contains("ids%5B0%5D=1") || url.contains("ids[0]=1"))
    #expect(url.contains("ids%5B1%5D=2") || url.contains("ids[1]=2"))
}

@Test func buildRequestDisabledNestedParamsSkipped() throws {
    let params = [
        KVPair(key: "filter", enabled: false, valueType: .object, children: [
            KVPair(key: "status", value: "active", enabled: true)
        ])
    ]
    let request = makeRequest(params: params)
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    let url = urlRequest.url?.absoluteString ?? ""
    #expect(!url.contains("filter"))
    #expect(!url.contains("status"))
}

// MARK: - Form data dot/repeat notation tests

@Test func flattenFormDataNestedObject() {
    let pairs = [
        KVPair(key: "personalInformation", valueType: .object, children: [
            KVPair(key: "gender", value: "male", enabled: true),
            KVPair(key: "email", value: "a@b.com", enabled: true)
        ])
    ]
    let flattened = HTTPClient.flattenPairs(pairs, style: .dotRepeat)
    #expect(flattened.count == 2)
    #expect(flattened[0].name == "personalInformation.gender")
    #expect(flattened[0].pair.value == "male")
    #expect(flattened[1].name == "personalInformation.email")
    #expect(flattened[1].pair.value == "a@b.com")
}

@Test func flattenFormDataDeepNestedObject() {
    let pairs = [
        KVPair(key: "user", valueType: .object, children: [
            KVPair(key: "address", valueType: .object, children: [
                KVPair(key: "city", value: "Jakarta", enabled: true)
            ])
        ])
    ]
    let flattened = HTTPClient.flattenPairs(pairs, style: .dotRepeat)
    #expect(flattened.count == 1)
    #expect(flattened[0].name == "user.address.city")
    #expect(flattened[0].pair.value == "Jakarta")
}

@Test func flattenFormDataArrayRepeatsKey() {
    let pairs = [
        KVPair(key: "tags", valueType: .array, children: [
            KVPair(value: "swift", enabled: true),
            KVPair(value: "macos", enabled: true),
            KVPair(value: "native", enabled: true)
        ])
    ]
    let flattened = HTTPClient.flattenPairs(pairs, style: .dotRepeat)
    #expect(flattened.count == 3)
    // All items should have the same key name (repeated)
    #expect(flattened[0].name == "tags")
    #expect(flattened[1].name == "tags")
    #expect(flattened[2].name == "tags")
    #expect(flattened[0].pair.value == "swift")
    #expect(flattened[1].pair.value == "macos")
    #expect(flattened[2].pair.value == "native")
}

@Test func flattenFormDataArrayDisabledChildSkipped() {
    let pairs = [
        KVPair(key: "files", valueType: .array, children: [
            KVPair(value: "a.png", enabled: true),
            KVPair(value: "b.png", enabled: false),
            KVPair(value: "c.png", enabled: true)
        ])
    ]
    let flattened = HTTPClient.flattenPairs(pairs, style: .dotRepeat)
    #expect(flattened.count == 2)
    #expect(flattened[0].pair.value == "a.png")
    #expect(flattened[1].pair.value == "c.png")
}

@Test func flattenFormDataMixedObjectAndArray() {
    let pairs = [
        KVPair(key: "personalInformation", valueType: .object, children: [
            KVPair(key: "gender", value: "male", enabled: true),
            KVPair(key: "email", value: "a@b.com", enabled: true)
        ]),
        KVPair(key: "guardianInformation", valueType: .object, children: [
            KVPair(key: "name", value: "John", enabled: true)
        ]),
        KVPair(key: "files", valueType: .array, children: [
            KVPair(value: "image1.png", enabled: true),
            KVPair(value: "image2.png", enabled: true)
        ])
    ]
    let flattened = HTTPClient.flattenPairs(pairs, style: .dotRepeat)
    #expect(flattened.count == 5)
    #expect(flattened[0].name == "personalInformation.gender")
    #expect(flattened[1].name == "personalInformation.email")
    #expect(flattened[2].name == "guardianInformation.name")
    #expect(flattened[3].name == "files")
    #expect(flattened[4].name == "files")
    #expect(flattened[3].pair.value == "image1.png")
    #expect(flattened[4].pair.value == "image2.png")
}

@Test func flattenBracketStyleUnchanged() {
    // Verify that bracket style (query params/URL encoded) is not affected
    let pairs = [
        KVPair(key: "filter", valueType: .object, children: [
            KVPair(key: "status", value: "active", enabled: true)
        ]),
        KVPair(key: "ids", valueType: .array, children: [
            KVPair(value: "1", enabled: true),
            KVPair(value: "2", enabled: true)
        ])
    ]
    let flattened = HTTPClient.flattenPairs(pairs, style: .bracket)
    #expect(flattened.count == 3)
    #expect(flattened[0].name == "filter[status]")
    #expect(flattened[1].name == "ids[0]")
    #expect(flattened[2].name == "ids[1]")
}

@Test func buildFormDataBodyUsesDotNotation() throws {
    let pairs = [
        KVPair(key: "info", valueType: .object, children: [
            KVPair(key: "name", value: "Alice", enabled: true)
        ]),
        KVPair(key: "username", value: "alice123", enabled: true)
    ]
    let request = makeRequest(method: .POST, url: "https://httpbin.org/post", body: .formData(pairs))
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    let bodyString = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
    #expect(bodyString.contains("name=\"info.name\""))
    #expect(bodyString.contains("Alice"))
    #expect(bodyString.contains("name=\"username\""))
    #expect(bodyString.contains("alice123"))
    // Must NOT contain bracket notation
    #expect(!bodyString.contains("info[name]"))
}

@Test func buildFormDataBodyRepeatsArrayKey() throws {
    let pairs = [
        KVPair(key: "tags", valueType: .array, children: [
            KVPair(value: "swift", enabled: true),
            KVPair(value: "macos", enabled: true)
        ])
    ]
    let request = makeRequest(method: .POST, url: "https://httpbin.org/post", body: .formData(pairs))
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: nil)
    let bodyString = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
    // Both array items should use the same key "tags" (repeated)
    let tagCount = bodyString.components(separatedBy: "name=\"tags\"").count - 1
    #expect(tagCount == 2)
    #expect(bodyString.contains("swift"))
    #expect(bodyString.contains("macos"))
    // Must NOT contain bracket notation
    #expect(!bodyString.contains("tags[0]"))
    #expect(!bodyString.contains("tags[1]"))
}

@Test func buildFormDataResolvesVariables() throws {
    let env = makeEnv([("gender_val", "male", true), ("email_val", "a@b.com", true)])
    let pairs = [
        KVPair(key: "gender", value: "{{gender_val}}", enabled: true),
        KVPair(key: "email", value: "{{email_val}}", enabled: true)
    ]
    let request = makeRequest(method: .POST, url: "https://httpbin.org/post", body: .formData(pairs))
    let urlRequest = try HTTPClient.buildRequest(from: request, environment: env)
    let bodyString = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
    #expect(bodyString.contains("male"))
    #expect(bodyString.contains("a@b.com"))
    #expect(!bodyString.contains("{{gender_val}}"))
    #expect(!bodyString.contains("{{email_val}}"))
}

// MARK: - Integration tests (require network)

@Test(.timeLimit(.minutes(1)))
func integrationGET() async throws {
    let request = makeRequest(method: .GET, url: "https://httpbin.org/get")
    let response = try await HTTPClient.send(request, environment: nil)
    #expect(response.statusCode == 200)
    #expect(!response.body.isEmpty)
    #expect(response.durationMs > 0)
    #expect(response.sizeBytes == response.body.count)
}

@Test(.timeLimit(.minutes(1)))
func integrationPOSTJSON() async throws {
    let body = "{\"name\":\"Alice\"}"
    let headers = [KVPair(id: UUID(), key: "Content-Type", value: "application/json", enabled: true)]
    let request = makeRequest(method: .POST, url: "https://httpbin.org/post",
                               headers: headers, body: .json(body))
    let response = try await HTTPClient.send(request, environment: nil)
    #expect(response.statusCode == 200)
    let bodyString = String(data: response.body, encoding: .utf8) ?? ""
    #expect(bodyString.contains("Alice"))
}

@Test(.timeLimit(.minutes(1)))
func integrationHeadersRoundTrip() async throws {
    let headers = [KVPair(id: UUID(), key: "X-Test-Header", value: "round-trip-value", enabled: true)]
    let request = makeRequest(method: .GET, url: "https://httpbin.org/get", headers: headers)
    let response = try await HTTPClient.send(request, environment: nil)
    #expect(response.statusCode == 200)
    let bodyString = String(data: response.body, encoding: .utf8) ?? ""
    #expect(bodyString.contains("round-trip-value"))
}

@Test(.timeLimit(.minutes(1)))
func integrationDELETE() async throws {
    let request = makeRequest(method: .DELETE, url: "https://httpbin.org/delete")
    let response = try await HTTPClient.send(request, environment: nil)
    #expect(response.statusCode == 200)
}
