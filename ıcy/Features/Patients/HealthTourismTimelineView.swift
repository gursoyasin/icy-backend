import SwiftUI

struct HealthTourismTimelineView: View {
    @State private var items: [TimelineItem] = []
    
    struct TimelineItem: Identifiable {
        let id = UUID()
        let type: ItemType
        let time: Date
        
        enum ItemType {
            case flight
            case transfer(Transfer)
            case hotel(Accommodation)
            case operation
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(items) { item in
                    HStack(alignment: .top) {
                        // Time Column
                        VStack {
                            Text(formatTime(item.time))
                                .font(.caption)
                                .bold()
                            Text(formatDate(item.time))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60)
                        
                        // Line & Dot
                        VStack(spacing: 0) {
                            Circle()
                                .fill(colorForItem(item.type))
                                .frame(width: 12, height: 12)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                        
                        // Content Card
                        VStack(alignment: .leading) {
                            contentForItem(item)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Journey Timeline")
        .onAppear(perform: loadTimeline)
    }
    
    func loadTimeline() {
        // Mock Data
        let now = Date()
        items = [
            TimelineItem(type: .transfer(Transfer(id: "1", pickupTime: now.addingTimeInterval(3600), pickupLocation: "IST Airport", dropoffLocation: "Hilton Bomonti", driverName: "Ahmet Y.", plateNumber: "34 ABC 123", status: "scheduled")), time: now.addingTimeInterval(3600)),
            TimelineItem(type: .hotel(Accommodation(id: "2", hotelName: "Hilton Bomonti", checkInDate: now.addingTimeInterval(7200), checkOutDate: now.addingTimeInterval(86400*3), roomType: "Create Suite", status: "booked")), time: now.addingTimeInterval(7200)),
            TimelineItem(type: .operation, time: now.addingTimeInterval(86400)), // Next day operation
            TimelineItem(type: .transfer(Transfer(id: "3", pickupTime: now.addingTimeInterval(86400*3 + 3600), pickupLocation: "Hilton Bomonti", dropoffLocation: "IST Airport", driverName: "Mehmet K.", plateNumber: "34 XYZ 789", status: "scheduled")), time: now.addingTimeInterval(86400*3 + 3600))
        ]
        .sorted(by: { $0.time < $1.time })
    }
    
    func contentForItem(_ item: TimelineItem) -> some View {
        switch item.type {
        case .flight:
            return AnyView(Text("Flight Arrival"))
        case .transfer(let t):
            return AnyView(
                VStack(alignment: .leading) {
                    Label("VIP Transfer", systemImage: "car.fill")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("\(t.pickupLocation) → \(t.dropoffLocation)")
                    if let driver = t.driverName {
                        Text("Driver: \(driver) (\(t.plateNumber ?? ""))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            )
        case .hotel(let h):
            return AnyView(
                VStack(alignment: .leading) {
                    Label("Hotel Check-in", systemImage: "bed.double.fill")
                        .font(.headline)
                        .foregroundColor(.purple)
                    Text(h.hotelName)
                    Text("\(h.roomType ?? "Standard Room")")
                        .font(.caption)
                }
            )
        case .operation:
            return AnyView(
                VStack(alignment: .leading) {
                    Label("Operation", systemImage: "cross.case.fill")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text("Hair Transplant Surgery")
                    Text("Clinic Main Hall")
                        .font(.caption)
                }
            )
        }
    }
    
    func colorForItem(_ type: TimelineItem.ItemType) -> Color {
        switch type {
        case .transfer: return .blue
        case .hotel: return .purple
        case .operation: return .red
        default: return .gray
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
    
    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

struct HealthTourismTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HealthTourismTimelineView()
        }
    }
}
