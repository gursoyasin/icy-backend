import Foundation

extension Message {
    static let mocks: [Message] = [
        Message(id: "1", content: "Hello", conversationId: "1", isFromUser: true, userId: "doc1", createdAt: Date()),
        Message(id: "2", content: "Hi there!", conversationId: "1", isFromUser: false, userId: nil, createdAt: Date().addingTimeInterval(60))
    ]
}
