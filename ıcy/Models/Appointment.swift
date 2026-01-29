import Foundation

struct Appointment: Identifiable, Codable {
    let id: String
    let patientId: String
    let date: Date
    let type: String
    let status: AppointmentStatus
    let graftCount: Int?
    
    // Nested objects from Prisma `include`
    let patient: Patient?
    
    // Fallback for flat JSON response
    private let _patientName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, patientId, date, type, status, graftCount, patient, _patientName = "patientName"
    }

    // UI Helpers
    var patientName: String {
        return patient?.fullName ?? _patientName ?? "Unknown Patient"
    }
    
    var doctorName: String {
        return "Dr. Yacn" // Placeholder until Doctor relation is fetched
    }
}

enum AppointmentStatus: String, Codable {
    case scheduled = "scheduled"
    case completed = "completed"
    case cancelled = "cancelled"
    case noShow = "no-show" // Fixed to match backend
    case active = "active"
    case arrived = "arrived" // Added
    
    var title: String {
        switch self {
        case .scheduled: return "Planlandı"
        case .completed: return "Tamamlandı"
        case .cancelled: return "İptal Edildi"
        case .noShow: return "Gelmedi"
        case .active: return "Aktif"
        case .arrived: return "Geldi"
        }
    }
}
