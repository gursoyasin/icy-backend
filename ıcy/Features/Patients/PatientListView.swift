import SwiftUI

struct PatientListView: View {
    @State private var searchText = ""
    @State private var patients: [Patient] = []
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var selectedPatientForEdit: Patient? // State for edit
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if patients.isEmpty {
                            Text(searchText.isEmpty ? "Hiç hasta yok." : "Sonuç bulunamadı.")
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        } else {
                            ForEach(patients) { patient in
                                NavigationLink(destination: PatientDetailView(patient: patient)) {
                                    PatientCard(patient: patient)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(patient: patient)
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        selectedPatientForEdit = patient
                                    } label: {
                                        Label("Düzenle", systemImage: "pencil")
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .searchable(text: $searchText, prompt: "İsim veya Telefon Ara")
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty {
                    refreshData() // Reset to all
                } else if newValue.count > 2 {
                    performSearch(query: newValue)
                }
            }
            .navigationTitle("Hastalar")
            .navigationBarItems(trailing: Button(action: {
                showingAddSheet = true
            }) {
                Image(systemName: "person.badge.plus")
                    .font(.title3)
                    .foregroundColor(.neoPrimary)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            })
            .sheet(isPresented: $showingAddSheet, onDismiss: {
                refreshData()
            }) {
                AddPatientView()
            }
            .sheet(item: $selectedPatientForEdit) { patient in
                EditPatientView(patient: patient, isPresented: Binding(
                    get: { selectedPatientForEdit != nil },
                    set: { if !$0 { selectedPatientForEdit = nil } }
                )) {
                    refreshData()
                }
            }
            .alert(isPresented: $showingError) {
                Alert(title: Text("Hata"), message: Text(errorMessage), dismissButton: .default(Text("Tamam")))
            }
            .onAppear {
                refreshData()
            }
        }
    }
    
    func refreshData() {
        Task {
            do {
                patients = try await APIService.shared.fetchPatients()
            } catch {
                print("Reload error: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    func performSearch(query: String) {
        Task {
            do {
                // Using the strict Backend Search API
                patients = try await APIService.shared.searchPatients(query: query)
            } catch {
                print("Search error: \(error)")
            }
        }
    }
    
    func delete(patient: Patient) {
        Task {
            do {
                try await APIService.shared.deletePatient(id: patient.id)
                // Refresh list locally
                if let index = patients.firstIndex(where: { $0.id == patient.id }) {
                    patients.remove(at: index)
                }
            } catch {
                print("Delete error: \(error)")
            }
        }
    }
}

struct PatientCard: View {
    let patient: Patient
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.neoPrimary, .neoSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                Text(patient.initials)
                    .font(.neoHeadline)
                    .foregroundColor(.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.fullName)
                    .font(.neoHeadline)
                    .foregroundColor(.neoTextPrimary)
                
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(patient.email ?? "E-posta yok")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Status Tag
            Text(statusTitle(for: patient.status))
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusColor(for: patient.status).opacity(0.1))
                .foregroundColor(statusColor(for: patient.status))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(statusColor(for: patient.status), lineWidth: 1)
                )
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
                .font(.caption)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
    }
    
    func statusColor(for status: PatientStatus) -> Color {
        switch status {
        case .active: return .neoPrimary
        case .lead: return .neoWarning
        case .treated: return .neoSuccess
        case .archived: return .gray
        }
    }
    
    func statusTitle(for status: PatientStatus) -> String {
        switch status {
        case .active: return "Aktif"
        case .lead: return "Potansiyel"
        case .treated: return "Tedavi Edildi"
        case .archived: return "Arşiv"
        }
    }
}

struct PatientListView_Previews: PreviewProvider {
    static var previews: some View {
        PatientListView()
    }
}
