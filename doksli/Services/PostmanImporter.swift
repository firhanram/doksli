import Foundation

// MARK: - PostmanImporter

enum PostmanImporter {

    enum ImportError: Error, LocalizedError {
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "The file is not a valid Postman environment export."
            }
        }
    }

    // MARK: - Postman format types

    private struct PostmanEnvironment: Decodable {
        let name: String
        let values: [PostmanValue]
    }

    private struct PostmanValue: Decodable {
        let key: String
        let value: String
        let enabled: Bool
    }

    // MARK: - Import

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
}
