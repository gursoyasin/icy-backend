import SwiftUI

struct AddSupportTicketView: View {
    @Binding var isPresented: Bool
    @State private var subject = ""
    @State private var message = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Konu")) {
                    TextField("Örn: Hata Bildirimi veya Öneri", text: $subject)
                }
                
                Section(header: Text("Mesajınız")) {
                    TextEditor(text: $message)
                        .frame(height: 150)
                }
                
                Section {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Talebi Gönder") {
                            submit()
                        }
                        .disabled(subject.isEmpty || message.isEmpty)
                    }
                }
            }
            .navigationTitle("Destek Talebi")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { isPresented = false }
                }
            }
        }
    }
    
    func submit() {
        isLoading = true
        Task {
            do {
                _ = try await APIService.shared.createSupportTicket(subject: subject, message: message)
                isLoading = false
                isPresented = false
            } catch {
                print("Ticket error: \(error)")
                isLoading = false
            }
        }
    }
}
