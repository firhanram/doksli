import Foundation

// MARK: - PostmanImporter

enum PostmanImporter {

    enum ImportError: Error, LocalizedError {
        case invalidFormat
        case invalidCollection

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "The file is not a valid Postman environment export."
            case .invalidCollection:
                return "The file is not a valid Postman collection (v2.1.0)."
            }
        }
    }

    // MARK: - Postman environment types

    private struct PostmanEnvironment: Decodable {
        let name: String
        let values: [PostmanValue]
    }

    private struct PostmanValue: Decodable {
        let key: String
        let value: String
        let enabled: Bool
    }

    // MARK: - Postman collection v2.1.0 types

    private struct PostmanCollection: Decodable {
        let info: PostmanInfo
        let item: [PostmanItem]
    }

    private struct PostmanInfo: Decodable {
        let name: String
    }

    // Item: folder (has `item` array) or request (has `request` field)
    private struct PostmanItem: Decodable {
        let name: String?
        let item: [PostmanItem]?
        let request: PostmanRequestWrapper?
    }

    // Request can be a plain string (URL) or a full object
    private enum PostmanRequestWrapper: Decodable {
        case string(String)
        case object(PostmanRequest)

        init(from decoder: Decoder) throws {
            if let container = try? decoder.singleValueContainer(),
               let str = try? container.decode(String.self) {
                self = .string(str)
            } else {
                self = .object(try PostmanRequest(from: decoder))
            }
        }
    }

    private struct PostmanRequest: Decodable {
        let method: String?
        let url: PostmanURL?
        let header: [PostmanHeader]?
        let body: PostmanBody?
        let auth: PostmanAuth?
    }

    // URL can be a plain string or a structured object
    private enum PostmanURL: Decodable {
        case string(String)
        case object(PostmanURLObject)

        init(from decoder: Decoder) throws {
            if let container = try? decoder.singleValueContainer(),
               let str = try? container.decode(String.self) {
                self = .string(str)
            } else {
                self = .object(try PostmanURLObject(from: decoder))
            }
        }
    }

    private struct PostmanURLObject: Decodable {
        let raw: String?
        let query: [PostmanQuery]?
    }

    private struct PostmanQuery: Decodable {
        let key: String?
        let value: String?
        let disabled: Bool?
    }

    private struct PostmanHeader: Decodable {
        let key: String
        let value: String?
        let disabled: Bool?
    }

    private struct PostmanBody: Decodable {
        let mode: String?
        let raw: String?
        let formdata: [PostmanFormDataItem]?
        let urlencoded: [PostmanFormDataItem]?
    }

    private struct PostmanFormDataItem: Decodable {
        let key: String
        let value: String?
        let type: String?
        let src: String?
        let disabled: Bool?
    }

    private struct PostmanAuth: Decodable {
        let type: String
        let bearer: [PostmanAuthKV]?
        let basic: [PostmanAuthKV]?
        let apikey: [PostmanAuthKV]?
    }

    // Auth attribute value can be string, number, or boolean
    private struct PostmanAuthKV: Decodable {
        let key: String
        let value: AnyCodableValue?
    }

    private enum AnyCodableValue: Decodable {
        case string(String)
        case number(Double)
        case bool(Bool)

        var stringValue: String {
            switch self {
            case .string(let s): return s
            case .number(let n):
                return n.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(n)) : String(n)
            case .bool(let b): return b ? "true" : "false"
            }
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let s = try? c.decode(String.self) { self = .string(s) }
            else if let b = try? c.decode(Bool.self) { self = .bool(b) }
            else if let n = try? c.decode(Double.self) { self = .number(n) }
            else { self = .string("") }
        }
    }

    // MARK: - Import environment

    static func importEnvironment(from url: URL) throws -> Environment {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportError.invalidFormat
        }

        let postman: PostmanEnvironment
        do {
            postman = try JSONDecoder().decode(PostmanEnvironment.self, from: data)
        } catch {
            throw ImportError.invalidFormat
        }

        let variables = postman.values.map { pv in
            EnvVar(id: UUID(), key: pv.key, value: pv.value, enabled: pv.enabled)
        }
        return Environment(id: UUID(), name: postman.name, variables: variables)
    }

    // MARK: - Import result

    struct CollectionImportResult {
        let folder: Folder          // tree with RequestStubs
        let requests: [Request]     // full requests to persist
    }

    // MARK: - Import collection

    static func importCollection(from url: URL) throws -> CollectionImportResult {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportError.invalidCollection
        }

        let postman: PostmanCollection
        do {
            postman = try JSONDecoder().decode(PostmanCollection.self, from: data)
        } catch {
            throw ImportError.invalidCollection
        }

        var requests: [Request] = []
        let items = postman.item.map { convertItem($0, collecting: &requests) }
        let folder = Folder(id: UUID(), name: postman.info.name, items: items)
        return CollectionImportResult(folder: folder, requests: requests)
    }

    // MARK: - Conversion helpers

    private static func convertItem(_ item: PostmanItem, collecting requests: inout [Request]) -> Item {
        let name = item.name ?? "Untitled"

        if let children = item.item {
            let folder = Folder(
                id: UUID(),
                name: name,
                items: children.map { convertItem($0, collecting: &requests) }
            )
            return .folder(folder)
        } else if let reqWrapper = item.request {
            let request: Request
            switch reqWrapper {
            case .string(let urlString):
                request = Request(
                    id: UUID(), name: name, method: .GET, url: urlString,
                    params: [], headers: [], body: .none, auth: .none
                )
            case .object(let req):
                request = convertRequest(name: name, from: req)
            }
            requests.append(request)
            return .request(RequestStub(from: request))
        } else {
            return .folder(Folder(id: UUID(), name: name, items: []))
        }
    }

    private static func convertRequest(name: String, from req: PostmanRequest) -> Request {
        let method = HTTPMethod(rawValue: (req.method ?? "GET").uppercased()) ?? .GET
        let rawURL: String
        var queryParams: [KVPair] = []

        if let url = req.url {
            switch url {
            case .string(let s):
                rawURL = s
            case .object(let obj):
                rawURL = obj.raw ?? ""
                queryParams = (obj.query ?? []).compactMap { q in
                    guard let key = q.key else { return nil }
                    return KVPair(key: key, value: q.value ?? "",
                                  enabled: !(q.disabled ?? false))
                }
            }
        } else {
            rawURL = ""
        }

        // Strip query string from URL — params are stored separately
        let baseURL = rawURL.components(separatedBy: "?").first ?? rawURL

        let headers = (req.header ?? []).map { h in
            KVPair(key: h.key, value: h.value ?? "",
                   enabled: !(h.disabled ?? false))
        }

        let body = convertBody(req.body)
        let auth = convertAuth(req.auth)

        return Request(id: UUID(), name: name, method: method, url: baseURL,
                       params: queryParams, headers: headers, body: body, auth: auth)
    }

    private static func convertBody(_ body: PostmanBody?) -> RequestBody {
        guard let body = body, let mode = body.mode else { return .none }
        switch mode {
        case "raw":
            let raw = body.raw ?? ""
            return raw.isEmpty ? .none : .json(raw)
        case "formdata":
            let pairs = (body.formdata ?? []).map { item in
                KVPair(key: item.key,
                       value: item.type == "file" ? (item.src ?? "") : (item.value ?? ""),
                       enabled: !(item.disabled ?? false),
                       valueType: item.type == "file" ? .file : .text)
            }
            return pairs.isEmpty ? .none : .formData(pairs)
        case "urlencoded":
            let pairs = (body.urlencoded ?? []).map { item in
                KVPair(key: item.key, value: item.value ?? "",
                       enabled: !(item.disabled ?? false))
            }
            return pairs.isEmpty ? .none : .urlEncoded(pairs)
        default:
            return .none
        }
    }

    private static func convertAuth(_ auth: PostmanAuth?) -> Auth {
        guard let auth = auth else { return .none }
        switch auth.type {
        case "bearer":
            let token = auth.bearer?.first(where: { $0.key == "token" })?.value?.stringValue ?? ""
            return .bearer(token)
        case "basic":
            let user = auth.basic?.first(where: { $0.key == "username" })?.value?.stringValue ?? ""
            let pass = auth.basic?.first(where: { $0.key == "password" })?.value?.stringValue ?? ""
            return .basic(user, pass)
        case "apikey":
            let key = auth.apikey?.first(where: { $0.key == "key" })?.value?.stringValue ?? ""
            let value = auth.apikey?.first(where: { $0.key == "value" })?.value?.stringValue ?? ""
            return .apiKey(key, value)
        default:
            return .none
        }
    }
}
