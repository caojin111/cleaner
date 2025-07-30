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
    @State private var pageVisible = false
    
    var body: some View {
        VStack(spacing: 36) {
            Spacer()
            // 统计展示（简化的动画）
            ZStack {
                Circle()
                    .fill(Color.seniorPrimary.opacity(0.18))
                    .frame(width: 180, height: 180)
                VStack(spacing: 16) {
                    Text(formatNumber(photoCount))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color.seniorPrimary)
                    Text("onboarding.page4.photos_count".localized)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.seniorText)
                }
            }
            .opacity(pageVisible ? 1.0 : 0.0)
            .offset(y: pageVisible ? 0 : 30)
            
            // 文案
            VStack(spacing: 18) {
                Text(String(format: "onboarding.page4.title".localized, photoCount))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Text("onboarding.page4.subtitle".localized)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(.seniorText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                if photoCount > 0 {
                    VStack(spacing: 12) {
                        StatRow(
                            icon: "🟢",
                            title: "onboarding.page4.estimated_duplicates".localized,
                            value: calculateEstimatedDuplicates(),
                            color: .orange
                        )
                        StatRow(
                            icon: "🟢",
                            title: "onboarding.page4.estimated_saving".localized,
                            value: calculateEstimatedSpaceSavings(),
                            color: .green
                        )
                        StatRow(
                            icon: "🟢",
                            title: "onboarding.page4.performance_boost".localized,
                            value: "onboarding.page4.significant_improvement".localized,
                            color: .blue
                        )
                    }
                    .padding(.horizontal, 24)
                }
            }
            .opacity(pageVisible ? 1.0 : 0.0)
            .offset(y: pageVisible ? 0 : 30)
            
            Spacer()
            
            // 按钮
            Button(action: {
                Logger.logPageNavigation(from: "Onboarding-4", to: "Paywall")
                showPaywall = true
            }) {
                Text("onboarding.page4.start_cleaning".localized)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    Color.seniorPrimary
                )
                .cornerRadius(28)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 36)
            .opacity(pageVisible ? 1.0 : 0.0)
            .offset(y: pageVisible ? 0 : 30)
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            startPhotoAnalysis()
            // 简单的页面出现动画
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                pageVisible = true
            }
        }
    }
    
    private func startPhotoAnalysis() {
        isAnalyzing = true
        
        Task {
            let count = await photoAnalyzer.getPhotoCount()
            
            await MainActor.run {
                photoCount = count
                isAnalyzing = false
                
                Logger.analytics.info("用户照片总数: \(count)")
            }
        }
    }
    
    private func calculateEstimatedSpaceSavings() -> String {
        guard photoCount > 0 else { return "onboarding.page4.calculating".localized }
        
        // 基于合理假设的计算：
        // 1. 假设10-15%的照片是重复或相似的
        // 2. 每张照片平均大小约2-5MB（现代手机拍摄）
        // 3. 根据照片数量动态调整重复率
        
        let duplicateRate: Double
        let averagePhotoSize: Int64
        
        if photoCount < 100 {
            duplicateRate = 0.05 // 5% 重复率（较少照片时重复较少）
            averagePhotoSize = 3 * 1024 * 1024 // 3MB
        } else if photoCount < 500 {
            duplicateRate = 0.10 // 10% 重复率
            averagePhotoSize = 4 * 1024 * 1024 // 4MB
        } else if photoCount < 1000 {
            duplicateRate = 0.12 // 12% 重复率
            averagePhotoSize = 4 * 1024 * 1024 // 4MB
        } else {
            duplicateRate = 0.15 // 15% 重复率（照片越多，重复越可能）
            averagePhotoSize = 5 * 1024 * 1024 // 5MB
        }
        
        let estimatedDuplicates = Int(Double(photoCount) * duplicateRate)
        let estimatedSavings = Int64(estimatedDuplicates) * averagePhotoSize
        
        // 添加一些随机性使其看起来更真实
        let randomFactor = Double.random(in: 0.8...1.2)
        let finalSavings = Int64(Double(estimatedSavings) * randomFactor)
        
        Logger.analytics.info("预计节省空间计算: 照片总数=\(photoCount), 重复率=\(Int(duplicateRate*100))%, 预计节省=\(formatByteCount(finalSavings))")
        
        return formatByteCount(finalSavings)
    }
    
    private func calculateEstimatedDuplicates() -> String {
        guard photoCount > 0 else { return "onboarding.page4.calculating".localized }
        
        let duplicateRate: Double
        
        if photoCount < 100 {
            duplicateRate = 0.05 // 5% 重复率
        } else if photoCount < 500 {
            duplicateRate = 0.10 // 10% 重复率
        } else if photoCount < 1000 {
            duplicateRate = 0.12 // 12% 重复率
        } else {
            duplicateRate = 0.15 // 15% 重复率
        }
        
        let estimatedDuplicates = Int(Double(photoCount) * duplicateRate)
        return "\(formatNumber(estimatedDuplicates))\("onboarding.page4.photos_unit".localized)"
    }
    
    // MARK: - Helper Methods
    
    /// 格式化字节数为可读的大小字符串，确保使用阿拉伯数字
    private func formatByteCount(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        
        // 获取格式化后的字符串
        let formatted = formatter.string(fromByteCount: bytes)
        
        // 手动处理常见的大小单位，确保使用阿拉伯数字
        let gb = Double(bytes) / (1024.0 * 1024.0 * 1024.0)
        let mb = Double(bytes) / (1024.0 * 1024.0)
        let kb = Double(bytes) / 1024.0
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.locale = Locale.current
        
        if gb >= 1.0 {
            let formattedNumber = numberFormatter.string(from: NSNumber(value: gb)) ?? String(format: "%.1f", gb)
            return "\(formattedNumber) \("onboarding.page4.gb_unit".localized)"
        } else if mb >= 1.0 {
            let formattedNumber = numberFormatter.string(from: NSNumber(value: mb)) ?? String(format: "%.1f", mb)
            return "\(formattedNumber) \("onboarding.page4.mb_unit".localized)"
        } else if kb >= 1.0 {
            let formattedNumber = numberFormatter.string(from: NSNumber(value: kb)) ?? String(format: "%.1f", kb)
            return "\(formattedNumber) \("onboarding.page4.kb_unit".localized)"
        } else {
            let formattedNumber = numberFormatter.string(from: NSNumber(value: bytes)) ?? "\(bytes)"
            return "\(formattedNumber) \("onboarding.page4.bytes_unit".localized)"
        }
    }
    
    /// 格式化数字，确保使用阿拉伯数字
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
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