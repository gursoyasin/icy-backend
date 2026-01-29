import SwiftUI

// MARK: - Colors
extension Color {
    // Primary Brand Colors
    static let neoPrimary = Color(hex: "0F2027") // Premium Dark
    static let neoSecondary = Color(hex: "203A43") // Deep Teal
    static let neoAccent = Color(hex: "2C5364") // Muted Blue Gray
    
    // Gradients
    static let neoGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Backgrounds
    static let neoBackground = Color(hex: "F2F2F2") // Crisp Gray
    static let neoCardBackground = Color.white
    
    // Text
    static let neoTextPrimary = Color(hex: "121212")
    static let neoTextSecondary = Color(hex: "555555")
    
    // Success/Warning
    static let neoSuccess = Color(hex: "27AE60")
    static let neoWarning = Color(hex: "D35400")
    static let neoError = Color(hex: "C0392B")
}

// MARK: - Typography
extension Font {
    static let neoLargeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let neoTitle = Font.system(size: 24, weight: .bold, design: .default)
    static let neoHeadline = Font.system(size: 18, weight: .semibold, design: .default)
    static let neoBody = Font.system(size: 16, weight: .regular, design: .default)
    static let neoCaption = Font.system(size: 12, weight: .medium, design: .default)
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.neoHeadline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.neoPrimary)
            .cornerRadius(12)
            .shadow(color: Color.neoPrimary.opacity(0.3), radius: 5, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Helpers
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
