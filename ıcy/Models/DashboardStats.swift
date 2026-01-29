import Foundation

struct DashboardStats: Codable {
    let totalPatients: Int
    let activePatients: Int
    let upcomingAppointments: Int
    let monthlyRevenue: Double
    let trends: StatsTrends?
    
    // Default for UI
    static let empty = DashboardStats(totalPatients: 0, activePatients: 0, upcomingAppointments: 0, monthlyRevenue: 0.0, trends: nil)
}

struct StatsTrends: Codable {
    let appointments: Int
    let patients: Int
    let revenue: Int
}
