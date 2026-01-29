
import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = APIService.shared.authToken != nil
    
    var body: some View {
        if isLoggedIn {
            DashboardView(isLoggedIn: $isLoggedIn)
        } else {
            LoginView(isLoggedIn: $isLoggedIn)
        }
    }
}

#Preview {
    ContentView()
}

