import SwiftUI

struct NewConversationView: View {
    @Binding var isPresented: Bool
    @State private var patients: [Patient] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Search Bar Placeholder (Visual only for now)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        Text("Hasta Ara...")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.03), radius: 5)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(patients) { patient in
                                Button(action: {
                                    isPresented = false
                                }) {
                                    HStack(spacing: 15) {
                                        Circle()
                                            .fill(LinearGradient(gradient: Gradient(colors: [.neoPrimary, .neoSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 50, height: 50)
                                            .overlay(Text(patient.initials).font(.headline).foregroundColor(.white))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(patient.fullName)
                                                .font(.headline) // Using system font effectively matches neoHeadline usually
                                                .foregroundColor(.neoTextPrimary)
                                            
                                            Text("Sohbeti Başlat")
                                                .font(.caption)
                                                .foregroundColor(.neoPrimary)
                                        }
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.03), radius: 3)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Yeni Sohbet")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                do {
                    patients = try await APIService.shared.fetchPatients()
                } catch { print(error) }
            }
            .toolbar {
                Button("İptal") { isPresented = false }
                    .foregroundColor(.gray)
            }
        }
    }
}
