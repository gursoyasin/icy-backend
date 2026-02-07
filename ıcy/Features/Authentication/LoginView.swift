import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @Binding var isLoggedIn: Bool
    
    // Error Handling
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 2FA
    @State private var show2FAInput = false
    @State private var twoFACode = ""
    @State private var userIdFor2FA: String?
    
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
                    
                    Text("ZENITH")
                        .font(.neoLargeTitle)
                        .foregroundColor(.neoPrimary)
                    
                    Text("Powered by Neo")
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
                        Text(show2FAInput ? "Doğrulama Kodu" : "Şifre")
                            .font(.neoCaption)
                            .foregroundColor(.neoTextSecondary)
                        
                        if show2FAInput {
                            TextField("123456", text: $twoFACode)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .keyboardType(.numberPad)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        } else {
                            SecureField("********", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Login Button
                Button(action: {
                    if show2FAInput {
                        performVerify2FA()
                    } else {
                        performLogin()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(show2FAInput ? "Doğrula" : "Giriş Yap")
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
                title: Text("Hata"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
    
    func performLogin() {
        isLoading = true
        Task {
            do {
                let url = URL(string: "\(AppConfig.baseURL)/auth/login")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body: [String: String] = ["email": email, "password": password]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(LoginResponse.self, from: data)
                
                isLoading = false
                
                if response.require2fa == true {
                    self.userIdFor2FA = response.userId
                    withAnimation {
                        self.show2FAInput = true
                    }
                } else if let token = response.token {
                    APIService.shared.authToken = token // Manually set token since we bypassed shared login
                    if let user = response.user {
                        APIService.shared.currentUser = user // Update in-memory user
                    }
                    withAnimation {
                        isLoggedIn = true
                    }
                } else {
                     throw URLError(.badServerResponse)
                }
            } catch {
                isLoading = false
                errorMessage = "Giriş yapılamadı. Bilgilerinizi kontrol ediniz."
                showError = true
            }
        }
    }
    
    func performVerify2FA() {
        guard let userId = userIdFor2FA else { return }
        isLoading = true
        Task {
            do {
                let (_, _) = try await APIService.shared.verify2FA(userId: userId, code: twoFACode)
                isLoading = false
                withAnimation {
                    isLoggedIn = true
                }
            } catch {
                isLoading = false
                errorMessage = "Hatalı kod."
                showError = true
            }
        }
    }
}

// Helper Model for custom login decoding within View
struct LoginResponse: Codable {
    let token: String?
    let require2fa: Bool?
    let userId: String?
    let message: String?
    let user: User? // Added user object
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
