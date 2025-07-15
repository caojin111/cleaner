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
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @StateObject private var userSettings = UserSettingsManager.shared
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.seniorPrimary.opacity(0.8),
                    Color.seniorPrimary
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo
                VStack(spacing: 20) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: Constants.logoSize, weight: .light))
                        .foregroundColor(.white)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // App Name
                    Text(Constants.appName)
                        .font(.seniorLargeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(logoOpacity)
                }
                
                Spacer()
                Spacer()
                
                // Developer Info
                VStack(spacing: 8) {
                    Text(Constants.developerInfo)
                        .font(.seniorCaption)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(logoOpacity)
                    
                    Text("v\(Constants.appVersion)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .opacity(logoOpacity)
                        .onTapGesture(count: 5) {
                            // 连续点击5次版本号重置首次启动状态（仅用于测试）
                            userSettings.resetFirstLaunch()
                            Logger.analytics.info("已重置首次启动状态（测试功能）")
                        }
                }
                .padding(.bottom, 50)
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
        
        // Logo动画
        withAnimation(.easeInOut(duration: 0.8)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }
        
        // 页面跳转延时
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