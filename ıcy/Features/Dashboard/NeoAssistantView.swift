import SwiftUI

struct NeoAssistantView: View {
    @State private var messages: [AIChatMessage] = [
        AIChatMessage(content: "Merhaba! Ben Neo AI. Kliniğinizin verilerini analiz ettim. Bugün size nasıl yardımcı olabilirim?", isUser: false)
    ]
    @State private var inputText = ""
    @State private var isTyping = false
    
    var body: some View {
        VStack {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("NEO AI")
                        .font(.neoTitle)
                        .foregroundColor(.white)
                    Text("Akıllı Klinik Analisti")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [.neoPrimary, .purple]), startPoint: .leading, endPoint: .trailing))
            
            // Chat Area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                        }
                        
                        if isTyping {
                            HStack {
                                Text("Neo düşünüyor...")
                                    .font(.caption)
                                    .italic()
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
            }
            
            // Input
            HStack(spacing: 12) {
                TextField("Verileriniz hakkında soru sorun...", text: $inputText)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(inputText.isEmpty ? .gray : .neoPrimary)
                }
                .disabled(inputText.isEmpty)
            }
            .padding()
            .background(Color.white)
        }
        .navigationTitle("Neo AI")
        .navigationBarHidden(true)
    }
    
    func sendMessage() {
        let userMsg = inputText
        messages.append(AIChatMessage(content: userMsg, isUser: true))
        inputText = ""
        isTyping = true
        
        Task {
            do {
                let response = try await APIService.shared.queryAI(text: userMsg)
                withAnimation {
                    isTyping = false
                    messages.append(AIChatMessage(content: response, isUser: false))
                }
            } catch {
                isTyping = false
                messages.append(AIChatMessage(content: "Üzgünüm, şu an verilerinizi analiz ederken bir hata oluştu.", isUser: false))
            }
        }
    }
}

struct AIChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

struct ChatBubble: View {
    let message: AIChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.neoPrimary : Color.gray.opacity(0.1))
                .foregroundColor(message.isUser ? .white : .neoTextPrimary)
                .cornerRadius(16, corners: message.isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
            
            if !message.isUser { Spacer() }
        }
    }
}
