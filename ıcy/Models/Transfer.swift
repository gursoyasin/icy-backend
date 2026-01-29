import Foundation

struct Transfer: Codable, Identifiable {
    let id: String
    let pickupTime: Date
    let pickupLocation: String
    let dropoffLocation: String
    let driverName: String?
    let plateNumber: String?
    let status: String
}
