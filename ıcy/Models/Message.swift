import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let content: String
    let conversationId: String
    let isFromUser: Bool
    let userId: String? // Optional because external messages might not have userId
    let createdAt: Date
    
    // UI Helpers
    var isFromCurrentUser: Bool {
        return isFromUser // Assuming 'User' always means the logged in doctor/staff
    }
    
    var timestamp: Date { createdAt }
}
