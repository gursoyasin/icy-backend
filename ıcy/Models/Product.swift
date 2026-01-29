import Foundation

struct Product: Codable, Identifiable {
    let id: String
    let name: String
    let stock: Int
    let price: Double
    let sku: String?
}
