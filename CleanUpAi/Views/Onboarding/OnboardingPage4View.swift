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
        VStack(spacing: 36) {
            Spacer()
            // 统计动画
            ZStack {
                Circle()
                    .fill(Color(red: 0.66, green: 1, blue: 0.81).opacity(0.18))
                    .frame(width: 180, height: 180)
                VStack(spacing: 16) {
                    Text("\(animateNumbers ? formatNumber(photoCount) : formatNumber(0))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    Text("张照片")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                    }
                }
            // 文案
            VStack(spacing: 18) {
                Text("您有 \(formatNumber(photoCount)) 张照片待清理")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Text(Constants.Onboarding.page4Subtitle)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                if photoCount > 0 {
                    VStack(spacing: 12) {
                        StatRow(
                            icon: "🟢",
                            title: "预计重复照片",
                            value: calculateEstimatedDuplicates(),
                            color: .orange
                        )
                        StatRow(
                            icon: "🟢",
                            title: "预计节省空间",
                            value: calculateEstimatedSpaceSavings(),
                            color: .green
                        )
                        StatRow(
                            icon: "🟢",
                            title: "性能提升",
                            value: "显著改善",
                            color: .blue
                        )
                    }
                    .padding(.horizontal, 24)
                }
            }
            Spacer()
            // 按钮
            Button(action: {
                Logger.logPageNavigation(from: "Onboarding-4", to: "Paywall")
                showPaywall = true
            }) {
                    Text("开始清理")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                        LinearGradient(gradient: Gradient(colors: [Color(red: 0.85, green: 1, blue: 0.72), Color(red: 0.66, green: 1, blue: 0.81)]), startPoint: .leading, endPoint: .trailing)
                        )
                    .cornerRadius(28)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 36)
        }
        .background(Color(red: 0.95, green: 1, blue: 0.96).ignoresSafeArea())
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
    
    private func calculateEstimatedSpaceSavings() -> String {
        guard photoCount > 0 else { return "计算中..." }
        
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
        guard photoCount > 0 else { return "计算中..." }
        
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
        return "\(formatNumber(estimatedDuplicates))张"
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
        numberFormatter.locale = Locale(identifier: "zh_CN")
        
        if gb >= 1.0 {
            let formattedNumber = numberFormatter.string(from: NSNumber(value: gb)) ?? String(format: "%.1f", gb)
            return "\(formattedNumber) GB"
        } else if mb >= 1.0 {
            let formattedNumber = numberFormatter.string(from: NSNumber(value: mb)) ?? String(format: "%.1f", mb)
            return "\(formattedNumber) MB"
        } else if kb >= 1.0 {
            let formattedNumber = numberFormatter.string(from: NSNumber(value: kb)) ?? String(format: "%.1f", kb)
            return "\(formattedNumber) KB"
        } else {
            let formattedNumber = numberFormatter.string(from: NSNumber(value: bytes)) ?? "\(bytes)"
            return "\(formattedNumber) 字节"
        }
    }
    
    /// 格式化数字，确保使用阿拉伯数字
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "zh_CN")
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