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
    
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                // 进度指示器 (过渡页不显示单独的进度点)
                if currentPage != 3 { // 过渡页不显示进度点
                    HStack {
                        Spacer()
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index <= min(currentPage, 3) ? Color.seniorPrimary : Color.white.opacity(0.18))
                                .frame(width: 12, height: 12)
                                .animation(.easeInOut, value: currentPage)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // 页面内容
                Group {
                    switch currentPage {
                    case 0:
                        OnboardingPage1View(currentPage: $currentPage)
                    case 1:
                        OnboardingPage2View(currentPage: $currentPage)
                    case 2:
                        OnboardingPage3View_New(currentPage: $currentPage)
                    case 3:
                        OnboardingTransitionView_New(currentPage: $currentPage)
                    case 4:
                        OnboardingPage4View(
                            currentPage: $currentPage,
                            showPaywall: $showPaywall
                        )
                    default:
                        OnboardingPage1View(currentPage: $currentPage)
                    }
                }
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