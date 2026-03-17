import Testing
import Foundation
@testable import doksli

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
