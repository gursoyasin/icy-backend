import SwiftUI

struct StaffManagementView: View {
    @State private var staff: [User] = []
    @State private var showingAddSheet = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.neoBackground.edgesIgnoringSafeArea(.all)
            
            if isLoading {
                ProgressView("Yükleniyor...")
            } else if staff.isEmpty {
                 VStack(spacing: 20) {
                    Image(systemName: "person.3.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Henüz personel eklenmemiş.")
                        .foregroundColor(.gray)
                    Button("Personel Ekle") { showingAddSheet = true }
                        .padding()
                        .background(Color.neoPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                List {
                    ForEach(staff) { user in
                        HStack(spacing: 15) {
                            Circle()
                                .fill(roleColor(user.role).opacity(0.1))
                                .frame(width: 40, height: 40)
                                .overlay(Text(user.name.prefix(1)).foregroundColor(roleColor(user.role)))
                            
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.system(.body, design: .rounded).bold())
                                    .foregroundColor(.neoTextPrimary)
                                HStack {
                                    Text(user.role.title)
                                        .font(.caption)
                                        .foregroundColor(roleColor(user.role))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(roleColor(user.role).opacity(0.1))
                                        .cornerRadius(4)
                                    
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteUser(user)
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Personel Yönetimi")
        .navigationBarItems(trailing: Button(action: { showingAddSheet = true }) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(.neoPrimary)
        })
        .sheet(isPresented: $showingAddSheet, onDismiss: { loadData() }) {
            AddStaffView()
        }
        .onAppear { loadData() }
        .alert(item: Binding<AlertItem?>(
            get: { errorMessage.map { AlertItem(message: $0) } },
            set: { _ in errorMessage = nil }
        )) { item in
            Alert(title: Text("Hata"), message: Text(item.message), dismissButton: .default(Text("Tamam")))
        }
    }
    
    func loadData() {
        isLoading = true
        Task {
            do {
                staff = try await APIService.shared.fetchStaff()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func deleteUser(_ user: User) {
        Task {
            do {
                try await APIService.shared.deleteUser(id: user.id)
                if let index = staff.firstIndex(where: { $0.id == user.id }) {
                    staff.remove(at: index)
                }
            } catch {
                errorMessage = "Silinemedi: \(error.localizedDescription)"
            }
        }
    }
    
    func roleColor(_ role: UserRole) -> Color {
        switch role {
        case .admin: return .neoSecondary
        case .doctor: return .neoPrimary
        case .staff: return .orange
        case .patient: return .gray
        }
    }
}

struct AlertItem: Identifiable {
    var id = UUID()
    var message: String
}
