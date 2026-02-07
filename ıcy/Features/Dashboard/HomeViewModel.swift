import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var stats: DashboardStats = .empty
    @Published var notifications: [AppNotification] = []
    @Published var todayAppointments: [Appointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Ensure user profile is loaded
            if apiService.currentUser == nil {
                let user = try await apiService.fetchProfile()
                apiService.updateCurrentUser(user)
            }
            
            // Parallel fetching could be used here, but keeping sequential for safety first
            stats = try await apiService.fetchStats()
            notifications = try await apiService.fetchNotifications()
            let allApps = try await apiService.fetchAppointments()
            
            self.todayAppointments = allApps.filter { Calendar.current.isDateInToday($0.date) }
            
        } catch {
            errorMessage = error.localizedDescription
            print("Dashboard Error: \(error)")
        }
        
        isLoading = false
    }
    
    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Günaydın" }
        if hour < 18 { return "Tünaydın" }
        return "İyi Akşamlar"
    }
    
    var currentUser: User? {
        return apiService.currentUser
    }
}
