import SwiftUI

struct AddAppointmentView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPatientIndex = 0
    @State private var patients: [Patient] = []
    
    // Doctor Selection
    @State private var doctors: [User] = []
    @State private var selectedDoctorIndex = 0
    
    @State private var date = Date()
    @State private var type = "Muayene"
    @State private var graftCount = ""
    @State private var isLoading = false
    @State private var showDataAlert = false
    @State private var apiError: String? = nil
    
    let types = ["Muayene", "Saç Ekimi", "Kontrol", "Diş Operasyonu", "Estetik Cerrahi"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 25) {
                    VStack(spacing: 15) {
                        // Patient Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hasta Seçimi")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 5)
                            
                            Menu {
                                ForEach(0..<patients.count, id: \.self) { index in
                                    Button(patients[index].fullName) {
                                        selectedPatientIndex = index
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.neoPrimary)
                                    Text(patients.isEmpty ? "Yükleniyor..." : patients[selectedPatientIndex].fullName)
                                        .foregroundColor(.neoTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 5)
                            }
                        }
                        
                        // Doctor Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Doktor Seçimi")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 5)
                            
                            Menu {
                                ForEach(0..<doctors.count, id: \.self) { index in
                                    Button(doctors[index].name) {
                                        selectedDoctorIndex = index
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "stethoscope")
                                        .foregroundColor(.neoSecondary)
                                    Text(doctors.isEmpty ? "Doktor Seçin" : doctors[selectedDoctorIndex].name)
                                        .foregroundColor(.neoTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 5)
                            }
                        }
                        
                        // Date Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tarih ve Saat")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 5)
                            
                            DatePicker("", selection: $date, in: Date()...)
                                .labelsHidden()
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 5)
                        }
                        
                        // Type Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("İşlem Türü")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 5)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(types, id: \.self) { t in
                                        Button(action: { type = t }) {
                                            Text(t)
                                                .font(.subheadline)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(type == t ? Color.neoPrimary : Color.white)
                                                .foregroundColor(type == t ? .white : .neoTextPrimary)
                                                .cornerRadius(20)
                                                .shadow(color: Color.black.opacity(0.03), radius: 3)
                                        }
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        
                        if type == "Saç Ekimi" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Planlanan Greft Sayısı")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                
                                TextField("Örn: 3500", text: $graftCount)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.03), radius: 5)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                    } else {
                        Button(action: book) {
                            Text("Randevuyu Onayla")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.neoPrimary)
                                .cornerRadius(12)
                                .shadow(color: .neoPrimary.opacity(0.3), radius: 5)
                        }
                        .padding()
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Yeni Randevu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.gray)
                }
            }
            .task {
                do {
                    patients = try await APIService.shared.fetchPatients()
                    doctors = try await APIService.shared.fetchDoctors()
                    
                    if patients.isEmpty || doctors.isEmpty {
                        showDataAlert = true
                    }
                } catch {
                    print("Error loading data: \(error)")
                }
            }
            .alert(isPresented: $showDataAlert) {
                if let error = apiError {
                     return Alert(title: Text("Hata"), message: Text(error), dismissButton: .default(Text("Tamam"), action: { apiError = nil }))
                } else if patients.isEmpty {
                    return Alert(title: Text("Uyarı"), message: Text("Randevu oluşturmak için önce hasta eklemelisiniz."), dismissButton: .default(Text("Tamam"), action: { presentationMode.wrappedValue.dismiss() }))
                } else {
                    return Alert(title: Text("Uyarı"), message: Text("Sistemde kayıtlı doktor bulunamadı."), dismissButton: .default(Text("Tamam"), action: { presentationMode.wrappedValue.dismiss() }))
                }
            }
        }
    }
    
    func book() {
        guard !patients.isEmpty, !doctors.isEmpty else { return }
        let patient = patients[selectedPatientIndex]
        let doctor = doctors[selectedDoctorIndex]
        
        isLoading = true
        Task {
            do {
                let count = Int(graftCount) ?? 0
                _ = try await APIService.shared.createAppointment(patientId: patient.id, doctorId: doctor.id, date: date, type: type, graftCount: count)
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            } catch {
                if let apiErrorVal = error as? APIError, case .serverError(let msg) = apiErrorVal {
                    apiError = msg
                } else {
                     // Debug: Show technical error
                     apiError = String(describing: error)
                }
                isLoading = false
                showDataAlert = true 
            }
        }
    }
}

struct AddAppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        AddAppointmentView()
    }
}
