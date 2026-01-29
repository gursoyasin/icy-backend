import Foundation

struct CallLog: Codable, Identifiable {
    let id: String
    let callerNumber: String
    let direction: String
    let status: String
    let duration: Int
    let timestamp: Date
}
