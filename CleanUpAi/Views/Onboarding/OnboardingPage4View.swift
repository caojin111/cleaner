//
//  OnboardingPage4View.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct OnboardingPage4View: View {
    @Binding var currentPage: Int
    @Binding var showPaywall: Bool
    @StateObject private var photoAnalyzer = PhotoAnalyzer.shared
    @State private var photoCount: Int = 0
    @State private var actualDuplicates: Int = 0
    @State private var isAnalyzing = false
    @State private var pageVisible = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 主要数字展示区域 - 匹配Figma设计，去掉圆形背景
                VStack(spacing: 16) {
                    Text(formatNumber(photoCount))
                        .font(.system(size: 75, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1985A2"))
                    Text("onboarding.page4.photos_count".localized)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "000000"))
                    Text("onboarding.page4.title".localized)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 16)
                }
                .opacity(pageVisible ? 1.0 : 0.0)
                .offset(y: pageVisible ? 0 : 30)

                // 统计信息区域
                if photoCount > 0 {
                    VStack(spacing: 12) {
                        StatRow(
                            title: "onboarding.page4.estimated_duplicates".localized,
                            value: calculateEstimatedDuplicates(),
                            color: Color(hex: "EA8373")
                        )
                        StatRow(
                            title: "onboarding.page4.estimated_saving".localized,
                            value: calculateEstimatedSpaceSavings(),
                            color: Color(hex: "76CD51")
                        )
                        StatRow(
                            title: "onboarding.page4.performance_boost".localized,
                            value: calculatePerformanceBoost(),
                            color: Color(hex: "5180CD")
                        )
                    }
                    .padding(.horizontal, 34)
                    .padding(.top, 32)
                    .opacity(pageVisible ? 1.0 : 0.0)
                    .offset(y: pageVisible ? 0 : 30)
                }

                Spacer()

                // 开始清理按钮 - 匹配Figma设计
                Button(action: {
                    Logger.logPageNavigation(from: "Onboarding-4", to: "Paywall")
                    showPaywall = true
                }) {
                                    Text("onboarding.page4.start_cleaning".localized)
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color(hex: "0BA9D4"))
                        .cornerRadius(50)
                }
                .padding(.horizontal, 62)
                .padding(.bottom, 36)
                .opacity(pageVisible ? 1.0 : 0.0)
                .offset(y: pageVisible ? 0 : 30)
            }
        }
        .onAppear {
            startPhotoAnalysis()
            // 页面出现动画
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
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            // 小图标区域
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "D9D9D9").opacity(0.289))
                    .frame(width: 25, height: 25)
                // 使用已下载的图片作为图标
                Image("e90804c70b59f2ca41899da040ab1892")
                    .resizable()
                    .frame(width: 25, height: 25)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "000000"))

                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 328, height: 76)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "D9D9D9").opacity(0.289))
        )
    }
}

#Preview {
    OnboardingPage4View(
        currentPage: .constant(3),
        showPaywall: .constant(false)
    )
} 