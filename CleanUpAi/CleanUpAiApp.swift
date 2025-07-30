//
//  CleanUpAiApp.swift
//  CleanUpAi
//
//  Created by Allen on 2025/7/10.
//

import SwiftUI
import UserNotifications
import FirebaseCore

@main
struct CleanUpAiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 在应用启动时初始化StoreKitManager
    init() {
        // 预加载StoreKit产品信息
        StoreKitManager.shared.preloadProducts()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 配置Firebase
        FirebaseApp.configure()
        
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // 应用在前台时收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 即使应用在前台也显示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    // 用户点击通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 处理通知点击事件
        let identifier = response.notification.request.identifier
        
        if identifier == "daily_cleanup_reminder" {
            // 用户点击了每日清理提醒，可以在这里打开应用或执行特定操作
            print("用户点击了每日清理提醒")
        }
        
        completionHandler()
    }
}
