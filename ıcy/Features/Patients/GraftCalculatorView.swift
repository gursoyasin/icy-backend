import SwiftUI

struct GraftCalculatorView: View {
    // Regions: Frontal, Mid-Scalp, Crown
    @State private var frontalGrafts: Double = 0
    @State private var midScalpGrafts: Double = 0
    @State private var crownGrafts: Double = 0
    
    // Pricing
    @State private var pricePerGraft: Double = 1.5 // EUR
    
    // API & State
    @State private var patients: [Patient] = []
    @State private var selectedPatientId: String = ""
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    var totalGrafts: Int {
        Int(frontalGrafts + midScalpGrafts + crownGrafts)
    }
    
    var estimatedPrice: Double {
        Double(totalGrafts) * pricePerGraft
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header (Head Map Visual)
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 200, height: 240)
                    
                    VStack {
                        // Frontal
                        RegionCircle(value: $frontalGrafts, color: .blue, title: "Ön Bölge")
                        // Mid
                        RegionCircle(value: $midScalpGrafts, color: .green, title: "Tepe")
                        // Crown
                        RegionCircle(value: $crownGrafts, color: .orange, title: "Arka")
                    }
                }
                .padding()
                
                // Patient Selection (Real Data)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hasta Seçimi")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading)
                    
                    if patients.isEmpty {
                        Text("Yükleniyor...")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        Menu {
                            ForEach(patients) { patient in
                                Button(patient.fullName) {
                                    selectedPatientId = patient.id
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedPatientName)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Sliders
                VStack(spacing: 20) {
                    GraftSlider(title: "Ön Bölge (Frontal)", value: $frontalGrafts, color: .blue)
                    GraftSlider(title: "Tepe Bölgesi (Mid)", value: $midScalpGrafts, color: .green)
                    GraftSlider(title: "Arka Bölge (Crown)", value: $crownGrafts, color: .orange)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
                .padding(.horizontal)
                
                // Summary Card
                VStack(spacing: 15) {
                    HStack {
                        Text("Toplam Greft")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(totalGrafts)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Tahmini Fiyat (€)")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "€%.0f", estimatedPrice))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.neoPrimary)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.neoPrimary.opacity(0.2), radius: 10)
                .padding(.horizontal)
                
                // Action Button (Real Save)
                Button(action: saveCalculation) {
                    HStack {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Hesaplamayı Kaydet")
                                .fontWeight(.bold)
                            Image(systemName: "square.and.arrow.down.fill")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isFormValid ? Color.neoPrimary : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isSaving)
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationTitle("Greft Hesaplayıcı")
        .background(Color.neoBackground.edgesIgnoringSafeArea(.all))
        .onAppear { loadPatients() }
        .alert("Başarılı", isPresented: $showSuccess) {
            Button("Tamam", role: .cancel) {
                // Reset
                frontalGrafts = 0
                midScalpGrafts = 0
                crownGrafts = 0
                selectedPatientId = ""
            }
        } message: {
            Text("Greft analizi hasta dosyasına not olarak eklendi.")
        }
    }
    
    // Logic
    var isFormValid: Bool {
        return !selectedPatientId.isEmpty && totalGrafts > 0
    }
    
    var selectedPatientName: String {
        if let p = patients.first(where: { $0.id == selectedPatientId }) {
            return p.fullName
        }
        return "Hasta Seçin"
    }
    
    func loadPatients() {
        Task {
            do {
                // Fetch recent patients for quick selection
                patients = try await APIService.shared.fetchPatients()
            } catch {
                print("Error loading patients: \(error)")
            }
        }
    }
    
    func saveCalculation() {
        guard isFormValid else { return }
        isSaving = true
        
        let noteContent = """
        GREFT ANALİZİ:
        - Ön: \(Int(frontalGrafts))
        - Orta: \(Int(midScalpGrafts))
        - Arka: \(Int(crownGrafts))
        - TOPLAM: \(totalGrafts) Greft
        - Tahmini Fiyat: €\(String(format: "%.0f", estimatedPrice))
        """
        
        Task {
            do {
                _ = try await APIService.shared.addPatientNote(id: selectedPatientId, note: noteContent)
                isSaving = false
                showSuccess = true
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct RegionCircle: View {
    @Binding var value: Double
    let color: Color
    let title: String
    
    var body: some View {
        Circle()
            .fill(color.opacity(Double(value)/3000.0 + 0.1))
            .frame(width: 60, height: 60)
            .overlay(Text("\(Int(value))").font(.caption).bold())
            .overlay(Text(title).font(.caption2).offset(y: 35))
    }
}

struct GraftSlider: View {
    let title: String
    @Binding var value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title).font(.subheadline).bold()
                Spacer()
                Text("\(Int(value)) greft").font(.caption).foregroundColor(.gray)
            }
            Slider(value: $value, in: 0...3000, step: 100)
                .accentColor(color)
        }
    }
}
