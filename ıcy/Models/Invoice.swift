import Foundation

struct Invoice: Codable, Identifiable {
    let id: String
    let amount: Double
    let currency: String
    let status: String
    let type: String
    let description: String
    let invoiceDate: Date
    let eInvoiceNumber: String?
}
