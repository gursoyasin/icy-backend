import SwiftUI

struct SecuritySettingsView: View {
    @State private var allowedIPs: [String] = []
    @State private var currentIP: String = "Loading..."
    @State private var isLoading = false
    
    // In a real app, this would come from UserSession or ViewModel
    // For demo, we assume we can fetch/update via APIService
    
    var body: some View {
        List {
            Section(header: Text("Current Session")) {
                HStack {
                    Text("Your IP Address")
                    Spacer()
                    Text(currentIP)
                        .foregroundColor(.gray)
                }
                
                Button(action: authorizeCurrentIP) {
                    Label("Authorize This IP", systemImage: "checkmark.shield")
                }
                .disabled(allowedIPs.contains(currentIP) || currentIP == "Loading...")
            }
            
            Section(header: Text("Allowed IP Addresses")) {
                if allowedIPs.isEmpty {
                    Text("No restrictions. Access allowed from anywhere.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(allowedIPs, id: \.self) { ip in
                        HStack {
                            Text(ip)
                            Spacer()
                            if ip == currentIP {
                                Text("(You)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .onDelete(perform: deleteIP)
                }
            }
            
            Section(footer: Text("If you restrict access, staff members will only be able to login from these IP addresses.")) {
                EmptyView()
            }
        }
        .navigationTitle("Security Settings")
        .onAppear(perform: loadData)
    }
    
    private func loadData() {
        // Fetch current IP via external service or backend helper
        // Fetch user's allowed IPs
        // Mocking for now as backend endpoint isn't fully ready for "my-ip"
        self.currentIP = "192.168.1.105" // Mock
        self.allowedIPs = ["88.241.12.34"] // Mock
    }
    
    private func authorizeCurrentIP() {
        withAnimation {
            allowedIPs.append(currentIP)
        }
        saveSettings()
    }
    
    private func deleteIP(at offsets: IndexSet) {
        withAnimation {
            allowedIPs.remove(atOffsets: offsets)
        }
        saveSettings()
    }
    
    private func saveSettings() {
        // Call APIService.updateUser(allowedIPs: allowedIPs)
    }
}

struct SecuritySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SecuritySettingsView()
        }
    }
}
