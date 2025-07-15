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
    
    private init() {
        // 如果从未设置过，则默认为 true（首次启动）
        let hasKey = UserDefaults.standard.object(forKey: "isFirstLaunch") != nil
        self.isFirstLaunch = hasKey ? UserDefaults.standard.bool(forKey: "isFirstLaunch") : true
        
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