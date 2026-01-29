import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.gray)
                Text(text)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
    }
}
