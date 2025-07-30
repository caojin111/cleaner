//
//  SplashView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog

struct SplashView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 1.0
    @State private var logoOpacity: Double = 1.0
    @State private var dotPulse: Bool = false
    @StateObject private var userSettings = UserSettingsManager.shared
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                // LOGO
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 420, height: 210)
                    .opacity(logoOpacity)
                        .scaleEffect(logoScale)
                // 绿色动效点缀
                HStack(spacing: 8) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(Color.seniorPrimary)
                            .frame(width: dotPulse && i == 2 ? 18 : 10, height: dotPulse && i == 2 ? 18 : 10)
                            .opacity(dotPulse && i == 2 ? 1.0 : 0.7)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: dotPulse)
                }
                }
                .padding(.vertical, 18)
                Spacer()
                // 底部开发者和版本号
                VStack(spacing: 6) {
                    Text("app.developer".localized)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(Color.seniorPrimary)
                    Text("app.version".localized)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(Color.gray)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startAnimations()
        }
        .fullScreenCover(isPresented: $isActive) {
            if userSettings.isFirstLaunch {
                OnboardingContainerView()
            } else {
                MainTabView()
            }
        }
    }
    
    private func startAnimations() {
        Logger.logAppLaunch()
        withAnimation(.easeInOut(duration: 0.8)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }
        // 绿色点缀动效
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dotPulse = true
        }
        // 页面自动跳转延时
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.splashDuration) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isActive = true
            }
            let destination = userSettings.isFirstLaunch ? "Onboarding" : "MainApp"
            Logger.logPageNavigation(from: "Splash", to: destination)
        }
    }
}

#Preview {
    SplashView()
} 