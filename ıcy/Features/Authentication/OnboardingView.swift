import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(image: "heart.text.square.fill", title: " Neo'ya Hoşgeldiniz", description: "Klinik yönetiminde yapay zeka destekli yeni bir çağ başlıyor."),
        OnboardingPage(image: "chart.bar.xaxis", title: "Detaylı Analizler", description: "Hasta, gelir ve randevu verilerinizi tek bir ekrandan yönetin."),
        OnboardingPage(image: "bubble.left.and.bubble.right.fill", title: "Unified Inbox", description: "WhatsApp, Instagram ve SMS mesajlarınızı tek kutuda toplayın."),
        OnboardingPage(image: "airplane.departure", title: "Sağlık Turizmi", description: "Uçak, transfer ve otel rezervasyonlarını profesyonelce planlayın.")
    ]
    
    var body: some View {
        ZStack {
            Color.neoBackground.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            Image(systemName: pages[index].image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .foregroundColor(.neoPrimary)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .neoPrimary.opacity(0.3), radius: 10)
                            
                            Text(pages[index].title)
                                .font(.neoLargeTitle)
                                .multilineTextAlignment(.center)
                            
                            Text(pages[index].description)
                                .font(.neoBody)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.neoTextSecondary)
                                .padding(.horizontal, 40)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .frame(height: 400)
                
                Spacer()
                
                // Button
                Button(action: next) {
                    Text(currentPage == pages.count - 1 ? "Başla" : "İlerle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.neoPrimary)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    func next() {
        withAnimation {
            if currentPage < pages.count - 1 {
                currentPage += 1
            } else {
                isCompleted = true
            }
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}
