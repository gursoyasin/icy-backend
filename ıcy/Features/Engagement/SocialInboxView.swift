import SwiftUI

struct SocialInboxView: View {
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    
    var body: some View {
        List {
            if conversations.isEmpty && !isLoading {
                Text("No messages yet.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(conversations) { conversation in
                    NavigationLink(destination: ChatDetailView(conversation: conversation)) {
                        HStack {
                            Image(systemName: iconForPlatform(conversation.platform))
                                .foregroundColor(colorForPlatform(conversation.platform))
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(conversation.contact)
                                    .font(.headline)
                                Text(conversation.lastMessage ?? "No messages")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text(timeAgo(conversation.updatedAt))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Social Inbox")
        .onAppear(perform: loadConversations)
    }
    
    // Mock Models for UI construction
    struct Conversation: Identifiable {
        let id: String
        let platform: String // whatsapp, instagram, facebook
        let contact: String
        let lastMessage: String?
        let updatedAt: Date
    }
    
    func loadConversations() {
        // Mock data
        conversations = [
            Conversation(id: "1", platform: "instagram", contact: "berna_akyar", lastMessage: "Fiyat bilgisi alabilir miyim?", updatedAt: Date()),
            Conversation(id: "2", platform: "facebook", contact: "Mehmet Yılmaz", lastMessage: "Randevu oluşturdum.", updatedAt: Date().addingTimeInterval(-3600)),
            Conversation(id: "3", platform: "whatsapp", contact: "+90 555 123 4567", lastMessage: "Konum atar mısınız?", updatedAt: Date().addingTimeInterval(-86400))
        ]
    }
    
    func iconForPlatform(_ platform: String) -> String {
        switch platform {
        case "instagram": return "camera.circle.fill" // SF Symbol approximation
        case "facebook": return "f.circle.fill"
        case "whatsapp": return "phone.circle.fill"
        default: return "message.circle.fill"
        }
    }
    
    func colorForPlatform(_ platform: String) -> Color {
        switch platform {
        case "instagram": return .pink
        case "facebook": return .blue
        case "whatsapp": return .green
        default: return .gray
        }
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ChatDetailView: View {
    let conversation: SocialInboxView.Conversation
    @State private var messageText = ""
    @State private var messages: [Message] = []
    
    struct Message: Identifiable {
        let id = UUID()
        let content: String
        let isFromUser: Bool
    }
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        HStack {
                            if message.isFromUser {
                                Spacer()
                                Text(message.content)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(12)
                            } else {
                                Text(message.content)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            HStack {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                }
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .navigationTitle(conversation.contact)
        .onAppear {
            // Mock initial messages
            messages = [
                Message(content: "Merhaba, nasıl yardımcı olabilirim?", isFromUser: true),
                Message(content: conversation.lastMessage ?? "", isFromUser: false)
            ]
        }
    }
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        messages.append(Message(content: messageText, isFromUser: true))
        messageText = ""
        // Call API to send reply
    }
}

struct SocialInboxView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SocialInboxView()
        }
    }
}
