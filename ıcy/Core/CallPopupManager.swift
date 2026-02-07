import SwiftUI
import Combine

class CallPopupManager: ObservableObject {
    static let shared = CallPopupManager()
    
    @Published var showPopup = false
    @Published var callerNumber = ""
    @Published var patientName = ""
    @Published var patientId: String?
    
    private init() {}
    
    func simulateIncomingCall(number: String, name: String, id: String?) {
        // In real app, this is triggered by Socket.IO event "call_incoming"
        DispatchQueue.main.async {
            self.callerNumber = number
            self.patientName = name
            self.patientId = id
            self.showPopup = true
        }
    }
    
    func connectSocket() {
        // Socket connection logic would go here
        // socket.on("call_incoming") { data in ... }
        print("Socket connecting...")
    }
}

struct CallPopupView: View {
    @ObservedObject var manager = CallPopupManager.shared
    
    var body: some View {
        if manager.showPopup {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "phone.badge.waveform.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text("Gelen Arama")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(manager.patientName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(manager.callerNumber)
                            .font(.subheadline)
                    }
                    Spacer()
                }
                
                HStack(spacing: 15) {
                    Button(action: {
                        // Open Patient Detail
                        manager.showPopup = false
                    }) {
                        Text("Kartı Aç")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.neoPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        manager.showPopup = false
                    }) {
                        Text("Kapat")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding()
            .transition(.move(edge: .top))
            .zIndex(100) // Ensure it's on top
        }
    }
}
