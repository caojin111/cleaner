//
//  OnboardingPage3View.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog

struct OnboardingPage3View: View {
    @Binding var currentPage: Int
    @State private var animatePhotos = false
    @State private var showAnalysisAnimation = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 图片回顾动画
            ZStack {
                // 背景圆圈
                Circle()
                    .fill(Color.seniorPrimary.opacity(0.1))
                    .frame(width: 220, height: 220)
                
                // 图片网格动画
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        PhotoPlaceholder(delay: 0.1)
                        PhotoPlaceholder(delay: 0.2)
                        PhotoPlaceholder(delay: 0.3)
                    }
                    HStack(spacing: 8) {
                        PhotoPlaceholder(delay: 0.4)
                        PhotoPlaceholder(delay: 0.5)
                        PhotoPlaceholder(delay: 0.6)
                    }
                    HStack(spacing: 8) {
                        PhotoPlaceholder(delay: 0.7)
                        PhotoPlaceholder(delay: 0.8)
                        PhotoPlaceholder(delay: 0.9)
                    }
                }
                .scaleEffect(animatePhotos ? 1.0 : 0.8)
                .opacity(animatePhotos ? 1.0 : 0.3)
                
                // 分析指示器
                if showAnalysisAnimation {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.seniorPrimary)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                                .shadow(color: .gray.opacity(0.3), radius: 8)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            // 文字内容
            VStack(spacing: 20) {
                Text(Constants.Onboarding.page3Title)
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                    .multilineTextAlignment(.center)
                
                Text(Constants.Onboarding.page3Subtitle)
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // 功能特点
                VStack(alignment: .leading, spacing: 12) {
                    FeatureItem(icon: "🔍", text: "智能识别相似图片")
                    FeatureItem(icon: "📊", text: "分析存储空间占用")
                    FeatureItem(icon: "🏆", text: "找出最值得保留的照片")
                    FeatureItem(icon: "🗂️", text: "按时间和类型整理")
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // 继续按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
                Logger.logPageNavigation(from: "Onboarding-3", to: "Onboarding-4")
            }) {
                HStack {
                    Text("查看我的照片")
                        .font(.seniorBody)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.body)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: Constants.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .fill(Color.seniorPrimary)
                )
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // 图片动画
        withAnimation(.easeInOut(duration: 0.8)) {
            animatePhotos = true
        }
        
        // 分析指示器动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showAnalysisAnimation = true
            }
            
            // 循环动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showAnalysisAnimation = false
                }
            }
        }
    }
}

// MARK: - Photo Placeholder Component

struct PhotoPlaceholder: View {
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundColor(.white)
            )
            .opacity(isVisible ? 1.0 : 0.3)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Feature Item Component

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            Text(text)
                .font(.seniorBody)
                .foregroundColor(.seniorText)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingPage3View(currentPage: .constant(2))
} 