import SwiftUI

struct AddAccommodationView: View {
    let patientId: String
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    
    @State private var hotelName = ""
    @State private var checkIn = Date()
    @State private var checkOut = Date().addingTimeInterval(86400)
    @State private var roomType = "Standart"
    @State private var isLoading = false
    
    let roomTypes = ["Standart", "Deluxe", "Suite", "King Suite"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Header
                    Circle()
                        .fill(Color.neoSecondary.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(Image(systemName: "building.2.fill").font(.largeTitle).foregroundColor(.neoSecondary))
                        .padding(.top, 20)
                    
                    VStack(spacing: 15) {
                        CustomTextField(icon: "house.fill", placeholder: "Otel Adı", text: $hotelName)
                        
                        // Room Type
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(roomTypes, id: \.self) { type in
                                    Button(action: { roomType = type }) {
                                        Text(type)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(roomType == type ? Color.neoSecondary : Color.white)
                                            .foregroundColor(roomType == type ? .white : .neoTextPrimary)
                                            .cornerRadius(20)
                                            .shadow(radius: 2)
                                    }
                                }
                            }
                            .padding(5)
                        }
                        
                        VStack(spacing: 0) {
                            DatePicker("Giriş Tarihi", selection: $checkIn, in: Date()..., displayedComponents: .date)
                                .padding()
                            Divider()
                            DatePicker("Çıkış Tarihi", selection: $checkOut, in: checkIn..., displayedComponents: .date)
                                .padding()
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 5)
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                    } else {
                        Button(action: save) {
                            Text("Konaklama Ekle")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(hotelName.isEmpty ? Color.gray : Color.neoSecondary)
                                .cornerRadius(12)
                                .shadow(color: .neoSecondary.opacity(0.3), radius: 5)
                        }
                        .disabled(hotelName.isEmpty)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Yeni Konaklama")
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
                 _ = try await APIService.shared.createAccommodation(
                    patientId: patientId,
                    hotelName: hotelName,
                    checkIn: checkIn,
                    checkOut: checkOut,
                    roomType: roomType
                 )
                 isLoading = false
                 isPresented = false
                 onSuccess()
             } catch {
                 print("Hotel error: \(error)")
                 isLoading = false
             }
         }
    }
}
