import SwiftUI

struct BookingShareView: View {
    @State private var bookingLink = "http://localhost:3000/booking.html"
    
    var body: some View {
        VStack(spacing: 30) {
            Text("NEO")
                .font(.neoTitle)
                .padding(.top, 40)
            Text("Online Randevu Paylaş")
                .font(.neoHeadline)
                .foregroundColor(.gray)
            
            // QR Code Placeholder
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundColor(.black)
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
            
            Text("Hastalarınız bu QR kodu tarayarak veya aşağıdaki linke tıklayarak randevularını kendileri oluşturabilirler.")
                .font(.neoBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
            
            // Link Box
            HStack {
                Text(bookingLink)
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = bookingLink
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal, 40)
            
            // Share Button
            Button(action: shareLink) {
                Label("Bağlantıyı Paylaş", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.neoPrimary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(Color.neoBackground.edgesIgnoringSafeArea(.all))
    }
    
    func shareLink() {
        let av = UIActivityViewController(activityItems: [bookingLink], applicationActivities: nil)
        
        // Root View Controller fix for SwiftUI
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true, completion: nil)
        }
    }
}
