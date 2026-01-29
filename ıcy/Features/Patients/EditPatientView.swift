import SwiftUI

struct EditPatientView: View {
    let patient: Patient
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    
    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var tags: String
    @State private var isLoading = false
    @State private var errorMsg = ""
    @State private var showError = false

    init(patient: Patient, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) {
        self.patient = patient
        self._isPresented = isPresented
        self.onSuccess = onSuccess
        _name = State(initialValue: patient.fullName)
        _email = State(initialValue: patient.email ?? "")
        _phone = State(initialValue: patient.phoneNumber ?? "")
        _tags = State(initialValue: patient.tags ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad Soyad", text: $name)
                    TextField("E-posta", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Telefon", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Etiketler")) {
                    TextField("Etiketler (VIP, Risk, vs.)", text: $tags)
                    Text("Virgül ile ayırarak birden fazla etiket girebilirsiniz.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
            .navigationTitle("Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(name.isEmpty || isLoading)
                }
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Hata"), message: Text(errorMsg), dismissButton: .default(Text("Tamam")))
            }
        }
    }
    
    func save() {
        isLoading = true
        Task {
            do {
                _ = try await APIService.shared.updatePatient(
                    id: patient.id,
                    name: name,
                    email: email,
                    phone: phone,
                    tags: tags // Logic handled in API Service
                )
                isLoading = false
                isPresented = false
                onSuccess()
            } catch {
                isLoading = false
                errorMsg = error.localizedDescription
                showError = true
            }
        }
    }
}
