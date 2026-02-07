import Foundation

struct User: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let role: UserRole
    let avatarUrl: String?
    let branch: Branch?
    let allowedIPs: [String]?
    let lastLoginIP: String?
}

struct Branch: Identifiable, Codable {
    let id: String
    let name: String
    let city: String
}

enum UserRole: String, Codable {
    case admin
    case doctor
    case staff
    case patient
    
    var title: String {
        switch self {
        case .admin: return "Yönetici"
        case .doctor: return "Doktor"
        case .staff: return "Asistan"
        case .patient: return "Hasta"
        }
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}
