import SwiftUI

struct AddClinicView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var clinicName = ""
    @State private var city = ""
    @State private var adminName = ""
    @State private var email = ""
    @State private var password = ""
    
    @State private var isLoading = false
    @State private var showingSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.neoPrimary)
                        .shadow(color: .neoPrimary.opacity(0.3), radius: 10)
                    
                    Text("Yeni Klinik Onboarding")
                        .font(.neoTitle)
                    
                    Text("Yeni bir müşteri kliniği oluşturun ve yönetici atayın.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 30)
                
                // Form
                VStack(spacing: 20) {
                    Group {
                        TextField("Klinik Adı (Örn: Estetik Center)", text: $clinicName)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                        
                        TextField("Şehir (Örn: İstanbul)", text: $city)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                        
                        Divider()
                        
                        TextField("Yönetici Adı (Örn: Dr. Ahmet)", text: $adminName)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                        
                        TextField("Yönetici Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                        
                        SecureField("Geçici Şifre", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                    }
                }
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView("Klinik oluşturuluyor...")
                }
                
                Button(action: createClinic) {
                    Text("Kliniği Oluştur ve Yetkilendir")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(formIsValid ? Color.neoPrimary : Color.gray)
                        .cornerRadius(16)
                        .shadow(color: formIsValid ? .neoPrimary.opacity(0.3) : .clear, radius: 10, y: 5)
                }
                .disabled(!formIsValid || isLoading)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .background(Color.neoBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("Klinik Ekle")
        .alert("Başarılı", isPresented: $showingSuccess) {
            Button("Tamam") { presentationMode.wrappedValue.dismiss() }
        } message: {
            Text("\(clinicName) başarıyla oluşturuldu. Yönetici: \(email)")
        }
    }
    
    var formIsValid: Bool {
        !clinicName.isEmpty && !email.isEmpty && !password.isEmpty && !adminName.isEmpty
    }
    
    func createClinic() {
        isLoading = true
        Task {
            do {
                try await APIService.shared.createClinic(
                    name: clinicName,
                    city: city,
                    adminName: adminName,
                    email: email,
                    password: password
                )
                isLoading = false
                showingSuccess = true
            } catch {
                print("Error: \(error)")
                isLoading = false
            }
        }
    }
}

struct AddClinicView_Previews: PreviewProvider {
    static var previews: some View {
        AddClinicView()
    }
}
