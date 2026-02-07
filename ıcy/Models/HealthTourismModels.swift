import Foundation

struct Transfer: Identifiable, Codable {
    let id: String
    let pickupTime: Date
    let pickupLocation: String
    let dropoffLocation: String
    let driverName: String?
    let plateNumber: String?
    let status: String
}

struct Accommodation: Identifiable, Codable {
    let id: String
    let hotelName: String
    let checkInDate: Date
    let checkOutDate: Date
    let roomType: String?
    let status: String
}

// Timeline Item Wrapper
enum TimelineItemType {
    case transfer(Transfer)
    case accommodation(Accommodation)
    
    var time: Date {
        switch self {
        case .transfer(let t): return t.pickupTime
        case .accommodation(let a): return a.checkInDate
        }
    }
}
