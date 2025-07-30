//
//  OnboardingTransitionView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog

struct OnboardingTransitionView: View {
    @Binding var currentPage: Int
    @State private var progress: CGFloat = 0.0
    @State private var animateText = false
    @State private var animateCircle = false
    @State private var rotateIcon = false
    @State private var progressText = "0%"
    
    private let analysisTime: Double = 5.0
    
    var body: some View {
        VStack(spacing: 48) {
            Spacer()
            
            // AI分析图标
            ZStack {
                // 背景圆圈
                Circle()
                    .fill(Color.seniorPrimary.opacity(0.18))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateCircle ? 1.0 : 0.8)
                    .opacity(animateCircle ? 1.0 : 0.3)
                
                // AI图标
                Text("🤖")
                    .font(.system(size: 48))
                    .scaleEffect(animateText ? 1.0 : 0.8)
                    .rotationEffect(.degrees(rotateIcon ? 360 : 0))
            }
            
            // 文案部分
            VStack(spacing: 24) {
                Text("onboarding.transition.analyzing".localized)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .opacity(animateText ? 1.0 : 0.0)
                
                Text("onboarding.transition.subtitle".localized)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animateText ? 1.0 : 0.0)
            }
            
            // 进度条部分
            VStack(spacing: 16) {
                // 圆形进度条
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(
                            Color.seniorPrimary,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    Text(progressText)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.seniorPrimary)
                }
                
                // 进度文本
                Text("onboarding.transition.progress_text".localized)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.seniorSecondary)
                    .opacity(animateText ? 1.0 : 0.0)
            }
            .opacity(animateText ? 1.0 : 0.0)
            
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            startAnalysis()
            Logger.logPageNavigation(from: "Onboarding-3", to: "AI-Analysis")
        }
    }
    
    private func startAnalysis() {
        // 开始动画
        withAnimation(.easeInOut(duration: 0.6)) {
            animateCircle = true
        }
        
        withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
            animateText = true
        }
        
        // AI图标持续旋转动画
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false).delay(0.5)) {
            rotateIcon = true
        }
        
        // 开始真实的进度条动画（5秒内从0%到100%）
        startProgressAnimation()
        
        // 5秒后跳转到下一页
        DispatchQueue.main.asyncAfter(deadline: .now() + analysisTime + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage += 1
            }
            Logger.logPageNavigation(from: "AI-Analysis", to: "Onboarding-4")
            Logger.analytics.info("AI分析过渡页面完成，耗时: \(analysisTime)秒")
        }
    }
    
    private func startProgressAnimation() {
        let totalSteps = 100
        let stepDuration = analysisTime / Double(totalSteps)
        
        for step in 0...totalSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(step) * stepDuration) {
                let progressValue = CGFloat(step) / CGFloat(totalSteps)
                progress = progressValue
                progressText = "\(step)%"
                
                Logger.analytics.debug("AI分析进度: \(step)%")
            }
        }
    }
}

#Preview {
    OnboardingTransitionView(currentPage: .constant(3))
} 