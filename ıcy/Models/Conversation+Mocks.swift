import Foundation

extension Conversation {
    static let mocks: [Conversation] = [
        Conversation(id: "1", platform: "whatsapp", contact: "Ahmet Yılmaz", updatedAt: Date(), messages: [
            Message(id: "1", content: "Merhaba, randevu alabilir miyim?", conversationId: "1", isFromUser: false, userId: nil, createdAt: Date())
        ])
    ]
}
