import SwiftUI

struct CampaignView: View {
    @State private var campaignTitle = ""
    @State private var messageBody = ""
    @State private var selectedChannel: MarketingChannel = .whatsapp
    @State private var targetAudience: AudienceType = .leads
    @State private var isLoading = false
    @State private var showSuccess = false
    
    // Premium Features
    @State private var selectedTemplate: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // 1. Sleek Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NEO")
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundColor(.neoPrimary)
                                Text("Pazarlama ve Büyüme Merkezi")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            ZStack {
                                Circle().fill(Color.neoAccent.opacity(0.1)).frame(width: 45, height: 45)
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.neoAccent)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // 2. Quick Actions (Horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                NavigationLink(destination: BookingShareView()) {
                                    QuickActionCard(title: "Randevu Linki", icon: "link", color: .blue)
                                }
                                NavigationLink(destination: AnalyticsView()) {
                                    QuickActionCard(title: "Raporlar", icon: "doc.text.magnifyingglass", color: .purple)
                                }
                                QuickActionCard(title: "Hediye Çeki", icon: "gift.fill", color: .orange)
                            }
                            .padding(.horizontal)
                        }
                        
                        // 3. Campaign Builder Container
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Yeni Kampanya")
                                .font(.neoHeadline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 20) {
                                // Channel Selector
                                HStack(spacing: 12) {
                                    ChannelButton(type: .whatsapp, current: $selectedChannel)
                                    ChannelButton(type: .sms, current: $selectedChannel)
                                    ChannelButton(type: .email, current: $selectedChannel)
                                }
                                
                                // Target
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Hedef Segment", systemImage: "person.2.circle.fill")
                                        .font(.caption).bold().foregroundColor(.gray)
                                    
                                    HStack {
                                        AudienceTag(type: .all, current: $targetAudience)
                                        AudienceTag(type: .leads, current: $targetAudience)
                                        AudienceTag(type: .retention, current: $targetAudience)
                                    }
                                }
                                
                                // Templates
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Hızlı Şablonlar")
                                        .font(.caption).bold().foregroundColor(.gray)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            TemplateChip(title: "Hoş Geldin", templateContent: "Klinigimize hoş geldiniz! İlk muayenenizde %10 indirim kazandınız. Randevu al: http://localhost:3000/booking.html", selected: $selectedTemplate, bodyRef: $messageBody)
                                            TemplateChip(title: "Takip", templateContent: "Kontrol vaktiniz yaklaşıyor. Randevunuzu buradan planlayabilirsiniz: http://localhost:3000/booking.html", selected: $selectedTemplate, bodyRef: $messageBody)
                                            TemplateChip(title: "Kampanya", templateContent: "Bu aya özel tüm saç ekimi işlemlerinde VIP transfer dahil! Randevu: http://localhost:3000/booking.html", selected: $selectedTemplate, bodyRef: $messageBody)
                                        }
                                    }
                                }
                                
                                // Message Area
                                TextField("Kampanya İsmi (Örn: Bahar Fırsatı)", text: $campaignTitle)
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(12)
                                
                                TextEditor(text: $messageBody)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(12)
                                    .overlay(
                                        Text("Mesajınızı yazın...")
                                            .foregroundColor(.gray.opacity(0.5))
                                            .padding(12)
                                            .opacity(messageBody.isEmpty ? 1 : 0),
                                        alignment: .topLeading
                                    )
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.03), radius: 15)
                            .padding(.horizontal)
                        }
                        
                        // 4. PREVIEW (The "WOW" Factor)
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Canlı Önizleme")
                                .font(.neoHeadline)
                                .padding(.horizontal)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 20)
                                
                                VStack(spacing: 0) {
                                    // Mock Phone Header
                                    HStack {
                                        Circle().fill(selectedChannel.color).frame(width: 30, height: 30)
                                            .overlay(Image(systemName: selectedChannel.icon).foregroundColor(.white).font(.system(size: 10)))
                                        Text("Klinik Merkezi").font(.caption).bold()
                                        Spacer()
                                        Image(systemName: "video.fill").font(.caption).foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    
                                    // Mock Message
                                    HStack {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(messageBody.isEmpty ? "Henüz bir mesaj yazılmadı..." : messageBody)
                                                .font(.system(size: 13))
                                            HStack {
                                                Spacer()
                                                Text("12:00").font(.system(size: 8)).foregroundColor(.gray)
                                                if selectedChannel == .whatsapp {
                                                    Image(systemName: "checkmark.seal.fill").font(.system(size: 8)).foregroundColor(.blue)
                                                }
                                            }
                                        }
                                        .padding(12)
                                        .background(selectedChannel == .whatsapp ? Color(red: 0.86, green: 0.97, blue: 0.77) : Color.gray.opacity(0.1))
                                        .cornerRadius(15)
                                        .padding()
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                            .frame(height: 220)
                            .padding(.horizontal)
                        }
                        
                        // 5. Submit Button
                        Button(action: sendCampaign) {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Kampanyayı Gönder")
                                        .fontWeight(.bold)
                                    Image(systemName: "arrow.right.circle.fill")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [selectedChannel.color, selectedChannel.color.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(18)
                            .shadow(color: selectedChannel.color.opacity(0.3), radius: 10, y: 5)
                        }
                        .disabled(messageBody.isEmpty || isLoading)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Başarılı", isPresented: $showSuccess) {
                Button("Harika!", role: .cancel) { }
            } message: {
                Text("Kampanyanız \(selectedChannel.rawValue.capitalized) üzerinden \(targetAudience.title) grubuna başarıyla gönderildi.")
            }
        }
    }
    
    func sendCampaign() {
        isLoading = true
        Task {
            do {
                let response = try await APIService.shared.createCampaign(
                    title: campaignTitle.isEmpty ? "Kampanya" : campaignTitle, 
                    message: messageBody, 
                    channel: selectedChannel.rawValue, 
                    targetAudience: targetAudience.rawValue // Passing raw enum string
                )
                print("Campaign Result: \(response.message)")
                isLoading = false
                showSuccess = true
                messageBody = ""
                selectedTemplate = nil
            } catch {
                print("Campaign error: \(error)")
                isLoading = false
            }
        }
    }
}

// MARK: - Components

enum MarketingChannel: String, CaseIterable {
    case whatsapp, sms, email
    
    var icon: String {
        switch self {
        case .whatsapp: return "bubble.left.and.bubble.right.fill"
        case .sms: return "message.fill"
        case .email: return "envelope.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .whatsapp: return .green
        case .sms: return .blue
        case .email: return .orange
        }
    }
}

struct ChannelButton: View {
    let type: MarketingChannel
    @Binding var current: MarketingChannel
    
    var body: some View {
        Button(action: { current = type }) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title3)
                Text(type.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(current == type ? type.color.opacity(0.1) : Color.gray.opacity(0.05))
            .foregroundColor(current == type ? type.color : .gray)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(current == type ? type.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
}

enum AudienceType: String, CaseIterable {
    case all, leads, retention
    
    var title: String {
        switch self {
        case .all: return "Tüm Hastalar"
        case .leads: return "Potansiyel"
        case .retention: return "Eski Hastalar"
        }
    }
}

struct AudienceTag: View {
    let type: AudienceType
    @Binding var current: AudienceType
    
    var body: some View {
        Button(action: { current = type }) {
            Text(type.title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(current == type ? Color.neoPrimary : Color.gray.opacity(0.1))
                .foregroundColor(current == type ? .white : .gray)
                .cornerRadius(20)
        }
    }
}

struct TemplateChip: View {
    let title: String
    let templateContent: String
    @Binding var selected: String?
    @Binding var bodyRef: String
    
    var body: some View {
        Button(action: {
            selected = title
            bodyRef = templateContent
        }) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(selected == title ? Color.neoSecondary.opacity(0.2) : Color.white)
                .foregroundColor(selected == title ? .neoSecondary : .gray)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selected == title ? Color.neoSecondary : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.neoTextPrimary)
        }
        .padding(16)
        .frame(width: 120, height: 100, alignment: .leading)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

struct CampaignView_Previews: PreviewProvider {
    static var previews: some View {
        CampaignView()
    }
}
