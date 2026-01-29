import SwiftUI

struct AddPhotoView: View {
    let patientId: String
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    
    @State private var selectedType = "before"
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Hangi fotoğrafı yüklemek istiyorsunuz?")
                    .font(.neoHeadline)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                HStack(spacing: 20) {
                    // Before Button
                    Button(action: { selectedType = "before" }) {
                        VStack {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 40))
                            Text("Öncesi\n(Before)")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(selectedType == "before" ? .white : .neoPrimary)
                        .frame(width: 100, height: 100)
                        .background(selectedType == "before" ? Color.neoPrimary : Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                    }
                    
                    // After Button
                    Button(action: { selectedType = "after" }) {
                        VStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 40))
                            Text("Sonrası\n(After)")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(selectedType == "after" ? .white : .neoSuccess)
                        .frame(width: 100, height: 100)
                        .background(selectedType == "after" ? Color.neoSuccess : Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                    }
                }
                
                Divider().padding()
                
                // Mock Upload Area
                VStack(spacing: 15) {
                    Image(systemName: "icloud.and.arrow.up")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Fotoğraf seçmek için dokunun (Simülasyon)")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(style: StrokeStyle(lineWidth: 1, dash: [5])).foregroundColor(.gray))
                .padding(.horizontal)
                .onTapGesture {
                    // Trigger mock upload
                    upload()
                }
                
                if isLoading {
                    ProgressView()
                    Text("Yükleniyor...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .navigationTitle("Fotoğraf Yükle")
            .toolbar {
                Button("Kapat") { isPresented = false }
            }
        }
    }
    
    func upload() {
        isLoading = true
        // Real Base64 Image Simulation (Using a system icon as the "photo" for demo purposes)
        // In a real device scenario, we would use PHPickerViewController to get UIImage
        let image = UIImage(systemName: "person.crop.square.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        guard let imageData = image?.jpegData(compressionQuality: 0.8) else { return }
        let base64String = imageData.base64EncodedString()
        
        Task {
            do {
                _ = try await APIService.shared.uploadPhoto(patientId: patientId, type: selectedType, imageBase64: base64String)
                isLoading = false
                isPresented = false
                onSuccess()
            } catch {
                print("Upload err: \(error)")
                isLoading = false
            }
        }
    }
}
