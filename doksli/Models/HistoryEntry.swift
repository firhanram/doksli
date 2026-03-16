import Foundation

// MARK: - HistoryEntry

struct HistoryEntry: Codable, Identifiable {
    var id: UUID
    var request: Request
    var response: Response
    var timestamp: Date
}
