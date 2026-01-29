import Foundation

let json = """
[
  {
    "id": "49047d64-617d-4ae7-ac3a-0a1e611f82df",
    "fullName": "Yasin Gürsoy",
    "email": "gursoyasin@gmail.com",
    "phoneNumber": "5522970760",
    "status": "active",
    "source": "Web",
    "notes": null,
    "createdAt": "2026-01-27T16:17:48.041Z",
    "branchId": "517af895-2506-40d7-b492-6d0d6ca840bc"
  }
]
"""

enum PatientStatus: String, Codable, CaseIterable {
    case active = "active"
    case lead = "lead"
    case treated = "treated"
    case archived = "archived"
}

struct Patient: Identifiable, Codable {
    let id: String
    let fullName: String
    let phoneNumber: String?
    let email: String?
    let status: PatientStatus
    let notes: String?
    let createdAt: Date? 
}

let data = json.data(using: .utf8)!
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
// formatter.locale = Locale(identifier: "en_US_POSIX") // Testing without this first

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .formatted(formatter)

do {
    let patients = try decoder.decode([Patient].self, from: data)
    print("Success: \(patients.count) patients loaded.")
} catch {
    print("Decoding Error: \(error)")
}
