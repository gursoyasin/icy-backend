import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    @State private var messageText = ""
    @State private var messages = Message.mocks
    
    var body: some View {
        ZStack {
            Color.neoBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                
                // Input Area
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    TextField("Bir mesaj yazın...", text: $messageText)
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.neoPrimary)
                            .padding(8)
                            .background(Color.neoPrimary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: -2)
            }
        }
        .navigationTitle(conversation.contactName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Initial load
            await loadMessages()
            
            // Simple Polling Mechanism (every 2 seconds)
            // Note: In production, invalidation or sockets are better.
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                await loadMessages()
            }
        }
    }
    
    func loadMessages() async {
        do {
            let fetched = try await APIService.shared.fetchMessages(conversationId: conversation.id)
            withAnimation {
                messages = fetched
            }
        } catch {
            print("Error fetching messages: \(error)")
        }
    }
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        let textToSend = messageText
        messageText = "" // clear immediately for UI responsiveness
        
        Task {
            do {
                _ = try await APIService.shared.sendMessage(conversationId: conversation.id, content: textToSend)
                await loadMessages()
            } catch {
                print("Send error: \(error)")
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.neoPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .cornerRadius(2, corners: .bottomRight)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .cornerRadius(2, corners: .bottomLeft)
                Spacer()
            }
        }
    }
}


