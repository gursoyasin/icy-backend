import Foundation

struct Accommodation: Codable, Identifiable {
    let id: String
    let hotelName: String
    let checkInDate: Date
    let checkOutDate: Date
    let roomType: String?
    let status: String
}
