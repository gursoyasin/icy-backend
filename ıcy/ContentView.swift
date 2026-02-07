
import SwiftUI

struct ContentView: View {
    @ObservedObject var apiService = APIService.shared
    
    var body: some View {
        if apiService.authToken != nil {
            // Binding wrapper for compatibility with existing child views if they need it
            // Ideally refactor child views to use environment object as well
            let binding = Binding<Bool>(
                get: { self.apiService.authToken != nil },
                set: { if !$0 { self.apiService.authToken = nil } }
            )
            DashboardView(isLoggedIn: binding)
        } else {
            let binding = Binding<Bool>(
                get: { self.apiService.authToken != nil },
                set: { _ in } // Login view updates via APIService
            )
            LoginView(isLoggedIn: binding)
        }
    }
}

#Preview {
    ContentView()
}

