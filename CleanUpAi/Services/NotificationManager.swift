import Foundation
import UserNotifications
import OSLog
import UIKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let logger = Logger(subsystem: "com.cleanupai.app", category: "NotificationManager")
    
    private init() {}
    
    // MARK: - 请求通知权限
    func requestNotificationPermission() async -> Bool {
        logger.info("请求通知权限")
        
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                logger.info("通知权限状态: \(granted)")
            }
            
            return granted
        } catch {
            logger.error("请求通知权限失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 检查通知权限状态
    func checkNotificationPermission() async -> UNAuthorizationStatus {
        logger.info("检查通知权限状态")
        
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        logger.info("通知权限状态: \(settings.authorizationStatus.rawValue)")
        
        return settings.authorizationStatus
    }
    
    // MARK: - 设置每日清理提醒
    func scheduleDailyCleanupReminder() async {
        logger.info("设置每日清理提醒")
        
        // 首先检查权限
        let permissionStatus = await checkNotificationPermission()
        guard permissionStatus == .authorized else {
            logger.warning("通知权限未授权，无法设置提醒")
            return
        }
        
        // 移除现有的清理提醒
        await removeDailyCleanupReminder()
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "CleanUp AI"
        content.body = "Time for daily cleanup! Keep your device running smoothly."
        content.sound = .default
        // 不再强制设置角标，避免图标上长期显示红点
        // 如需显示角标，可在此计算未处理事项数量后赋值
        
        // 添加应用图标作为附件（如果可能）
        if let attachment = createNotificationAttachment() {
            content.attachments = [attachment]
        }
        
        // 创建触发器 - 每天20:00
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        // 创建通知请求
        let request = UNNotificationRequest(
            identifier: "daily_cleanup_reminder",
            content: content,
            trigger: trigger
        )
        
        // 添加通知请求
        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("每日清理提醒设置成功")
        } catch {
            logger.error("设置每日清理提醒失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 移除每日清理提醒
    func removeDailyCleanupReminder() async {
        logger.info("移除每日清理提醒")
        
        let identifiers = ["daily_cleanup_reminder"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        
        logger.info("每日清理提醒已移除")
    }
    
    // MARK: - 创建通知附件（应用图标）
    private func createNotificationAttachment() -> UNNotificationAttachment? {
        // 尝试从Assets中获取应用图标
        if let image = UIImage(named: "AppIcon") {
            // 将UIImage转换为临时文件
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent("app_icon.png")
            
            do {
                if let imageData = image.pngData() {
                    try imageData.write(to: tempFile)
                    
                    let attachment = try UNNotificationAttachment(
                        identifier: "app_icon",
                        url: tempFile,
                        options: nil
                    )
                    logger.info("通知附件创建成功")
                    return attachment
                }
            } catch {
                logger.error("创建通知附件失败: \(error.localizedDescription)")
            }
        }
        
        logger.warning("无法创建应用图标附件")
        return nil
    }
    
    // MARK: - 获取所有待处理的通知
    func getPendingNotifications() async -> [UNNotificationRequest] {
        logger.info("获取待处理通知")
        
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        logger.info("待处理通知数量: \(requests.count)")
        
        return requests
    }
    
    // MARK: - 清除所有通知
    func clearAllNotifications() async {
        logger.info("清除所有通知")
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        logger.info("所有通知已清除")
    }

    // MARK: - 清零角标与已送达通知
    func clearBadgeAndDeliveredNotifications() async {
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = 0
            logger.info("应用角标已清零")
        }
        await UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        logger.info("已送达通知已清除")
    }
    
    // MARK: - 发送测试通知
    func sendTestNotification() async {
        logger.info("发送测试通知")
        
        let content = UNMutableNotificationContent()
        content.title = "CleanUp AI"
        content.body = "Test notification - Daily cleanup reminder is working!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("测试通知发送成功")
        } catch {
            logger.error("发送测试通知失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 检查每日提醒是否已设置
    func isDailyReminderScheduled() async -> Bool {
        let requests = await getPendingNotifications()
        return requests.contains { $0.identifier == "daily_cleanup_reminder" }
    }
} 