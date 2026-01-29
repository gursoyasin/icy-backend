import SwiftUI

struct AddTransferView: View {
    let patientId: String
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    
    @State private var pickupLocation = ""
    @State private var dropoffLocation = ""
    @State private var pickupTime = Date()
    @State private var driverName = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Header Icon
                    Circle()
                        .fill(Color.neoPrimary.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(Image(systemName: "car.fill").font(.largeTitle).foregroundColor(.neoPrimary))
                        .padding(.top, 20)
                    
                    VStack(spacing: 15) {
                        CustomTextField(icon: "mappin.and.ellipse", placeholder: "Alınacak Yer (Havalimanı)", text: $pickupLocation)
                        CustomTextField(icon: "mappin.circle.fill", placeholder: "Bırakılacak Yer (Otel/Klinik)", text: $dropoffLocation)
                        CustomTextField(icon: "person.fill", placeholder: "Şoför Adı (Opsiyonel)", text: $driverName)
                        
                        HStack {
                            Image(systemName: "clock.fill").foregroundColor(.gray)
                            DatePicker("Saat", selection: $pickupTime, in: Date()...)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 5)
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView().padding()
                    } else {
                        Button(action: save) {
                            Text("Transfer Ekle")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(pickupLocation.isEmpty || dropoffLocation.isEmpty ? Color.gray : Color.neoPrimary)
                                .cornerRadius(12)
                                .shadow(color: .neoPrimary.opacity(0.3), radius: 5)
                        }
                        .disabled(pickupLocation.isEmpty || dropoffLocation.isEmpty)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Yeni Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { isPresented = false }
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    func save() {
        isLoading = true
        Task {
            do {
                _ = try await APIService.shared.createTransfer(
                    patientId: patientId,
                    pickupTime: pickupTime,
                    pickupLocation: pickupLocation,
                    dropoffLocation: dropoffLocation,
                    driverName: driverName
                )
                isLoading = false
                isPresented = false
                onSuccess()
            } catch {
                print("Transfer Hata: \(error)")
                isLoading = false
            }
        }
    }
}
