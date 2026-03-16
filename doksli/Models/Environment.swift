import Foundation

// MARK: - EnvVar

struct EnvVar: Codable, Identifiable {
    var id: UUID
    var key: String
    var value: String
    var enabled: Bool
}

// MARK: - Environment

struct Environment: Codable, Identifiable {
    var id: UUID
    var name: String
    var variables: [EnvVar]
}
