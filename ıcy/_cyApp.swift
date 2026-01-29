//
//  _cyApp.swift
//  ıcy
//
//  Created by yacN on 26.01.2026.
//

import SwiftUI

@main
struct _cyApp: App {
    @AppStorage("onboardingCompleted") var onboardingCompleted = false
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(2.0)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    if onboardingCompleted {
                        ContentView()
                            .zIndex(1.0)
                    } else {
                        OnboardingView(isCompleted: $onboardingCompleted)
                            .zIndex(1.0)
                    }
                }
            }
        }
    }
}
