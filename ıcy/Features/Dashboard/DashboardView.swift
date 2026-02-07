import SwiftUI

struct DashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Özet")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Takvim")
                }
                .tag(1)
            
            PatientListView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Hastalar")
                }
                .tag(2)
            
            if (APIService.shared.currentUser?.role ?? .staff) == .admin {
                CampaignView()
                    .tabItem {
                        Image(systemName: "megaphone.fill")
                        Text("Pazarlama")
                    }
                    .tag(3)
            }
                
            MessagesView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Mesajlar")
                }
                .tag(4)
                
            SettingsView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Ayarlar")
                }
                .tag(5)
        }
        .accentColor(.neoPrimary)
    }
}

// MARK: - Redesigned Pro Dashboard
// MARK: - Ultra Premium Dashboard
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showContent = false
    @State private var showAddAppointment = false
    @State private var showAddPatient = false
    @State private var showScanner = false
    
    // Grid: 2 Columns
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 1. Premium Background
                LinearGradient(gradient: Gradient(colors: [Color.neoBackground, Color.white]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                // decorative circles
                GeometryReader { geo in
                    Circle()
                        .fill(LinearGradient(colors: [.neoPrimary.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: geo.size.width * 0.8)
                        .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.2)
                }
                
                if showContent {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {
                            headerSection
                            actionRow
                            statsGrid
                            todaysAgenda
                            Spacer(minLength: 80)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Floating Action Button for AI
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink(destination: NeoAssistantView()) {
                            Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(LinearGradient(colors: [.neoPrimary, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .shadow(color: .purple.opacity(0.4), radius: 10, y: 5)
                            )
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddAppointment) { AddAppointmentView() }
            .sheet(isPresented: $showAddPatient) { AddPatientView() }
            .alert("Tarayıcı", isPresented: $showScanner) {
                Button("Tamam", role: .cancel) { }
            } message: { Text("QR/Barkod tarayıcı özelliği yakında eklenecek.") }
            .task { await viewModel.loadData() }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    showContent = true
                }
                // Pre-load if needed, but .task handles it
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date(), style: .date)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundColor(.gray)
                    .tracking(2)
                
                Text(viewModel.greetingMessage)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.neoTextPrimary)
                
                Text(viewModel.currentUser?.branch?.name ?? "Merkez Klinik")
                    .font(.subheadline)
                    .foregroundColor(.neoSecondary)
            }
            
            Spacer()
            
            // Profile Image with Ring
            ZStack {
                Circle()
                    .stroke(LinearGradient(colors: [.neoPrimary, .neoSecondary], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                    .frame(width: 54, height: 54)
                
                Text(String(viewModel.currentUser?.name.prefix(1) ?? "U"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.neoPrimary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // Clean, Text-less action buttons for minimalism
    private var actionRow: some View {
        HStack(spacing: 20) {
            QuickActionIcon(icon: "calendar.badge.plus", color: .neoPrimary) {
                showAddAppointment = true
            }
            QuickActionIcon(icon: "person.badge.plus", color: .neoSecondary) {
                showAddPatient = true
            }
            QuickActionIcon(icon: "doc.text.viewfinder", color: .orange) {
                showScanner = true
            }
            // Admin only report button
            if (viewModel.currentUser?.role ?? .staff) == .admin {
                NavigationLink(destination: AnalyticsView()) {
                   ZStack {
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                        
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                    }
                    .frame(width: 60, height: 60)
                }
            } else {
                 // Placeholder for non-admins to keep alignment or remove
                 QuickActionIcon(icon: "chart.pie.fill", color: .purple) { }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            PremiumStatCard(
                title: "Randevular",
                value: "\(viewModel.stats.upcomingAppointments)",
                subtitle: "Bekleyen",
                icon: "calendar",
                color: .neoPrimary
            )
            
            PremiumStatCard(
                title: "Hastalar",
                value: "\(viewModel.stats.totalPatients)",
                subtitle: "Toplam Kayıt",
                icon: "person.2.fill",
                color: .neoSecondary
            )
            
            if (viewModel.currentUser?.role ?? .staff) == .admin {
                PremiumStatCard(
                    title: "Gelir",
                    value: "₺\(Int(viewModel.stats.monthlyRevenue))",
                    subtitle: "Bu Ay",
                    icon: "creditcard.fill",
                    color: .neoSuccess
                )
                
                PremiumStatCard(
                    title: "Büyüme",
                    value: "%\(viewModel.stats.trends?.revenue ?? 0)",
                    subtitle: "Geçen Aya Göre",
                    icon: "arrow.up.right",
                    color: .green
                )
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var todaysAgenda: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Bugünün Ajandası")
                    .font(.headline)
                    .foregroundColor(.neoTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if viewModel.todayAppointments.isEmpty {
                        Text("Bugün planlanmış randevu yok.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading, 24)
                    } else {
                        ForEach(viewModel.todayAppointments) { app in
                            AgendaCard(appointment: app)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    

}

// MARK: - Premium Components

struct QuickActionIcon: View {
    let icon: String
    let color: Color
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            .frame(width: 60, height: 60)
        }
    }
}

struct PremiumStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Spacer()
                // Subtle shine effect
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.neoTextPrimary)
                .minimumScaleFactor(0.8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Glassmorphism
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white, lineWidth: 1)
        )
    }
}

struct AgendaCard: View {
    let appointment: Appointment
    
    var body: some View {
        HStack(spacing: 16) {
            // Time Strip
            VStack {
                Text(appointment.date, style: .time)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 50)
            .padding(.vertical, 8)
            .background(Color.neoPrimary)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.patientName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.neoTextPrimary)
                Text(appointment.type)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if appointment.status == .active {
                Text("AKTİF")
                    .font(.system(size: 8, weight: .bold))
                    .padding(4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .frame(width: 280)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 5, y: 5)
    }
}
