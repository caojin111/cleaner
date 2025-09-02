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
    static let appName = "app.name".localized
    static let developerInfo = "app.developer".localized
    static let appVersion = "app.version".localized
    
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
        static let yearlyOriginalPrice = "paywall.plan.yearly_original_price".localized // 原价（划线显示）
        static let yearlyPrice = "paywall.plan.yearly_price".localized // 折扣价
        static let yearlyTrial = "paywall.plan.yearly_trial".localized
        static let monthlyPrice = "paywall.plan.monthly_price".localized
        static let weeklyPrice = "paywall.plan.weekly_price".localized
    }
    
    // MARK: - Onboarding Content
    struct Onboarding {
        static let page1Title = "高效清理，节省空间"
        static let page1Subtitle = "智能分析，提升手机性能"
        
        static let page2Title = "onboarding.page2.title".localized
        static let page2Button = "onboarding.page2.continue".localized
        
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
    static let seniorBody = Font.system(size: 25, weight: .regular)
    static let seniorCaption = Font.system(size: 16, weight: .regular)
}

extension Color {
    static let seniorPrimary = Color(red: 11.0/255.0, green: 173.0/255.0, blue: 217.0/255.0)
    static let seniorSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)
    static let seniorBackground = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let seniorText = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let seniorSuccess = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let seniorDanger = Color(red: 0.9, green: 0.3, blue: 0.3)
} 