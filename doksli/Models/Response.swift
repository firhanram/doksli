import Foundation

// MARK: - Response

struct Response: Codable, Equatable {
    var statusCode: Int
    var headers: [KVPair]
    var body: Data
    var durationMs: Double
    var sizeBytes: Int
}
