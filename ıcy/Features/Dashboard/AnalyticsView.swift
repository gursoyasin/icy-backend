import SwiftUI

struct AnalyticsView: View {
    @State private var analyticsData: AnalyticsData?
    @State private var animateCharts = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(alignment: .leading, spacing: 5) {
                    Text("Klinik Analizi")
                        .font(.neoLargeTitle)
                    Text("Son 7 günlük verileriniz")
                        .font(.neoBody)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                if let data = analyticsData {
                    // 1. Revenue Chart
                    VStack(alignment: .leading) {
                        Text("Gelir Akışı (₺)")
                            .font(.neoHeadline)
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(data.revenue) { point in
                                ChartBar(
                                    label: point.day, 
                                    value: CGFloat(point.amount) / (data.revenue.map{$0.amount}.max() ?? 1.0), 
                                    color: .neoPrimary,
                                    animate: animateCharts
                                )
                            }
                        }
                        .frame(height: 200)
                        .padding(.top)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.03), radius: 10)
                    .padding(.horizontal)
                    
                    // 2. Efficiency Stats (Grid)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        MiniStatBox(title: "Dönüşüm", value: "%\(data.conversionRate)", icon: "arrow.triangle.2.circlepath", color: .blue)
                        MiniStatBox(title: "Ort. Greft", value: "\(data.avgGraft)", icon: "star.fill", color: .neoPrimary)
                        MiniStatBox(title: "Gelmemezlik", value: "%\(data.noShowRate ?? 0)", icon: "xmark.circle.fill", color: .red)
                        MiniStatBox(title: "Hasta Memnuniyeti", value: "4.9", icon: "heart.fill", color: .neoAccent)
                    }
                    .padding(.horizontal)

                    // 3. Doctor Workload (New)
                    if let workload = data.doctorWorkload, !workload.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Doktor Performansı (30 Gün)")
                                .font(.neoHeadline)
                            
                            VStack(spacing: 15) {
                                ForEach(workload) { doc in
                                    HStack {
                                        Circle().fill(Color.neoSecondary.opacity(0.2)).frame(width: 40, height: 40)
                                            .overlay(Image(systemName: "stethoscope").foregroundColor(.neoSecondary))
                                        
                                        Text(doc.name)
                                            .font(.neoBody).bold()
                                        
                                        Spacer()
                                        
                                        Text("\(doc.count) Randevu")
                                            .font(.caption)
                                            .padding(6)
                                            .background(Color.neoSecondary.opacity(0.1))
                                            .foregroundColor(.neoSecondary)
                                            .cornerRadius(6)
                                    }
                                    Divider()
                                }
                            }
                            .padding(.top)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.03), radius: 10)
                        .padding(.horizontal)
                    }
                    
                    // 4. Acquisition Source
                    VStack(alignment: .leading) {
                        Text("Hasta Kaynakları")
                            .font(.neoHeadline)
                        
                        let total = data.sources.reduce(0) { $0 + $1.count }
                        VStack(spacing: 12) {
                            ForEach(data.sources) { source in
                                SourceRow(label: source.label, count: source.count, total: total, color: .purple, animate: animateCharts)
                            }
                        }
                        .padding(.top)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.03), radius: 10)
                    .padding(.horizontal)
                    
                } else {
                    ProgressView("Veriler analiz ediliyor...")
                        .padding(.top, 50)
                }
                
                Spacer(minLength: 50)
            }
        }
        .background(Color.neoBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("Analiz")
        .task {
            do {
                analyticsData = try await APIService.shared.fetchAnalytics()
                withAnimation(.easeOut(duration: 0.8)) {
                    animateCharts = true
                }
            } catch {
                print("Analytics error: \(error)")
            }
        }
    }
}

struct ChartBar: View {
    let label: String
    let value: CGFloat
    let color: Color
    var animate: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(gradient: Gradient(colors: [color, color.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
                .frame(height: animate ? 150 * value : 0) // Animation logic
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double.random(in: 0...0.2)), value: animate)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}

struct SourceRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    var animate: Bool = false
    
    var body: some View {
        let percent = total > 0 ? (Double(count) / Double(total)) * 100 : 0
        
        return HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundColor(.neoTextPrimary)
            Spacer()
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.1)).frame(width: 120, height: 8)
                Capsule().fill(color).frame(width: animate ? 1.2 * CGFloat(percent) : 0, height: 8)
                    .animation(.easeOut(duration: 1.0), value: animate)
            }
            Text("%\(Int(percent))").font(.caption).bold().frame(width: 35)
        }
    }
}

struct MiniStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(.neoTextPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
    }
}
