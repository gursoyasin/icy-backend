import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
}

class APIService: ObservableObject {
    static let shared = APIService()
    // Production URL (Render.com)
    private let baseURL = "https://icy-backend-jsju.onrender.com/api"
    
    @Published var authToken: String? {
        didSet {
            UserDefaults.standard.set(authToken, forKey: "authToken")
        }
    }
    
    init() {
        self.authToken = UserDefaults.standard.string(forKey: "authToken")
    }

    @Published var currentUser: User?
    
    func getCurrentUser() -> User? { return currentUser }
    func updateCurrentUser(_ user: User) { self.currentUser = user }

    
    // MARK: - Auth
    func login(email: String, password: String) async throws -> (User, String) {
        guard let url = URL(string: "\(baseURL)/auth/login") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("Invalid credentials")
        }
        
        let decodedResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        self.authToken = decodedResponse.token
        self.currentUser = decodedResponse.user
        return (decodedResponse.user, decodedResponse.token)
    }
    
    func registerUser(name: String, email: String, role: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/auth/register") else { throw APIError.invalidURL }
        guard let token = authToken else { throw APIError.serverError("No auth token") }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["name": name, "email": email, "password": "password", "role": role]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to register user")
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    func fetchStaff() async throws -> [User] {
        return try await fetch(endpoint: "/auth/users")
    }
    
    func deleteUser(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/users/\(id)") else { throw APIError.invalidURL }
        guard let token = authToken else { throw APIError.serverError("No auth token") }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        if (response as? HTTPURLResponse)?.statusCode != 200 {
            throw APIError.serverError("Silme başarısız")
        }
    }
    
    func changePassword(old: String, new: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/change-password") else { throw APIError.invalidURL }
        guard let token = authToken else { throw APIError.serverError("No auth token") }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["oldPassword": old, "newPassword": new]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw APIError.serverError("Network Error")
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Şifre değiştirilemedi. Eski şifrenizi kontrol edin.")
        }
    }
    
    // MARK: - Patients
    func fetchPatients() async throws -> [Patient] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try await fetch(endpoint: "/patients", decoder: decoder)
    }
    
    // MARK: - Appointments
    func fetchAppointments() async throws -> [Appointment] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try await fetch(endpoint: "/appointments", decoder: decoder)
    }
    
    // MARK: - Messaging
    func fetchConversations() async throws -> [Conversation] {
        return try await fetch(endpoint: "/conversations")
    }
    
    func fetchMessages(conversationId: String) async throws -> [Message] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        
        return try await fetch(endpoint: "/conversations/\(conversationId)/messages", decoder: decoder)
    }
    
    // Using a simple socket.io emit event simulation via REST for this phase or just POST
    // Since we didn't implement POST /messages in backend yet (only socket), 
    // let's quickly add a POST endpoint to backend OR use the socket event? 
    // Wait, the backend only listens to 'send_message' via socket.
    // I should probably add a REST endpoint for sending messages to support polling/REST clients.
    // Let's assume I will add it to backend in a sec.
    
    func sendMessage(conversationId: String, content: String) async throws -> Message {
        guard let url = URL(string: "\(baseURL)/messages") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["conversationId": conversationId, "content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to send message")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Message.self, from: data)
    }

    // MARK: - Health Tourism
    func fetchTransfers(patientId: String) async throws -> [Transfer] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try await fetch(endpoint: "/patients/\(patientId)/transfers", decoder: decoder)
    }
    
    func fetchAccommodations(patientId: String) async throws -> [Accommodation] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try await fetch(endpoint: "/patients/\(patientId)/accommodations", decoder: decoder)
    }

    // MARK: - Finance
    func fetchInvoices(patientId: String) async throws -> [Invoice] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try await fetch(endpoint: "/patients/\(patientId)/invoices", decoder: decoder)
    }
    
    func generateInvoice(patientId: String, amount: Double, description: String) async throws -> Invoice {
        guard let url = URL(string: "\(baseURL)/invoices/generate") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "patientId": patientId,
            "amount": amount,
            "description": description,
            "type": "service"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("Invoice generation failed")
        }
        
        // Custom decoder for response
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try decoder.decode(Invoice.self, from: data)
    }

    // MARK: - Visual Records
    func fetchPhotos(patientId: String) async throws -> [PhotoEntry] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try await fetch(endpoint: "/patients/\(patientId)/photos", decoder: decoder)
    }
    
    func uploadPhoto(patientId: String, type: String, imageBase64: String) async throws -> PhotoEntry {
        guard let url = URL(string: "\(baseURL)/photos") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["patientId": patientId, "type": type, "imageBase64": imageBase64]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.serverError("Upload failed")
        }
        
        // Custom decoder for response
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try decoder.decode(PhotoEntry.self, from: data)
    }
    
    func createTransfer(patientId: String, pickupTime: Date, pickupLocation: String, dropoffLocation: String, driverName: String) async throws -> Transfer {
        let utcDate = pickupTime.ISO8601Format()
        let body: [String: Any] = [
             "patientId": patientId,
             "pickupTime": utcDate,
             "pickupLocation": pickupLocation,
             "dropoffLocation": dropoffLocation,
             "driverName": driverName
        ]
        return try await post(endpoint: "/transfers", body: body)
    }
    
    func createAccommodation(patientId: String, hotelName: String, checkIn: Date, checkOut: Date, roomType: String) async throws -> Accommodation {
         let body: [String: Any] = [
              "patientId": patientId,
              "hotelName": hotelName,
              "checkInDate": checkIn.ISO8601Format(),
              "checkOutDate": checkOut.ISO8601Format(),
              "roomType": roomType
         ]
         return try await post(endpoint: "/accommodations", body: body)
    }

    // Helper POST
    private func post<T: Decodable>(endpoint: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.serverError("Post failed") }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try decoder.decode(T.self, from: data)
    }

    func createSupportTicket(subject: String, message: String) async throws -> String {
        let body = ["subject": subject, "message": message]
        // Decode into a struct or Dictionary with concrete types, or ignore return
        struct TicketResponse: Codable { let id: String }
        let _: TicketResponse = try await post(endpoint: "/support", body: body)
        return "Success"
    }
    
    func queryAI(text: String) async throws -> String {
        let body = ["prompt": text]
        struct AIResponse: Codable { let answer: String }
        let res: AIResponse = try await post(endpoint: "/ai/query", body: body)
        return res.answer
    }
    
    // MARK: - Marketing [REAL]
    func createCampaign(title: String, message: String, channel: String, targetAudience: String) async throws -> CampaignResponse {
        let body: [String: Any] = [
            "title": title,
            "message": message,
            "channel": channel,
            "targetAudience": targetAudience
        ]
        

        
        return try await post(endpoint: "/campaigns/send", body: body)
    }

    // MARK: - Operations & Engagement
    func fetchCalls() async throws -> [CallLog] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try await fetch(endpoint: "/calls", decoder: decoder)
    }
    
    func fetchNotifications() async throws -> [AppNotification] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try await fetch(endpoint: "/notifications", decoder: decoder)
    }
    
    // MARK: - Creations [NEW]
    func createPatient(name: String, email: String, phone: String, tags: String?) async throws -> Patient {
        let body: [String: Any] = [
            "fullName": name,
            "email": email,
            "phoneNumber": phone,
            "status": "active",
            "source": "Web",
            "tags": tags ?? ""
        ]
        
        let data = try JSONSerialization.data(withJSONObject: body)
        let url = URL(string: "\(baseURL)/patients")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (responseData, _) = try await URLSession.shared.data(for: request)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try decoder.decode(Patient.self, from: responseData)
    }
    
    func updatePatient(id: String, name: String, email: String, phone: String, tags: String?) async throws -> Patient {
        let body: [String: Any] = [
            "fullName": name,
            "email": email,
            "phoneNumber": phone,
            "tags": tags ?? ""
        ]
        return try await patch(endpoint: "/patients/\(id)", body: body)
    }

    func addPatientNote(id: String, note: String) async throws -> Patient {
         let body: [String: Any] = ["appendNote": note]
         return try await patch(endpoint: "/patients/\(id)", body: body)
    }

    func getPatient(id: String) async throws -> Patient {
        let p: Patient = try await fetch(endpoint: "/patients/\(id)")
        return p
    }

    func searchPatients(query: String) async throws -> [Patient] {
        return try await fetch(endpoint: "/patients?search=\(query)")
    }

    // Helper PATCH
    private func patch<T: Decodable>(endpoint: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.serverError("Patch failed") }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try decoder.decode(T.self, from: data)
    }
    
    func createAppointment(patientId: String, doctorId: String, date: Date, type: String, graftCount: Int?) async throws -> Appointment {
        let utcDate = date.ISO8601Format() // Ensure ISO string
        
        let body: [String: Any] = [
            "patientId": patientId,
            "doctorId": doctorId,
            "date": utcDate,
            "type": type,
            "status": "scheduled",
            "graftCount": graftCount ?? 0
        ]
        
        let data = try JSONSerialization.data(withJSONObject: body)
        let url = URL(string: "\(baseURL)/appointments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw customError("Invalid response")
        }
        
        // Handle Error Codes
        if !(200...299).contains(httpResponse.statusCode) {
            if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let errorMessage = json["error"] as? String {
                throw customError(errorMessage) // "Bu saatte doktorun başka randevusu var" will be caught here
            }
            throw customError("Server error: \(httpResponse.statusCode)")
        }
        
        // Custom decoder handling
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try decoder.decode(Appointment.self, from: responseData) 
    }
    // MARK: - Admin & Settings [NEW]
    func fetchProfile() async throws -> User {
        return try await fetch(endpoint: "/auth/me")
    }
    
    func deletePatient(id: String) async throws {
        let url = URL(string: "\(baseURL)/patients/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw customError("Failed to delete patient")
        }
    }
    
    func updateAppointmentStatus(id: String, status: String) async throws {
        let body = ["status": status]
        let data = try JSONSerialization.data(withJSONObject: body)
        let url = URL(string: "\(baseURL)/appointments/\(id)/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw customError("Failed to update status")
        }
    }
    
    func cancelAppointment(id: String) async throws {
        let url = URL(string: "\(baseURL)/appointments/\(id)/cancel")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH" // Using PATCH for update
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw customError("Failed to cancel appointment")
        }
    }
    
    // Super Admin
    func createClinic(name: String, city: String, adminName: String, email: String, password: String) async throws {
        let body: [String: Any] = [
            "clinicName": name,
            "city": city,
            "adminName": adminName,
            "email": email,
            "password": password
        ]
        // We don't need the return value for now, just success
        struct ClinicResponse: Codable { let success: Bool }
        let _: ClinicResponse = try await post(endpoint: "/admin/clinics", body: body)
    }
    
    func customError(_ msg: String) -> Error {
        return NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
    }
    
    // MARK: - Stats & Analytics
    func fetchStats() async throws -> DashboardStats {
        return try await fetch(endpoint: "/stats")
    }

    func fetchAnalytics() async throws -> AnalyticsData {
        return try await fetch(endpoint: "/analytics")
    }

    // MARK: - Generic Fetch
    private func fetch<T: Decodable>(endpoint: String, decoder: JSONDecoder? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw APIError.serverError("Invalid response type")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError("Server returned \(httpResponse.statusCode)")
        }
        
        // Use provided decoder or default to ISO8601 (standard for our Prisma backend)
        let actualDecoder: JSONDecoder
        if let decoder = decoder {
            actualDecoder = decoder
        } else {
            let isoDecoder = JSONDecoder()
            isoDecoder.dateDecodingStrategy = .iso8601
            actualDecoder = isoDecoder
        }
        
        return try actualDecoder.decode(T.self, from: data)
    }
    func fetchDoctors() async throws -> [User] {
        return try await fetch(endpoint: "/auth/doctors")
    }
    

}

// MARK: - Response Models
struct AnalyticsData: Codable {
    let revenue: [RevenuePoint]
    let sources: [SourcePoint]
    let conversionRate: Double
    let avgGraft: Int
    let noShowRate: Double? // Optional for safety
    let doctorWorkload: [DoctorWorkload]?
}

struct DoctorWorkload: Codable, Identifiable {
    var id: String { name }
    let name: String
    let count: Int
}

struct RevenuePoint: Codable, Identifiable {
    var id: String { date }
    let date: String
    let day: String
    let amount: Double
}

struct SourcePoint: Codable, Identifiable {
    var id: String { label }
    let label: String
    let count: Int
}

struct CampaignResponse: Codable {
    let success: Bool
    let message: String
    let sentCount: Int
}

