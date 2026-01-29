import SwiftUI

struct MessagesView: View {
    @State private var conversations = Conversation.mocks
    @State private var showingNewMessage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 0) { // Slack/WhatsApp style list
                        ForEach(conversations) { conversation in
                            NavigationLink(destination: ChatView(conversation: conversation)) {
                                ConversationRow(conversation: conversation)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider().padding(.leading, 80)
                        }
                    }
                    .background(Color.white)
                }
            }
            .navigationTitle("Mesajlar")
            .toolbar {
                Button(action: { showingNewMessage = true }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.neoPrimary)
                }
            }
            .sheet(isPresented: $showingNewMessage) {
                NewConversationView(isPresented: $showingNewMessage)
            }
            .task {
               do {
                   conversations = try await APIService.shared.fetchConversations()
               } catch { print("Err: \(error)") }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar with Platform Icon
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 56, height: 56)
                    .overlay(Text(conversation.contactName.prefix(1)).font(.title2).fontWeight(.bold).foregroundColor(.neoPrimary))
                
                Image(systemName: conversation.platformType.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .padding(4)
                    .background(Circle().fill(Color.white))
                    .foregroundColor(platformColor(for: conversation.platformType))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.contactName)
                        .font(.headline)
                        .foregroundColor(.neoTextPrimary)
                    Spacer()
                    Text(conversation.date, style: .time)
                        .font(.caption)
                        .foregroundColor(conversation.unreadCount > 0 ? .neoPrimary : .gray)
                        .fontWeight(conversation.unreadCount > 0 ? .bold : .regular)
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(conversation.unreadCount > 0 ? .neoTextPrimary : .gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Circle().fill(Color.neoPrimary))
                    }
                }
            }
        }
        .padding()
        .background(Color.white) // Clickable area
    }
    
    func platformColor(for platform: Platform) -> Color {
        switch platform {
        case .whatsapp: return .green
        case .instagram: return .purple
        case .sms: return .blue
        case .email: return .orange
        case .internalApp: return .neoPrimary
        }
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}
