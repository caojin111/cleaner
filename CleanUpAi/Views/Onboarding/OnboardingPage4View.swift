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
    @State private var actualDuplicates: Int = 0
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
                            value: calculatePerformanceBoost(),
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
            // 获取照片总数
            let count = await photoAnalyzer.getPhotoCount()
            
            // 执行实际分析以获取真实的重复数量
            await photoAnalyzer.startAnalysis()
            let actualDuplicatesCount = photoAnalyzer.foundDuplicates.count
            
            await MainActor.run {
                photoCount = count
                actualDuplicates = actualDuplicatesCount
                isAnalyzing = false
                
                Logger.analytics.info("用户照片总数: \(count), 实际重复数: \(actualDuplicatesCount)")
            }
        }
    }
    
    private func calculateEstimatedSpaceSavings() -> String {
        guard photoCount > 0 else { return "onboarding.page4.calculating".localized }
        
        // 优先使用PhotoAnalyzer中的准确空间节省数据
        if actualDuplicates > 0 {
            let actualSavings = photoAnalyzer.estimatedSpaceSavings()
            Logger.analytics.info("使用准确的空间节省数据: \(formatByteCount(actualSavings))")
            return formatByteCount(actualSavings)
        }
        
        // 如果还没有实际分析结果，使用预估
        let duplicateCount = calculateEstimatedDuplicatesCount()
        
        // 基于合理假设的计算：
        // 每张照片平均大小约2-5MB（现代手机拍摄）
        let averagePhotoSize: Int64
        
        if photoCount < 100 {
            averagePhotoSize = 3 * 1024 * 1024 // 3MB
        } else if photoCount < 500 {
            averagePhotoSize = 4 * 1024 * 1024 // 4MB
        } else if photoCount < 1000 {
            averagePhotoSize = 4 * 1024 * 1024 // 4MB
        } else {
            averagePhotoSize = 5 * 1024 * 1024 // 5MB
        }
        
        let estimatedSavings = Int64(duplicateCount) * averagePhotoSize
        
        // 添加一些随机性使其看起来更真实
        let randomFactor = Double.random(in: 0.8...1.2)
        let finalSavings = Int64(Double(estimatedSavings) * randomFactor)
        
        Logger.analytics.info("使用预估的空间节省数据: 照片总数=\(photoCount), 预估重复数=\(duplicateCount), 预计节省=\(formatByteCount(finalSavings))")
        
        return formatByteCount(finalSavings)
    }
    
    private func calculateEstimatedDuplicates() -> String {
        guard photoCount > 0 else { return "onboarding.page4.calculating".localized }
        
        // 优先使用实际检测到的重复数量
        if actualDuplicates > 0 {
            return "\(formatNumber(actualDuplicates))\("onboarding.page4.photos_unit".localized)"
        }
        
        // 如果还没有实际分析结果，使用预估值
        let estimatedCount = calculateEstimatedDuplicatesCount()
        return "\(formatNumber(estimatedCount))\("onboarding.page4.photos_unit".localized)"
    }
    
    private func calculateEstimatedDuplicatesCount() -> Int {
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
        
        return Int(Double(photoCount) * duplicateRate)
    }
    
    private func calculatePerformanceBoost() -> String {
        guard photoCount > 0 else { return "onboarding.page4.calculating".localized }
        
        // 基于重复文件数量和节省空间计算性能提升
        let duplicateCount = actualDuplicates > 0 ? actualDuplicates : calculateEstimatedDuplicatesCount()
        
        // 计算性能提升等级
        let performanceLevel: String
        let improvementPercentage: Int
        
        if duplicateCount < 10 {
            performanceLevel = "onboarding.page4.minor_improvement".localized
            improvementPercentage = 5
        } else if duplicateCount < 50 {
            performanceLevel = "onboarding.page4.noticeable_improvement".localized
            improvementPercentage = 15
        } else if duplicateCount < 100 {
            performanceLevel = "onboarding.page4.significant_improvement".localized
            improvementPercentage = 25
        } else if duplicateCount < 200 {
            performanceLevel = "onboarding.page4.major_improvement".localized
            improvementPercentage = 35
        } else {
            performanceLevel = "onboarding.page4.exceptional_improvement".localized
            improvementPercentage = 50
        }
        
        Logger.analytics.info("性能提升计算: 重复数=\(duplicateCount), 提升等级=\(performanceLevel), 提升百分比=\(improvementPercentage)%")
        
        return performanceLevel
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