import Foundation

// MARK: - CurlParser

enum CurlParser {

    enum ParseError: LocalizedError {
        case empty
        case notCurl
        case missingURL

        var errorDescription: String? {
            switch self {
            case .empty: return "Input is empty."
            case .notCurl: return "Command must start with \"curl\"."
            case .missingURL: return "No URL found in the curl command."
            }
        }
    }

    // MARK: - Public API

    static func parse(_ input: String) -> Result<Request, ParseError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.empty) }

        // Normalize line continuations (backslash + newline)
        let normalized = trimmed
            .replacingOccurrences(of: "\\\n", with: " ")
            .replacingOccurrences(of: "\\\r\n", with: " ")

        let tokens = tokenize(normalized)
        guard let first = tokens.first, first.lowercased() == "curl" else {
            return .failure(.notCurl)
        }

        return parseTokens(Array(tokens.dropFirst()))
    }

    // MARK: - Shell tokenizer

    /// Splits a shell command string into tokens, respecting single quotes, double quotes,
    /// and backslash escapes.
    private static func tokenize(_ input: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var i = input.startIndex
        var inSingle = false
        var inDouble = false

        while i < input.endIndex {
            let c = input[i]

            if inSingle {
                if c == "'" {
                    inSingle = false
                } else {
                    current.append(c)
                }
            } else if inDouble {
                if c == "\\" && input.index(after: i) < input.endIndex {
                    let next = input[input.index(after: i)]
                    if next == "\"" || next == "\\" || next == "$" || next == "`" {
                        current.append(next)
                        i = input.index(after: i)
                    } else {
                        current.append(c)
                    }
                } else if c == "\"" {
                    inDouble = false
                } else {
                    current.append(c)
                }
            } else {
                if c == "\\" && input.index(after: i) < input.endIndex {
                    let next = input[input.index(after: i)]
                    current.append(next)
                    i = input.index(after: i)
                } else if c == "'" {
                    inSingle = true
                } else if c == "\"" {
                    inDouble = true
                } else if c.isWhitespace {
                    if !current.isEmpty {
                        tokens.append(current)
                        current = ""
                    }
                } else {
                    current.append(c)
                }
            }

            i = input.index(after: i)
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens
    }

    // MARK: - Token parser

    private static func parseTokens(_ tokens: [String]) -> Result<Request, ParseError> {
        var method: HTTPMethod? = nil
        var url: String? = nil
        var headers: [KVPair] = []
        var auth: Auth = .none
        var bodyData: [String] = []
        var formPairs: [KVPair] = []
        var forceGet = false

        var i = 0
        while i < tokens.count {
            let token = tokens[i]

            switch token {
            // Method
            case "-X", "--request":
                i += 1
                if i < tokens.count {
                    method = HTTPMethod(rawValue: tokens[i].uppercased()) ?? .GET
                }

            // Headers
            case "-H", "--header":
                i += 1
                if i < tokens.count {
                    let headerStr = tokens[i]
                    if let colonIndex = headerStr.firstIndex(of: ":") {
                        let key = String(headerStr[headerStr.startIndex..<colonIndex])
                            .trimmingCharacters(in: .whitespaces)
                        let value = String(headerStr[headerStr.index(after: colonIndex)...])
                            .trimmingCharacters(in: .whitespaces)

                        // Detect Authorization: Bearer
                        if key.lowercased() == "authorization" && value.lowercased().hasPrefix("bearer ") {
                            let token = String(value.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                            auth = .bearer(token)
                        } else {
                            headers.append(KVPair(id: UUID(), key: key, value: value, enabled: true))
                        }
                    }
                }

            // Basic auth
            case "-u", "--user":
                i += 1
                if i < tokens.count {
                    let cred = tokens[i]
                    if let colonIndex = cred.firstIndex(of: ":") {
                        let user = String(cred[cred.startIndex..<colonIndex])
                        let pass = String(cred[cred.index(after: colonIndex)...])
                        auth = .basic(user, pass)
                    } else {
                        auth = .basic(cred, "")
                    }
                }

            // Body data
            case "-d", "--data", "--data-raw", "--data-binary":
                i += 1
                if i < tokens.count {
                    bodyData.append(tokens[i])
                }

            // Form data
            case "-F", "--form":
                i += 1
                if i < tokens.count {
                    let pair = tokens[i]
                    if let eqIndex = pair.firstIndex(of: "=") {
                        let key = String(pair[pair.startIndex..<eqIndex])
                        var value = String(pair[pair.index(after: eqIndex)...])
                        var valueType: KVPair.ValueType = .text
                        if value.hasPrefix("@") {
                            value = String(value.dropFirst())
                            valueType = .file
                        }
                        formPairs.append(KVPair(id: UUID(), key: key, value: value, enabled: true,
                                                valueType: valueType))
                    }
                }

            // Force GET
            case "-G", "--get":
                forceGet = true

            // URL via --url flag
            case "--url":
                i += 1
                if i < tokens.count {
                    url = tokens[i]
                }

            // Ignored flags with a value argument
            case "-o", "--output", "-e", "--referer", "-A", "--user-agent",
                 "--connect-timeout", "-m", "--max-time", "--retry",
                 "-w", "--write-out", "--cacert", "--cert", "--key":
                i += 1 // skip the value

            // Ignored boolean flags
            case "-g", "--globoff", "-L", "--location", "-k", "--insecure",
                 "-v", "--verbose", "-s", "--silent", "-S", "--show-error",
                 "--compressed", "-I", "--head", "-i", "--include", "-N":
                break

            default:
                // Treat as URL if it looks like one and we don't have a URL yet
                if url == nil && !token.hasPrefix("-") {
                    url = token
                }
            }

            i += 1
        }

        // HEAD method detection
        if tokens.contains("-I") || tokens.contains("--head") {
            method = .HEAD
        }

        guard let rawURL = url else {
            return .failure(.missingURL)
        }

        // Split URL into base + query params
        var baseURL: String
        var params: [KVPair] = []
        if let qIndex = rawURL.firstIndex(of: "?") {
            baseURL = String(rawURL[rawURL.startIndex..<qIndex])
            let queryString = String(rawURL[rawURL.index(after: qIndex)...])
            params = parseQueryString(queryString)
        } else {
            baseURL = rawURL
        }

        // Determine body
        let body: RequestBody
        if !formPairs.isEmpty {
            body = .formData(formPairs)
        } else if let data = bodyData.last {
            let trimmed = data.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
                body = .json(data)
            } else if isURLEncoded(trimmed) {
                body = .urlEncoded(parseQueryString(trimmed))
            } else {
                body = .json(data)
            }
        } else {
            body = .none
        }

        // Determine method
        let resolvedMethod: HTTPMethod
        if forceGet {
            resolvedMethod = .GET
        } else if let m = method {
            resolvedMethod = m
        } else if body != .none {
            resolvedMethod = .POST
        } else {
            resolvedMethod = .GET
        }

        // Filter out Content-Type from headers if it was auto-added by CurlBuilder
        // (the body type already implies it)
        let filteredHeaders: [KVPair]
        if case .json = body {
            filteredHeaders = headers.filter { $0.key.lowercased() != "content-type" ||
                !$0.value.lowercased().contains("json") }
        } else {
            filteredHeaders = headers
        }

        let request = Request(
            id: UUID(),
            name: hostFromURL(baseURL),
            method: resolvedMethod,
            url: baseURL,
            params: params,
            headers: filteredHeaders,
            body: body,
            auth: auth
        )

        return .success(request)
    }

    // MARK: - Helpers

    private static func parseQueryString(_ query: String) -> [KVPair] {
        query.split(separator: "&", omittingEmptySubsequences: true).map { part in
            let pair = part.split(separator: "=", maxSplits: 1)
            let key = String(pair[0]).removingPercentEncoding ?? String(pair[0])
            let value = pair.count > 1 ? (String(pair[1]).removingPercentEncoding ?? String(pair[1])) : ""
            return KVPair(id: UUID(), key: key, value: value, enabled: true)
        }
    }

    private static func isURLEncoded(_ string: String) -> Bool {
        // Must contain at least one key=value and no JSON-like characters
        let hasEquals = string.contains("=")
        let looksLikeJSON = string.hasPrefix("{") || string.hasPrefix("[")
        let hasNewlines = string.contains("\n")
        return hasEquals && !looksLikeJSON && !hasNewlines
    }

    private static func hostFromURL(_ url: String) -> String {
        guard let components = URLComponents(string: url), let host = components.host else {
            return "Imported request"
        }
        return host
    }
}
