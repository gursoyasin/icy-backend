import SwiftUI

struct PatientDetailView: View {
    let patient: Patient
    @State private var selectedTab = 0
    @State private var showingSurvey = false
    
    // Deletion
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Profile
                HStack(spacing: 20) {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.neoPrimary, .neoSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(patient.initials)
                                .font(.neoLargeTitle)
                                .foregroundColor(.white)
                        )
                        .shadow(color: .neoPrimary.opacity(0.3), radius: 10)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(patient.fullName)
                            .font(.neoTitle)
                            .foregroundColor(.neoTextPrimary)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.caption)
                            Text(patient.email ?? "E-posta yok")
                                .font(.neoBody)
                        }
                        .foregroundColor(.neoTextSecondary)
                        
                        HStack {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                            Text(patient.phoneNumber ?? "Telefon yok")
                                .font(.neoBody)
                        }
                        .foregroundColor(.neoTextSecondary)
                        
                        if let tags = patient.tags, !tags.isEmpty {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .font(.caption)
                                Text(tags)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.neoPrimary.opacity(0.1))
                                    .foregroundColor(.neoPrimary)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
                
                // Actions
                HStack(spacing: 15) {
                    ActionButton(icon: "message.fill", title: "Mesaj", color: .neoSuccess)
                    ActionButton(icon: "phone.fill", title: "Ara", color: .neoPrimary)
                    ActionButton(icon: "doc.text.fill", title: "Anket", color: .purple) { showingSurvey = true }
                }
                .sheet(isPresented: $showingSurvey) {
                    SurveyView(patientId: patient.id)
                }
                
                Divider()
                
                // Info Section
                VStack(alignment: .leading, spacing: 20) {
                    // Custom Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            TabButton(title: "Medikal", isSelected: selectedTab == 0) { selectedTab = 0 }
                            TabButton(title: "Seyahat", isSelected: selectedTab == 1) { selectedTab = 1 }
                            TabButton(title: "Finans", isSelected: selectedTab == 2) { selectedTab = 2 }
                            TabButton(title: "Fotoğraflar", isSelected: selectedTab == 3) { selectedTab = 3 }
                        }
                    }
                    
                    if selectedTab == 0 {
                        // Medical Tab
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Hasta Notları")
                                    .font(.neoHeadline)
                                Spacer()
                                NavigationLink(destination: GraftCalculatorView()) {
                                    HStack {
                                        Image(systemName: "pencil.and.ruler.fill")
                                        Text("Hesaplayıcı")
                                    }
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.neoPrimary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Text(patient.notes ?? "Henüz not eklenmemiş.")
                                .font(.neoBody)
                                .foregroundColor(.neoTextPrimary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 5)
                        }
                    } else if selectedTab == 1 {
                        TravelDetailView(patientId: patient.id)
                    } else if selectedTab == 2 {
                        FinanceDetailView(patientId: patient.id)
                    } else {
                        PhotoDetailView(patientId: patient.id)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Detaylar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Button(role: .destructive, action: deletePatient) {
                    Label("Hastayı Sil", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .background(Color.neoBackground.edgesIgnoringSafeArea(.all))
    }
    
    // Logic
    func deletePatient() {
        Task {
            do {
                try await APIService.shared.deletePatient(id: patient.id)
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Delete failed: \(error)")
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 4, y: 3)
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundColor(isSelected ? .white : .neoTextPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.neoPrimary : Color.white)
                .cornerRadius(20)
                .shadow(color: isSelected ? Color.neoPrimary.opacity(0.3) : Color.black.opacity(0.05), radius: 5)
        }
    }
}

struct TravelDetailView: View {
    let patientId: String
    @State private var transfers: [Transfer] = []
    @State private var accommodations: [Accommodation] = []
    
    // Mock Sheets
    @State private var showAddTransfer = false
    @State private var showAddHotel = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Transfers
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Transferler")
                        .font(.neoHeadline)
                    Spacer()
                    Button(action: { showAddTransfer = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.neoPrimary)
                    }
                }
                
                if transfers.isEmpty {
                    Text("Planlanmış transfer yok.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(transfers) { transfer in
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(.neoPrimary)
                                .padding(10)
                                .background(Color.neoPrimary.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text("\(transfer.pickupLocation) → \(transfer.dropoffLocation)")
                                    .fontWeight(.bold)
                                    .font(.subheadline)
                                Text("\(transfer.pickupTime, style: .date) \(transfer.pickupTime, style: .time)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if let driver = transfer.driverName, !driver.isEmpty {
                                Text(driver)
                                    .font(.caption2)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(5)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 3)
                    }
                }
            }
            .sheet(isPresented: $showAddTransfer) {
                AddTransferView(patientId: patientId, isPresented: $showAddTransfer) {
                     Task { await loadData() }
                }
            }
            
            // Accommodations
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Konaklama")
                        .font(.neoHeadline)
                    Spacer()
                    Button(action: { showAddHotel = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.neoSecondary)
                    }
                }
                
                if accommodations.isEmpty {
                    Text("Otel rezervasyonu yok.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(accommodations) { stay in
                        HStack {
                            Image(systemName: "bed.double.fill")
                                .foregroundColor(.neoSecondary)
                                .padding(10)
                                .background(Color.neoSecondary.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(stay.hotelName)
                                    .fontWeight(.bold)
                                    .font(.subheadline)
                                Text("\(stay.checkInDate, style: .date) - \(stay.checkOutDate, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(stay.roomType ?? "Standart")
                                .font(.caption2)
                                .foregroundColor(.neoPrimary)
                                .padding(6)
                                .background(Color.neoPrimary.opacity(0.1))
                                .cornerRadius(5)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 3)
                    }
                }
            }
            .sheet(isPresented: $showAddHotel) {
                AddAccommodationView(patientId: patientId, isPresented: $showAddHotel) {
                     Task { await loadData() }
                }
            }
        }
        .task {
            await loadData()
        }
    }
    
    func loadData() async {
        do {
            transfers = try await APIService.shared.fetchTransfers(patientId: patientId)
            accommodations = try await APIService.shared.fetchAccommodations(patientId: patientId)
        } catch {
            print("Error loading travel info: \(error)")
        }
    }
}

struct FinanceDetailView: View {
    let patientId: String
    @State private var invoices: [Invoice] = []
    @State private var showingInvoiceSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Faturalar")
                    .font(.neoHeadline)
                Spacer()
                Button(action: { showingInvoiceSheet = true }) {
                    Label("Fatura Kes", systemImage: "plus")
                        .font(.caption)
                        .padding(8)
                        .background(Color.neoPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            if invoices.isEmpty {
                Text("Kayıtlı fatura yok.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(invoices) { invoice in
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.neoSecondary)
                            .padding(10)
                            .background(Color.neoSecondary.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(invoice.description)
                                .fontWeight(.bold)
                                .font(.subheadline)
                            Text(invoice.eInvoiceNumber ?? "GIB Onayı Bekleniyor...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("₺\(Int(invoice.amount))")
                            .fontWeight(.bold)
                            .foregroundColor(.neoPrimary)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.03), radius: 3)
                }
            }
        }
        .sheet(isPresented: $showingInvoiceSheet) {
            GenerateInvoiceView(patientId: patientId, isPresented: $showingInvoiceSheet, onSuccess: {
                Task { await loadInvoices() }
            })
        }
        .task {
            await loadInvoices()
        }
    }
    
    func loadInvoices() async {
        do {
            invoices = try await APIService.shared.fetchInvoices(patientId: patientId)
        } catch {
            print("Error: \(error)")
        }
    }
}

struct GenerateInvoiceView: View {
    let patientId: String
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    
    @State private var amount = ""
    @State private var description = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Fatura Detayları")) {
                    TextField("Tutar (TRY)", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Açıklama (Örn: Saç Ekimi)", text: $description)
                }
                
                Section {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("E-Fatura Oluştur (GIB Entegrasyonu)") {
                            generate()
                        }
                    }
                }
            }
            .navigationTitle("Yeni E-Fatura")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { isPresented = false }
                }
            }
        }
    }
    
    func generate() {
        guard let amountVal = Double(amount), !description.isEmpty else { return }
        isLoading = true
        Task {
            do {
                _ = try await APIService.shared.generateInvoice(patientId: patientId, amount: amountVal, description: description)
                isLoading = false
                isPresented = false
                onSuccess()
            } catch {
                isLoading = false
            }
        }
    }
}

struct PhotoDetailView: View {
    let patientId: String
    @State private var photos: [PhotoEntry] = []
    @State private var showUpload = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Görsel Kayıtlar")
                    .font(.neoHeadline)
                Spacer()
                Button(action: { showUpload = true }) {
                    Label("Yükle", systemImage: "arrow.up.doc")
                        .font(.caption)
                        .padding(8)
                        .background(Color.neoPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            if photos.isEmpty {
                Text("Fotoğraf yüklenmedi.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(photos) { photo in
                    VStack(alignment: .leading) {
                        Text(photo.notes ?? "Karşılaştırma")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom, 5)
                        
                        if let before = photo.beforeUrl, let after = photo.afterUrl, let beforeURL = URL(string: before), let afterURL = URL(string: after) {
                             // Use Premium Slider
                            AsyncImage(url: beforeURL) { phaseBefore in
                                if let bImage = phaseBefore.image {
                                    AsyncImage(url: afterURL) { phaseAfter in
                                         if let aImage = phaseAfter.image {
                                             BeforeAfterView(beforeImage: bImage, afterImage: aImage)
                                                 .frame(height: 250)
                                         } else {
                                             ProgressView()
                                         }
                                    }
                                } else {
                                    ProgressView()
                                }
                            }
                            
                        } else {
                             // Fallback for single images
                            HStack(spacing: 12) {
                                if let before = photo.beforeUrl {
                                    AsyncImage(url: URL(string: before)) { image in
                                        image.resizable()
                                    } placeholder: { Color.gray.opacity(0.3) }
                                    .aspectRatio(3/4, contentMode: .fill)
                                    .frame(height: 150)
                                    .cornerRadius(8)
                                    .clipped()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
            }
        }
        .sheet(isPresented: $showUpload) {
            AddPhotoView(patientId: patientId, isPresented: $showUpload) {
                Task { await loadData() }
            }
        }
        .task {
            await loadData()
        }
    }
    
    func loadData() async {
        do {
            photos = try await APIService.shared.fetchPhotos(patientId: patientId)
        } catch { }
    }
}

struct PatientDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PatientDetailView(patient: Patient.mocks[0])
    }
}
