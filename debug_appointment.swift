
import Foundation

struct Patient: Codable {
    let id: String
    let fullName: String
    // Minimal mock for checking appointment decoding
}

enum AppointmentStatus: String, Codable {
    case scheduled = "scheduled"
    case completed = "completed"
    case cancelled = "cancelled"
    case noShow = "no-show"
    case active = "active"
    case arrived = "arrived"
}

struct Appointment: Identifiable, Codable {
    let id: String
    let patientId: String
    let date: Date
    let type: String
    let status: AppointmentStatus
    let graftCount: Int?
    
    let patient: Patient?
    private let _patientName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, patientId, date, type, status, graftCount, patient
        case _patientName = "patientName"
    }
}

let json = """
[{"id":"7a2ce27a-fe9e-42d5-88f9-9db493cae49f","patientId":"8aab160f-f501-4409-90fe-9f20b9cacd10","date":"2026-01-29T18:41:00.000Z","type":"Muayene","status":"no-show","patientName":"Ali veli","doctorId":"cef7b22c-2d46-4958-8744-2dcf7cde4c9c","graftCount":0}]
"""

let data = json.data(using: .utf8)!
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

do {
    let result = try decoder.decode([Appointment].self, from: data)
    print("Success! Count: \(result.count)")
    print("First Patient Name: \(result[0].patientId)") // Accessing what we can since _patientName is private
} catch {
    print("Failure: \(error)")
}
