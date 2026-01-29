import SwiftUI

struct SurveyView: View {
    let patientId: String
    @Environment(\.presentationMode) var presentationMode
    
    @State private var rating = 5
    @State private var feedback = ""
    @State private var isSent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    if isSent {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.neoSuccess)
                                .shadow(color: .neoSuccess.opacity(0.3), radius: 10)
                            
                            Text("Geri Bildiriminiz Alındı!")
                                .font(.neoTitle)
                                .foregroundColor(.neoTextPrimary)
                            
                            Text("Değerli görüşleriniz için teşekkür ederiz.")
                                .font(.neoBody)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        VStack(spacing: 10) {
                            Text("Deneyiminizi Puanlayın")
                                .font(.neoHeadline)
                                .foregroundColor(.neoTextSecondary)
                            
                            HStack(spacing: 15) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 35))
                                        .foregroundColor(star <= rating ? .neoSecondary : .gray.opacity(0.3))
                                        .shadow(color: star <= rating ? .neoSecondary.opacity(0.4) : .clear, radius: 5)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                rating = star
                                            }
                                        }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 5)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ek Görüşleriniz")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.neoTextSecondary)
                                .padding(.leading, 5)
                            
                            TextEditor(text: $feedback)
                                .frame(height: 120)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.03), radius: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: send) {
                            Text("Anketi Gönder")
                                .font(.neoBody)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [.neoPrimary, .neoSecondary]), startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(16)
                                .shadow(color: .neoPrimary.opacity(0.3), radius: 10, y: 5)
                        }
                        .padding(.vertical)
                    }
                }
                .padding()
            }
            .navigationTitle("Hasta Anketi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isSent {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("İptal") { presentationMode.wrappedValue.dismiss() }
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    func send() {
        // Animation and Dismiss
        withAnimation {
            isSent = true
        }
        
        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
