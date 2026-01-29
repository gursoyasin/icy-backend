import SwiftUI

struct AddStaffView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var email = ""
    @State private var role = "doctor"
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    let roles = ["doctor", "staff", "admin"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 25) {
                    // Header Icon
                    Circle()
                        .fill(Color.neoSecondary.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(Image(systemName: "person.badge.plus.fill").font(.largeTitle).foregroundColor(.neoSecondary))
                        .padding(.top, 20)
                    
                    VStack(spacing: 15) {
                        CustomTextField(icon: "person.fill", placeholder: "Ad Soyad", text: $name)
                        CustomTextField(icon: "envelope.fill", placeholder: "E-posta", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        // Role Picker
                        HStack {
                            Image(systemName: "briefcase.fill")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            Picker("Rol", selection: $role) {
                                ForEach(roles, id: \.self) { roleName in
                                    Text(roleName.capitalized).tag(roleName)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 5)
                    }
                    .padding(.horizontal)
                    
                    Text("Varsayılan şifre: 'password' olarak atanacaktır.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        Button(action: save) {
                            Text("Personeli Kaydet")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(name.isEmpty || email.isEmpty ? Color.gray : Color.neoSecondary)
                                .cornerRadius(12)
                                .shadow(color: .neoSecondary.opacity(0.3), radius: 5, y: 3)
                        }
                        .disabled(name.isEmpty || email.isEmpty)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Yeni Personel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.gray)
                }
            }
            .alert(isPresented: $showingError) {
                Alert(title: Text("Hata"), message: Text(errorMessage), dismissButton: .default(Text("Tamam")))
            }
        }
    }
    
    func save() {
        isLoading = true
        Task {
            do {
                _ = try await APIService.shared.registerUser(name: name, email: email, role: role)
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                isLoading = false
            }
        }
    }
}

struct AddStaffView_Previews: PreviewProvider {
    static var previews: some View {
        AddStaffView()
    }
}
