import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @Binding var isLoggedIn: Bool
    
    // Error Handling
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.neoBackground.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Logo / Branding
                VStack(spacing: 12) {
                    Image(systemName: "staroflife.fill") // Placeholder logo
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.neoPrimary)
                    
                    Text("ICYSOFT")
                        .font(.neoLargeTitle)
                        .foregroundColor(.neoPrimary)
                    
                    Text("ICY")
                        .font(.neoHeadline)
                        .foregroundColor(.neoSecondary)
                }
                .padding(.top, 60)
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("E-posta")
                            .font(.neoCaption)
                            .foregroundColor(.neoTextSecondary)
                        TextField("ad@klinik.com", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Şifre")
                            .font(.neoCaption)
                            .foregroundColor(.neoTextSecondary)
                        SecureField("********", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal)
                
                // Login Button
                Button(action: performLogin) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Giriş Yap")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right")
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                .disabled(isLoading)
                
                Spacer()
                
                // Footer
                VStack {
                    Text("Yardıma mı ihtiyacınız var?")
                        .font(.neoCaption)
                        .foregroundColor(.neoTextSecondary)
                    Text("Destek ile İletişime Geçin")
                        .font(.neoCaption)
                        .foregroundColor(.neoPrimary)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Giriş Başarısız"),
                message: Text("Sunucuya bağlanılamadı veya bilgiler hatalı."),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
    
    func performLogin() {
        isLoading = true
        Task {
            do {
                let (_, _) = try await APIService.shared.login(email: email, password: password)
                isLoading = false
                withAnimation {
                    isLoggedIn = true
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
                print("Login error: \(error)")
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
