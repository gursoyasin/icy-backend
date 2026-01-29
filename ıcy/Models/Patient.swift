import Foundation

struct Patient: Identifiable, Codable {
    let id: String
    let fullName: String
    let phoneNumber: String?
    let email: String?
    let status: PatientStatus
    let notes: String?
    let tags: String?
    let source: String?
    let createdAt: Date? // Added to match backend
    
    // UI Helpers
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        if let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)"
        }
        return String(fullName.prefix(1))
    }
    
    var lastVisitDate: Date? { createdAt } // Mapping for UI compatibility
}

enum PatientStatus: String, Codable, CaseIterable {
    case active = "active" // Lowercase to match backend defaults
    case lead = "lead"
    case treated = "treated"
    case archived = "archived"
    
    // UI Display Name
    var rawValue: String {
        switch self {
        case .active: return "Active"
        case .lead: return "New Lead"
        case .treated: return "Treated"
        case .archived: return "Archived"
        }
    }
}
