import Foundation

struct PhotoEntry: Codable, Identifiable {
    let id: String
    let beforeUrl: String?
    let afterUrl: String?
    let date: Date
    let notes: String?
}
