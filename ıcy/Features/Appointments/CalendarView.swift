import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var appointments: [Appointment] = []
    @State private var showingAddSheet = false
    @State private var errorMessage: String? = nil
    
    var filteredAppointments: [Appointment] {
        appointments.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neoBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Custom Horizontal Week Strip
                    VStack(spacing: 15) {
                        // Month Header
                        HStack {
                            Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                                .font(.title2) // Replaced custom font
                                .foregroundColor(.primary) // Replaced custom color
                            Spacer()
                            // Today Button
                            Button("Bugün") {
                                withAnimation { selectedDate = Date() }
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.neoPrimary.opacity(0.1))
                            .foregroundColor(.neoPrimary)
                            .cornerRadius(20)
                        }
                        .padding(.horizontal)
                        
                        // Week Scroll
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(weekDates(), id: \.self) { date in
                                    DateCapsule(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)) {
                                        withAnimation { selectedDate = date }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Color.white)
                    .cornerRadius(24, corners: [.bottomLeft, .bottomRight])
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                    
                    // Timeline
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Ajanda")
                                .font(.headline) // Replaced custom font
                            Spacer()
                            Text("\(filteredAppointments.count) Randevu")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        ScrollView {
                            if filteredAppointments.isEmpty {
                                VStack(spacing: 15) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 40))
                                        .foregroundColor(.neoSecondary.opacity(0.5))
                                    Text("Bu güne planlanmış randevu yok.")
                                        .font(.body) // Replaced custom font
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(filteredAppointments.enumerated()), id: \.element.id) { index, appointment in
                                        TimelineCard(appointment: appointment, isLast: index == filteredAppointments.count - 1, refreshAction: {
                                            Task {
                                                appointments = try await APIService.shared.fetchAppointments()
                                            }
                                        })
                                            .swipeActions {
                                                if appointment.status != .cancelled {
                                                    Button("İptal Et") {
                                                        Task {
                                                            try? await APIService.shared.cancelAppointment(id: appointment.id)
                                                            // Refresh list
                                                            appointments = try await APIService.shared.fetchAppointments()
                                                        }
                                                    }
                                                    .tint(.red)
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .background(Color.neoBackground)
                }
            }
            .navigationTitle("Takvim")
            .background(Color.neoBackground.edgesIgnoringSafeArea(.all))
            .toolbar {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.neoPrimary)
                }
            }
            .sheet(isPresented: $showingAddSheet, onDismiss: {
                Task {
                    do {
                        errorMessage = nil
                        appointments = try await APIService.shared.fetchAppointments()
                    } catch {
                        print("Error: \(error)")
                        errorMessage = String(describing: error)
                    }
                }
            }) {
                AddAppointmentView()
            }
            .task {
                do {
                    appointments = try await APIService.shared.fetchAppointments()
                } catch { 
                    print("Error: \(error)")
                    appointments = [] 
                }
            }
        }
    }
    
    // Helper function moved to struct level
    func weekDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []
        for i in -3...10 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(date)
            }
        }
        return dates
    }
}

struct TimelineCard: View {
    let appointment: Appointment
    let isLast: Bool
    var refreshAction: () -> Void = {}
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Time Column
            VStack(alignment: .trailing) {
                Text(appointment.date, style: .time)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.neoPrimary)
            }
            .frame(width: 50)
            .padding(.top, 4)
            
            // Timeline Line
            VStack(spacing: 0) {
                Circle()
                    .fill(statusColor(for: appointment.status))
                    .frame(width: 12, height: 12)
                    .background(Circle().stroke(Color.white, lineWidth: 2))
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, -4)
                }
            }
            .padding(.top, 6)
            
            // Card Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(appointment.patientName)
                        .font(.headline) // Replaced custom font
                }
                
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Text(appointment.type)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(appointment.status.title)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: appointment.status).opacity(0.1))
                    .foregroundColor(statusColor(for: appointment.status))
                    .cornerRadius(4)
                
                // Status Actions
                if appointment.status == .scheduled {
                    HStack {
                        Button("Geldi") {
                            updateStatus("arrived")
                        }
                        .font(.caption)
                        .padding(6)
                        .background(Color.neoSuccess.opacity(0.1))
                        .foregroundColor(.neoSuccess)
                        .cornerRadius(6)
                        
                        Button("Gelmedi") {
                            updateStatus("no-show")
                        }
                        .font(.caption)
                        .padding(6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.bottom, 20)
        }
    }
    
    func statusColor(for status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled: return .neoPrimary
        case .completed: return .neoSuccess
        case .cancelled: return .red
        case .noShow: return .gray
        case .active: return .neoAccent
        case .arrived: return .neoSuccess
        }
    }
    
    func updateStatus(_ status: String) {
        Task {
            try? await APIService.shared.updateAppointmentStatus(id: appointment.id, status: status)
            refreshAction()
        }
    }
}

struct DateCapsule: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .gray)
                
                Text(date.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary) // Replaced custom color
            }
            .frame(width: 50, height: 70)
            .background(isSelected ? Color.neoPrimary : Color.neoBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: isSelected ? 0 : 1)
            )
            .shadow(color: isSelected ? Color.neoPrimary.opacity(0.3) : .clear, radius: 5, y: 3)
        }
    }
}



struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
