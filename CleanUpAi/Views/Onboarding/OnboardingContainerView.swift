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
            Color.seniorBackground.ignoresSafeArea()
            
            VStack {
                // 进度指示器
                HStack {
                    Spacer()
                    
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index <= currentPage ? Color.seniorPrimary : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
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
            PaywallView()
        }
        .onAppear {
            Logger.logPageNavigation(from: "Splash", to: "Onboarding")
        }
    }
}

#Preview {
    OnboardingContainerView()
} 