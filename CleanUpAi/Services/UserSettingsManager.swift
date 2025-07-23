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
} 