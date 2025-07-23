//
//  OnboardingContainerView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog

struct OnboardingContainerView: View {
    @State private var currentPage = 0
    @State private var showPaywall = false
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var photoAnalyzer = PhotoAnalyzer.shared
    
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 1, blue: 0.96).ignoresSafeArea()
            
            VStack {
                // 进度指示器
                HStack {
                    Spacer()
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index <= currentPage ? Color(red: 0.66, green: 1, blue: 0.81) : Color.white.opacity(0.18))
                            .frame(width: 12, height: 12)
                            .animation(.easeInOut, value: currentPage)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // 页面内容
                TabView(selection: $currentPage) {
                    OnboardingPage1View(currentPage: $currentPage)
                        .tag(0)
                    OnboardingPage2View(currentPage: $currentPage)
                        .tag(1)
                    OnboardingPage3View(currentPage: $currentPage)
                        .tag(2)
                    OnboardingPage4View(
                        currentPage: $currentPage,
                        showPaywall: $showPaywall
                    )
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isFromOnboarding: true)
        }
        .onAppear {
            Logger.logPageNavigation(from: "Splash", to: "Onboarding")
        }
    }
}

#Preview {
    OnboardingContainerView()
} 