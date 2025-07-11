//
//  OnboardingPage4View.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog

struct OnboardingPage4View: View {
    @Binding var currentPage: Int
    @Binding var showPaywall: Bool
    @StateObject private var photoAnalyzer = PhotoAnalyzer.shared
    @State private var photoCount: Int = 0
    @State private var isAnalyzing = false
    @State private var animateNumbers = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 统计数字动画
            ZStack {
                // 背景圆圈
                Circle()
                    .fill(Color.seniorPrimary.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 16) {
                    // 照片数量
                    Text("\(animateNumbers ? photoCount : 0)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.seniorPrimary)
                        .contentTransition(.numericText())
                    
                    Text("张照片")
                        .font(.seniorTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.seniorText)
                    
                    if isAnalyzing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .seniorPrimary))
                            .scaleEffect(0.8)
                    }
                }
            }
            
            // 文字内容
            VStack(spacing: 20) {
                Text(String(format: Constants.Onboarding.page4Title, photoCount))
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                    .multilineTextAlignment(.center)
                
                Text(Constants.Onboarding.page4Subtitle)
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // 预期收益
                if photoCount > 0 {
                    VStack(spacing: 12) {
                        StatRow(
                            icon: "🗂️",
                            title: "预计重复照片",
                            value: "\(photoCount / 10)张",
                            color: .orange
                        )
                        
                        StatRow(
                            icon: "💾",
                            title: "预计节省空间",
                            value: "\(ByteCountFormatter.string(fromByteCount: Int64(photoCount * 2048), countStyle: .file))",
                            color: .green
                        )
                        
                        StatRow(
                            icon: "⚡",
                            title: "性能提升",
                            value: "显著改善",
                            color: .blue
                        )
                    }
                    .padding(.horizontal, 30)
                }
            }
            
            Spacer()
            
            // 开始按钮
            Button(action: {
                Logger.logPageNavigation(from: "Onboarding-4", to: "Paywall")
                showPaywall = true
            }) {
                HStack {
                    Text("开始清理")
                        .font(.seniorBody)
                        .fontWeight(.bold)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: Constants.buttonHeight + 10)
                .background(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.seniorPrimary,
                                    Color.seniorPrimary.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.seniorPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .onAppear {
            startPhotoAnalysis()
        }
    }
    
    private func startPhotoAnalysis() {
        isAnalyzing = true
        
        Task {
            let count = await photoAnalyzer.getPhotoCount()
            
            await MainActor.run {
                photoCount = count
                isAnalyzing = false
                
                // 数字动画
                withAnimation(.easeInOut(duration: 1.0)) {
                    animateNumbers = true
                }
                
                Logger.analytics.info("用户照片总数: \(count)")
            }
        }
    }
}

// MARK: - Stat Row Component

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.seniorCaption)
                    .foregroundColor(.seniorSecondary)
                
                Text(value)
                    .font(.seniorBody)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .gray.opacity(0.1), radius: 2)
        )
    }
}

#Preview {
    OnboardingPage4View(
        currentPage: .constant(3),
        showPaywall: .constant(false)
    )
} 