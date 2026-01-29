import SwiftUI

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    @State private var user: User?
    @State private var showingSupport = false

    @State private var showingChangePassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header
                        if let user = user {
                            HStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                    .overlay(Text(user.name.prefix(1)).font(.largeTitle).foregroundColor(.neoPrimary))
                                    .shadow(radius: 5)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(user.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    HStack {
                                        Text("Rol: \(user.role.title)")
                                        if let branch = user.branch {
                                            Text("• \(branch.name)")
                                        }
                                    }
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(4)
                                    .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding(25)
                            .background(LinearGradient(gradient: Gradient(colors: [.neoPrimary, .neoSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(20)
                            .shadow(color: .neoPrimary.opacity(0.3), radius: 10, y: 5)
                            .padding()
                        }
                        
                        // Menu Items
                        VStack(spacing: 0) {
                            SettingsRow(icon: "bell.fill", title: "Bildirimler", isToggle: true)
                            Divider().padding(.leading, 50)
                            SettingsRow(icon: "moon.fill", title: "Karanlık Mod", isToggle: true)
                            Divider().padding(.leading, 50)
                            
                            // Real Features
                            Button(action: { /* Change Language Logic */ }) {
                                SettingsRow(icon: "globe", title: "Dil (Language)", value: "Türkçe")
                            }
                            Divider().padding(.leading, 50)
                            
                            // Password Change (Security)
                             Button(action: { showingChangePassword = true }) {
                                SettingsRow(icon: "lock.fill", title: "Şifre Değiştir")
                            }
                            Divider().padding(.leading, 50)
                            
                            if (user?.role ?? .staff) == .admin {
                                // Management Section
                                Text("YÖNETİM PANELİ")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 10)
                                    .padding(.bottom, 5)
                                    .padding(.horizontal)
                                    
                                NavigationLink(destination: StaffManagementView()) {
                                    SettingsRow(icon: "person.3.fill", title: "Personel Yönetimi")
                                }
                                Divider().padding(.leading, 50)
                                
                                Button(action: { /* Change Branch Logic */ }) {
                                    SettingsRow(icon: "building.2.fill", title: "Şube Ayarları", value: user?.branch?.name ?? "Merkez")
                                }
                                Divider().padding(.leading, 50)
                            }
                            
                            Text("DESTEK")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 10)
                                .padding(.bottom, 5)
                                .padding(.horizontal)
                            
                            Button(action: { showingSupport = true }) {
                                SettingsRow(icon: "questionmark.circle.fill", title: "Yardım & Destek")
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.03), radius: 5)
                        
                        // Logout
                        Button(action: { isLoggedIn = false }) {
                            Text("Çıkış Yap")
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.03), radius: 5)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSupport) {
                AddSupportTicketView(isPresented: $showingSupport)
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView(isPresented: $showingChangePassword)
            }
            .task {
                do { 
                    user = try await APIService.shared.fetchProfile() 
                    print("Settings Profile Loaded: Role = \(user?.role.rawValue ?? "nil")")
                } catch { 
                    print("Settings Profile Fetch Error: \(error)")
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var isToggle: Bool = false
    @State private var isOn = true
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.neoPrimary)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .foregroundColor(.neoTextPrimary)
            
            Spacer()
            
            if isToggle {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            } else if let val = value {
                Text(val)
                    .font(.caption)
                    .foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
            }
        }
        .padding()
        .contentShape(Rectangle()) // Make full row tapable
    }
}

struct ChangePasswordView: View {
    @Binding var isPresented: Bool
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var message: String? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Mevcut Şifre")) {
                    SecureField("Eski Şifreniz", text: $oldPassword)
                }
                
                Section(header: Text("Yeni Şifre")) {
                    SecureField("Yeni Şifre", text: $newPassword)
                    SecureField("Yeni Şifre (Tekrar)", text: $confirmPassword)
                }
                
                if let msg = message {
                    Text(msg)
                        .foregroundColor(msg.contains("başarıyla") ? .green : .red)
                }
                
                Button("Şifreyi Güncelle") {
                    changePassword()
                }
                .disabled(oldPassword.isEmpty || newPassword.isEmpty || newPassword != confirmPassword)
            }
            .navigationTitle("Şifre Değiştir")
            .navigationBarItems(trailing: Button("Kapat") { isPresented = false })
        }
    }
    
    func changePassword() {
        guard newPassword == confirmPassword else {
            message = "Yeni şifreler uyuşmuyor."
            return
        }
        
        isLoading = true
        Task {
            do {
                try await APIService.shared.changePassword(old: oldPassword, new: newPassword)
                message = "Şifreniz başarıyla güncellendi."
                oldPassword = ""
                newPassword = ""
                confirmPassword = ""
            } catch {
                message = "Hata: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
