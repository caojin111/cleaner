//
//  CleanUpAiApp.swift
//  CleanUpAi
//
//  Created by Allen on 2025/7/10.
//

import SwiftUI
import UserNotifications
import FirebaseCore
import FirebaseAnalytics

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
                .onAppear {
                    Task { await NotificationManager.shared.clearBadgeAndDeliveredNotifications() }
                }
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // 配置Firebase
        FirebaseApp.configure()

        // 记录应用启动事件
        FirebaseManager.shared.logAppOpen()

        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self

        // 重置Paywall倒计时（只有在app完全重新启动时）
        resetPaywallCountdown()

        // 记录应用启动完成事件
        FirebaseManager.shared.logUserAction(action: "app_launch_completed")

        return true
    }

    // 重置Paywall倒计时
    private func resetPaywallCountdown() {
        // 清除UserDefaults中的倒计时数据，让下次打开Paywall时重新开始
        UserDefaults.standard.removeObject(forKey: "paywall_countdown_end_time")
        print("Paywall: App启动时重置倒计时")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // 应用在前台时收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 即使应用在前台也显示通知
        completionHandler([.banner, .sound]) // 前台不显示角标，避免常驻红点
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
