//
//  Constants.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import Foundation
import SwiftUI

struct Constants {
    
    // MARK: - App Info
    static let appName = "CleanUp AI"
    static let developerInfo = "Made with LazyCat"
    static let appVersion = "1.0.0"
    
    // MARK: - Timing
    static let splashDuration: Double = 2.5
    static let animationDuration: Double = 0.3
    
    // MARK: - UI Dimensions
    static let logoSize: CGFloat = 120
    static let buttonHeight: CGFloat = 50
    static let cornerRadius: CGFloat = 12
    static let cardSpacing: CGFloat = 16
    
    // MARK: - Subscription Prices
    struct Subscription {
        static let yearlyOriginalPrice = "$49.99/年" // 原价（划线显示）
        static let yearlyPrice = "$29.99/年" // 折扣价
        static let yearlyTrial = "7天免费试用"
        static let monthlyPrice = "$9.99/月"
        static let weeklyPrice = "$4.99/周"
    }
    
    // MARK: - Onboarding Content
    struct Onboarding {
        static let page1Title = "高效清理，节省空间"
        static let page1Subtitle = "智能分析，提升手机性能"
        
        static let page2Title = "需要以下权限"
        static let page2Button = "授权"
        
        static let page3Title = "年度图片回顾"
        static let page3Subtitle = "智能分析您的照片收藏"
        
        static let page4Title = "您有 %d 张图片等待清理"
        static let page4Subtitle = "开始清理，释放更多空间"
    }
    
    // MARK: - Swipe Thresholds
    static let swipeThreshold: CGFloat = 100
    static let swipeHintThreshold: CGFloat = 50
    
    // MARK: - File Analysis
    static let maxConcurrentAnalysis = 5
    static let thumbnailSize = CGSize(width: 200, height: 200)
}

// MARK: - Senior UI Extensions
extension Font {
    static let seniorLargeTitle = Font.system(size: 32, weight: .bold)
    static let seniorTitle = Font.system(size: 24, weight: .semibold)
    static let seniorBody = Font.system(size: 20, weight: .regular)
    static let seniorCaption = Font.system(size: 16, weight: .regular)
}

extension Color {
    static let seniorPrimary = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let seniorSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)
    static let seniorBackground = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let seniorText = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let seniorSuccess = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let seniorDanger = Color(red: 0.9, green: 0.3, blue: 0.3)
} 