import Foundation

// MARK: - HTTPClientError

enum HTTPClientError: Error {
    case invalidURL(String)
    case notHTTPResponse
}

// MARK: - FlattenStyle

enum FlattenStyle {
    case bracket     // field[key], field[0] — for query params and URL encoded
    case dotRepeat   // field.key, field (repeated) — for form data bodies
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
        let flatParams = flattenPairs(request.params)
        if !flatParams.isEmpty {
            var queryItems = components.queryItems ?? []
            queryItems += flatParams.map { URLQueryItem(name: $0.name, value: $0.pair.value) }
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
            let cleanToken = token.hasPrefix("Bearer ") ? String(token.dropFirst(7)) : token
            urlRequest.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")
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
        case .json(let string):
            let resolved = VariableResolver.resolve(string, environment: environment)
            urlRequest.httpBody = Data(resolved.utf8)
            // Auto-set Content-Type if user hasn't set one
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                let trimmed = resolved.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                } else {
                    urlRequest.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                }
            }
        case .formData(let pairs):
            let resolvedPairs = Self.resolvePairs(pairs, environment: environment)
            let boundary = UUID().uuidString
            urlRequest.setValue(
                "multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField: "Content-Type"
            )
            urlRequest.httpBody = buildMultipartBody(pairs: resolvedPairs, boundary: boundary)
        case .urlEncoded(let pairs):
            urlRequest.setValue(
                "application/x-www-form-urlencoded",
                forHTTPHeaderField: "Content-Type"
            )
            urlRequest.httpBody = buildURLEncodedBody(pairs: pairs)
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

    /// Recursively flattens nested KVPairs into `(name, leafPair)` tuples.
    /// `.bracket` style uses `field[key]` / `field[0]` — for query params and URL encoded.
    /// `.dotRepeat` style uses `field.key` for objects and repeats the same key for arrays — for form data.
    /// Skips disabled pairs at any level.
    static func flattenPairs(
        _ pairs: [KVPair],
        prefix: String = "",
        style: FlattenStyle = .bracket
    ) -> [(name: String, pair: KVPair)] {
        var result: [(name: String, pair: KVPair)] = []
        for (index, pair) in pairs.enumerated() {
            guard pair.enabled else { continue }

            let name: String
            if prefix.isEmpty {
                name = pair.key
            } else if style == .dotRepeat {
                name = pair.key.isEmpty ? prefix : "\(prefix).\(pair.key)"
            } else {
                let segment = pair.key.isEmpty ? "\(index)" : pair.key
                name = "\(prefix)[\(segment)]"
            }

            if pair.isContainer, let children = pair.children {
                if pair.valueType == .array && style == .dotRepeat {
                    // Array with dotRepeat: flatten each child using the SAME name (repeated key)
                    for child in children where child.enabled {
                        if child.isContainer, let grandchildren = child.children {
                            result += flattenPairs(grandchildren, prefix: name, style: style)
                        } else {
                            result.append((name: name, pair: child))
                        }
                    }
                } else {
                    let childPairs: [KVPair]
                    if pair.valueType == .array {
                        childPairs = children.enumerated().map { idx, child in
                            var c = child
                            c.key = "\(idx)"
                            return c
                        }
                    } else {
                        childPairs = children
                    }
                    result += flattenPairs(childPairs, prefix: name, style: style)
                }
            } else {
                result.append((name: name, pair: pair))
            }
        }
        return result
    }

    /// Recursively resolves `{{var}}` tokens in KVPair keys and values.
    private static func resolvePairs(_ pairs: [KVPair], environment: Environment?) -> [KVPair] {
        pairs.map { pair in
            var resolved = pair
            resolved.key = VariableResolver.resolve(pair.key, environment: environment)
            resolved.value = VariableResolver.resolve(pair.value, environment: environment)
            if let children = pair.children {
                resolved.children = resolvePairs(children, environment: environment)
            }
            return resolved
        }
    }

    private static func buildURLEncodedBody(pairs: [KVPair]) -> Data {
        let flattened = flattenPairs(pairs)
        let encoded = flattened.map { item in
            let key = item.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? item.name
            let value = item.pair.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? item.pair.value
            return "\(key)=\(value)"
        }.joined(separator: "&")
        return Data(encoded.utf8)
    }

    private static func buildMultipartBody(pairs: [KVPair], boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"
        let flattened = flattenPairs(pairs, style: .dotRepeat)
        for item in flattened {
            if item.pair.valueType == .file {
                let fileURL = URL(fileURLWithPath: item.pair.value)
                guard let fileData = try? Data(contentsOf: fileURL) else { continue }
                let filename = fileURL.lastPathComponent
                let mimeType = mimeTypeForPath(item.pair.value)
                body += Data("--\(boundary)\(crlf)".utf8)
                body += Data("Content-Disposition: form-data; name=\"\(item.name)\"; filename=\"\(filename)\"\(crlf)".utf8)
                body += Data("Content-Type: \(mimeType)\(crlf)\(crlf)".utf8)
                body += fileData
            } else {
                body += Data("--\(boundary)\(crlf)".utf8)
                body += Data("Content-Disposition: form-data; name=\"\(item.name)\"\(crlf)\(crlf)".utf8)
                body += Data("\(item.pair.value)".utf8)
            }

            body += Data(crlf.utf8)
        }
        body += Data("--\(boundary)--\(crlf)".utf8)
        return body
    }

    private static func mimeTypeForPath(_ path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "json": return "application/json"
        case "xml": return "application/xml"
        case "pdf": return "application/pdf"
        case "zip": return "application/zip"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "txt": return "text/plain"
        case "html", "htm": return "text/html"
        case "css": return "text/css"
        case "js": return "application/javascript"
        case "csv": return "text/csv"
        default: return "application/octet-stream"
        }
    }
}
