import Foundation

struct AppNotification: Codable, Identifiable {
    let id: String
    let title: String
    let message: String
    let type: String
    let isRead: Bool
    let createdAt: Date
}
