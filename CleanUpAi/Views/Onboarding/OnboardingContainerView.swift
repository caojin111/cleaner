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
    @State private var isAnalysisComplete = false
    @State private var photoCount: Int = 0
    @State private var actualDuplicates: Int = 0
    @State private var isAnalyzing = false
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
                        OnboardingPage3View_New(currentPage: $currentPage, onPrepareAnalysis: preparePhotoAnalysis)
                    case 3:
                        OnboardingTransitionView_New(currentPage: $currentPage)
                    case 4:
                        OnboardingPage4View(
                            currentPage: $currentPage,
                            showPaywall: $showPaywall,
                            initialPhotoCount: photoCount,
                            initialDuplicates: actualDuplicates,
                            isAnalysisComplete: isAnalysisComplete
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
        .onChange(of: currentPage) { newValue in
            if newValue == 4 && !isAnalysisComplete {
                // 当跳转到Page4时，如果分析还未完成，开始分析
                startPhotoAnalysis()
            }
        }
    }

    private func startPhotoAnalysis() {
        guard !isAnalyzing else { return }

        isAnalyzing = true
        Logger.analytics.info("开始预先分析照片数据")

        Task {
            // 获取照片总数
            let count = await photoAnalyzer.getPhotoCount()

            // 执行实际分析以获取真实的重复数量
            await photoAnalyzer.startAnalysis()
            let actualDuplicatesCount = photoAnalyzer.foundDuplicates.count

            await MainActor.run {
                photoCount = count
                actualDuplicates = actualDuplicatesCount
                isAnalyzing = false
                isAnalysisComplete = true

                Logger.analytics.info("预先分析完成: 照片总数=\(count), 实际重复数=\(actualDuplicatesCount)")
            }
        }
    }

    // 供Page3调用的函数，在跳转前开始分析
    func preparePhotoAnalysis() {
        if !isAnalysisComplete {
            startPhotoAnalysis()
        }
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(PermissionManager.shared)
        .environmentObject(PhotoAnalyzer.shared)
} 