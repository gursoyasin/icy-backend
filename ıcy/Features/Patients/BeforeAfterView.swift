import SwiftUI

struct BeforeAfterView: View {
    let beforeImage: Image
    let afterImage: Image
    
    @State private var sliderPosition: CGFloat = 0.5
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Layer (After Image)
                afterImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // Overlay Layer (Before Image) -- Masked
                beforeImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: geometry.size.width * sliderPosition)
                            Spacer()
                        }
                    )
                
                // Slider Handle
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: geometry.size.width * sliderPosition)
                    
                    // Handle
                    ZStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 4)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                            .shadow(radius: 4)
                        
                        Image(systemName: "chevron.left.chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let location = value.location.x / geometry.size.width
                                sliderPosition = min(max(location, 0), 1)
                            }
                    )
                    
                    Spacer()
                }
            }
            // Labels
            .overlay(
                HStack {
                    Text("Öncesi")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                        .padding()
                    Spacer()
                    Text("Sonrası")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                        .padding()
                },
                alignment: .bottom
            )
            .cornerRadius(16)
            .shadow(radius: 5)
        }
    }
}
