import Foundation

// Mocks for Preview
extension Patient {
    static let mocks: [Patient] = [
        Patient(id: "1", fullName: "Ahmet Yılmaz", phoneNumber: "+90 555 111 22 33", email: "ahmet@mail.com", status: .active, notes: "Interested in FUE.", tags: "VIP", source: "Instagram", createdAt: Date()),
        Patient(id: "2", fullName: "Ayşe Demir", phoneNumber: "+90 532 999 88 77", email: "ayse@mail.com", status: .treated, notes: "Post-op control completed.", tags: nil, source: "Web", createdAt: Date().addingTimeInterval(-86400 * 10))
    ]
}
