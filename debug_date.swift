
import Foundation

struct Appt: Decodable {
    let date: Date
}

let json = """
{ "date": "2026-01-29T18:41:00.000Z" }
"""

let data = json.data(using: .utf8)!
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

do {
    let result = try decoder.decode(Appt.self, from: data)
    print("Success: \(result.date)")
} catch {
    print("Failure: \(error)")
}
