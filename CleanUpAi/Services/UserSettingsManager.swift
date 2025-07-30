//
//  UserSettingsManager.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import Foundation
import OSLog

class UserSettingsManager: ObservableObject {
    static let shared = UserSettingsManager()
    
    @Published var isFirstLaunch: Bool {
        didSet {
            UserDefaults.standard.set(self.isFirstLaunch, forKey: "isFirstLaunch")
            Logger.analytics.info("用户首次启动状态已更新: \(self.isFirstLaunch)")
        }
    }
    
    @Published var isSubscribed: Bool {
        didSet {
            UserDefaults.standard.set(self.isSubscribed, forKey: "isSubscribed")
            Logger.analytics.info("订阅状态已更新: \(self.isSubscribed)")
        }
    }
    
    // 每日滑动次数限制
    private let swipeLimit = 10
    private let swipeDateKey = "swipeDate"
    private let swipeCountKey = "swipeCount"
    
    // 评分弹窗相关
    private let hasShownRatingKey = "hasShownRating"
    private let firstSwipeLimitReachedKey = "firstSwipeLimitReached"
    private let shouldShowThankYouKey = "shouldShowThankYou"
    
    @Published var shouldShowRating: Bool = false
    @Published var shouldShowThankYou: Bool = false
    
    var todaySwipeCount: Int {
        get {
            let today = Self.dateString(Date())
            let lastDate = UserDefaults.standard.string(forKey: swipeDateKey)
            if lastDate != today {
                // 新的一天，重置
                UserDefaults.standard.set(today, forKey: swipeDateKey)
                UserDefaults.standard.set(0, forKey: swipeCountKey)
                return 0
            }
            return UserDefaults.standard.integer(forKey: swipeCountKey)
        }
        set {
            let today = Self.dateString(Date())
            UserDefaults.standard.set(today, forKey: swipeDateKey)
            UserDefaults.standard.set(newValue, forKey: swipeCountKey)
        }
    }
    
    var canSwipeToday: Bool {
        isSubscribed || todaySwipeCount < swipeLimit
    }
    
    var remainingSwipes: Int {
        if isSubscribed {
            return -1 // 订阅用户无限制
        }
        return max(0, swipeLimit - todaySwipeCount)
    }
    
    func increaseSwipeCount() {
        guard !isSubscribed else { 
            Logger.analytics.info("订阅用户滑动，无需计数")
            return 
        }
        todaySwipeCount = todaySwipeCount + 1
        Logger.analytics.info("滑动次数已增加，今日剩余: \(self.remainingSwipes)/10")
        
        // 检查是否需要显示评分弹窗
        checkForRatingPrompt()
    }
    
    /// 检查是否需要显示评分弹窗
    private func checkForRatingPrompt() {
        // 如果已经显示过评分弹窗，不再显示
        let hasShownRating = UserDefaults.standard.bool(forKey: hasShownRatingKey)
        if hasShownRating {
            return
        }
        
        // 如果用户是订阅用户，不显示评分弹窗
        if isSubscribed {
            return
        }
        
        // 检查是否首次达到10次滑动限制
        let hasReachedLimitBefore = UserDefaults.standard.bool(forKey: firstSwipeLimitReachedKey)
        if !hasReachedLimitBefore && todaySwipeCount >= swipeLimit {
            // 标记已达到限制
            UserDefaults.standard.set(true, forKey: firstSwipeLimitReachedKey)
            // 触发显示评分弹窗
            DispatchQueue.main.async {
                self.shouldShowRating = true
                Logger.analytics.info("首次达到滑动限制，触发评分弹窗")
            }
        }
    }
    
    /// 标记已显示评分弹窗
    func markRatingShown() {
        UserDefaults.standard.set(true, forKey: hasShownRatingKey)
        shouldShowRating = false
        Logger.analytics.info("评分弹窗已显示，已标记")
    }
    
    /// 标记需要显示感谢弹窗
    func markShouldShowThankYou() {
        UserDefaults.standard.set(true, forKey: shouldShowThankYouKey)
        shouldShowThankYou = true
        Logger.analytics.info("标记需要显示感谢弹窗")
    }
    
    /// 标记已显示感谢弹窗
    func markThankYouShown() {
        UserDefaults.standard.set(false, forKey: shouldShowThankYouKey)
        shouldShowThankYou = false
        Logger.analytics.info("感谢弹窗已显示，已标记")
    }
    
    static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private init() {
        // 如果从未设置过，则默认为 true（首次启动）
        let hasKey = UserDefaults.standard.object(forKey: "isFirstLaunch") != nil
        self.isFirstLaunch = hasKey ? UserDefaults.standard.bool(forKey: "isFirstLaunch") : true
        
        self.isSubscribed = UserDefaults.standard.bool(forKey: "isSubscribed")
        
        // 初始化感谢弹窗状态
        self.shouldShowThankYou = UserDefaults.standard.bool(forKey: shouldShowThankYouKey)
        
        Logger.analytics.info("UserSettingsManager初始化 - hasKey: \(hasKey), isFirstLaunch: \(self.isFirstLaunch)")
    }
    
    /// 标记用户已完成首次启动流程
    func markOnboardingCompleted() {
        isFirstLaunch = false
        Logger.analytics.info("用户首次启动流程已完成")
    }
    
    /// 重置首次启动状态（仅用于调试）
    func resetFirstLaunch() {
        isFirstLaunch = true
        Logger.analytics.info("重置首次启动状态")
    }
    
    /// 重置评分状态（仅用于调试）
    func resetRatingStatus() {
        UserDefaults.standard.removeObject(forKey: hasShownRatingKey)
        UserDefaults.standard.removeObject(forKey: firstSwipeLimitReachedKey)
        shouldShowRating = false
        Logger.analytics.info("重置评分状态")
    }
    
    /// 模拟达到滑动限制（仅用于调试）
    func simulateSwipeLimitReached() {
        guard !isSubscribed else {
            Logger.analytics.info("订阅用户不会显示评分弹窗")
            return
        }
        
        let hasShownRating = UserDefaults.standard.bool(forKey: hasShownRatingKey)
        if !hasShownRating {
            shouldShowRating = true
            Logger.analytics.info("模拟滑动限制达到，显示评分弹窗")
        } else {
            Logger.analytics.info("评分弹窗已显示过，不再显示")
        }
    }
} 