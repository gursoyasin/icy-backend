import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
            EmptyView()
        } else {
            ZStack {
                Color.neoBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Logo or Icon
                    Image(systemName: "cross.case.fill") // Placeholder for Clinic Logo
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("ICY CLINIC")
                        .font(.custom("AvenirNext-Bold", size: 32))
                        .foregroundColor(.primary)
                    
                    Text("Powered by Estesoft Neo")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
