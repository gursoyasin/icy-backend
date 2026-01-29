import SwiftUI

struct AddPatientView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var tags = "" // New State
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 25) {
                    // Header Icon
                    Circle()
                        .fill(Color.neoPrimary.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(Image(systemName: "person.fill.badge.plus").font(.largeTitle).foregroundColor(.neoPrimary))
                        .padding(.top, 20)
                    
                    VStack(spacing: 15) {
                        CustomTextField(icon: "person.fill", placeholder: "Ad Soyad", text: $name)
                        CustomTextField(icon: "envelope.fill", placeholder: "E-posta", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        CustomTextField(icon: "phone.fill", placeholder: "Telefon", text: $phone)
                            .keyboardType(.phonePad)
                        CustomTextField(icon: "tag.fill", placeholder: "Etiketler (Örn: VIP, Risk)", text: $tags) // New Tag Input
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        Button(action: save) {
                            Text("Hastayı Kaydet")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(name.isEmpty || email.isEmpty ? Color.gray : Color.neoPrimary)
                                .cornerRadius(12)
                                .shadow(color: .neoPrimary.opacity(0.3), radius: 5, y: 3)
                        }
                        .disabled(name.isEmpty || email.isEmpty)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Yeni Hasta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    func save() {
        isLoading = true
        Task {
            do {
                _ = try await APIService.shared.createPatient(name: name, email: email, phone: phone, tags: tags)
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Create error: \(error)")
                isLoading = false
            }
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 5)
    }
}

struct AddPatientView_Previews: PreviewProvider {
    static var previews: some View {
        AddPatientView()
    }
}
