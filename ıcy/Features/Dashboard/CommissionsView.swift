import SwiftUI

struct CommissionsView: View {
    @State private var performance: StaffPerformance?
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Yükleniyor...")
            } else if let perf = performance {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Card
                        VStack(spacing: 10) {
                            Text(perf.month)
                                .font(.neoHeadline)
                                .foregroundColor(.neoTextSecondary)
                            Text("\(String(format: "%.2f", perf.commissionEarned)) ₺")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.neoPrimary)
                            Text("Toplam Hakediş")
                                .font(.neoCaption)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                        
                        // Details Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            StatCard(title: "Hedef", value: "\(String(format: "%.0f", perf.targetAmount)) ₺", icon: "target")
                            StatCard(title: "Gerçekleşen", value: "\(String(format: "%.0f", perf.actualAmount)) ₺", icon: "chart.bar.fill")
                            StatCard(title: "Tamamlanma", value: "%\(String(format: "%.1f", (perf.actualAmount / perf.targetAmount) * 100))", icon: "percent")
                            StatCard(title: "Prim Oranı", value: "%10", icon: "arrow.up.right.circle.fill") // Mock rate
                        }
                        
                        // Info Note
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Prim hesaplamaları fatura ödemesi alındıktan sonra otomatik yansıtılır.")
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                        .padding()
                        
                        Spacer()
                    }
                    .padding()
                }
            } else {
                Text("Veri bulunamadı")
            }
        }
        .navigationTitle("Prim & Performans")
        .background(Color.neoBackground)
        .onAppear(perform: fetchPerformance)
    }
    
    func fetchPerformance() {
        // Mock Data Fetch - In real app, call endpoint /api/finance/performance/me
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.performance = StaffPerformance(
                id: "1",
                userId: "user1",
                month: "2024-02",
                targetAmount: 100000,
                actualAmount: 125000,
                commissionEarned: 12500
            )
            self.isLoading = false
        }
    }
}

// Simple Model just for View
struct StaffPerformance: Identifiable {
    let id: String
    let userId: String
    let month: String
    let targetAmount: Double
    let actualAmount: Double
    let commissionEarned: Double
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.neoPrimary)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }
}
