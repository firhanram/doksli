import Foundation

// MARK: - HTTPClientError

enum HTTPClientError: Error {
    case invalidURL(String)
    case notHTTPResponse
}

// MARK: - HTTPClient

struct HTTPClient {

    // MARK: Build

    /// Builds a `URLRequest` from `request`, resolving `{{var}}` tokens using `environment`.
    /// Never mutates `request`. Throws `HTTPClientError.invalidURL` if the resolved URL is invalid.
    static func buildRequest(from request: Request, environment: Environment?) throws -> URLRequest {
        // 1. Resolve variables
        let resolvedURL = VariableResolver.resolve(request.url, environment: environment)
        let resolvedHeaders = request.headers.map { kv in
            KVPair(id: kv.id, key: kv.key,
                   value: VariableResolver.resolve(kv.value, environment: environment),
                   enabled: kv.enabled)
        }

        // 2. Parse URL and append enabled query params
        guard !resolvedURL.trimmingCharacters(in: .whitespaces).isEmpty,
              var components = URLComponents(string: resolvedURL) else {
            throw HTTPClientError.invalidURL(resolvedURL)
        }
        let enabledParams = request.params.filter { $0.enabled }
        if !enabledParams.isEmpty {
            var queryItems = components.queryItems ?? []
            queryItems += enabledParams.map { URLQueryItem(name: $0.key, value: $0.value) }
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw HTTPClientError.invalidURL(resolvedURL)
        }

        // 3. Assemble URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        // 4. Set enabled headers
        for header in resolvedHeaders where header.enabled {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        // 5. Inject auth header (not visible in UI headers)
        switch request.auth {
        case .none:
            break
        case .bearer(let token):
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        case .basic(let username, let password):
            let credentials = "\(username):\(password)"
            let encoded = Data(credentials.utf8).base64EncodedString()
            urlRequest.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        case .apiKey(let name, let value):
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }

        // 6. Encode body
        switch request.body {
        case .none:
            break
        case .raw(let string):
            let resolved = VariableResolver.resolve(string, environment: environment)
            urlRequest.httpBody = Data(resolved.utf8)
        case .formData(let pairs):
            let boundary = UUID().uuidString
            urlRequest.setValue(
                "multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField: "Content-Type"
            )
            urlRequest.httpBody = buildMultipartBody(pairs: pairs.filter { $0.enabled },
                                                     boundary: boundary)
        case .urlEncoded(let pairs):
            urlRequest.setValue(
                "application/x-www-form-urlencoded",
                forHTTPHeaderField: "Content-Type"
            )
            urlRequest.httpBody = buildURLEncodedBody(pairs: pairs.filter { $0.enabled })
        }

        return urlRequest
    }

    // MARK: Send

    /// Sends `request` and returns a `Response`. Resolves variables, builds URLRequest,
    /// measures wall-clock duration with `ContinuousClock`, maps the HTTP response.
    static func send(_ request: Request, environment: Environment?) async throws -> Response {
        let urlRequest = try buildRequest(from: request, environment: environment)

        let clock = ContinuousClock()
        var responseData: Data = Data()
        var urlResponse: URLResponse = URLResponse()

        let duration = try await clock.measure {
            (responseData, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        }

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw HTTPClientError.notHTTPResponse
        }

        let seconds = Double(duration.components.seconds)
                    + Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
        return mapResponse(httpResponse, data: responseData, durationSeconds: seconds)
    }

    // MARK: Response mapping

    private static func mapResponse(
        _ httpResponse: HTTPURLResponse,
        data: Data,
        durationSeconds: Double
    ) -> Response {
        let headers: [KVPair] = httpResponse.allHeaderFields.compactMap { key, value in
            guard let k = key as? String, let v = value as? String else { return nil }
            return KVPair(id: UUID(), key: k, value: v, enabled: true)
        }
        return Response(
            statusCode: httpResponse.statusCode,
            headers: headers,
            body: data,
            durationMs: durationSeconds * 1000,
            sizeBytes: data.count
        )
    }

    // MARK: Body encoding helpers

    private static func buildURLEncodedBody(pairs: [KVPair]) -> Data {
        let encoded = pairs.map { pair in
            let key = pair.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? pair.key
            let value = pair.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? pair.value
            return "\(key)=\(value)"
        }.joined(separator: "&")
        return Data(encoded.utf8)
    }

    private static func buildMultipartBody(pairs: [KVPair], boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"
        for pair in pairs {
            body += Data("--\(boundary)\(crlf)".utf8)
            body += Data("Content-Disposition: form-data; name=\"\(pair.key)\"\(crlf)\(crlf)".utf8)
            body += Data("\(pair.value)\(crlf)".utf8)
        }
        body += Data("--\(boundary)--\(crlf)".utf8)
        return body
    }
}
