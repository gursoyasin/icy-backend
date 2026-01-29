import Foundation

struct Conversation: Identifiable, Codable {
    let id: String
    let platform: String
    let contact: String
    let updatedAt: Date
    let messages: [Message]?
    
    // UI Helpers
    var contactName: String { contact }
    
    var lastMessage: String {
        return messages?.first?.content ?? "No messages"
    }
    
    var date: Date { updatedAt }
    
    var unreadCount: Int { 0 } // Future: Implement read status
    
    var platformType: Platform {
        return Platform(rawValue: platform.lowercased()) ?? .email
    }
}

enum Platform: String, Codable {
    case whatsapp = "whatsapp"
    case instagram = "instagram"
    case sms = "sms"
    case email = "email"
    case internalApp = "internal" // 'internal' is a keyword, so we map it carefully
    
    var iconName: String {
        switch self {
        case .whatsapp: return "message.circle.fill"
        case .instagram: return "camera.fill"
        case .sms: return "bubble.left.fill"
        case .email: return "envelope.fill"
        case .internalApp: return "person.2.fill"
        }
    }
}
