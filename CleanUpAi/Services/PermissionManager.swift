//
//  PermissionManager.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import Foundation
import Photos
import UserNotifications
import SwiftUI
import OSLog

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        updateCurrentStatus()
    }
    
    // MARK: - Status Updates
    
    func updateCurrentStatus() {
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Permission Requests
    
    func requestPhotoLibraryPermission() async -> Bool {
        Logger.logPermissionRequest("照片库")
        
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        
        await MainActor.run {
            photoLibraryStatus = status
        }
        
        switch status {
        case .authorized, .limited:
            Logger.logPermissionGranted("照片库")
            return true
        case .denied, .restricted:
            Logger.logPermissionDenied("照片库")
            return false
        case .notDetermined:
            Logger.logPermissionDenied("照片库 - 未确定")
            return false
        @unknown default:
            Logger.logPermissionDenied("照片库 - 未知状态")
            return false
        }
    }
    
    func requestNotificationPermission() async -> Bool {
        Logger.logPermissionRequest("通知")
        
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await MainActor.run {
                notificationStatus = granted ? .authorized : .denied
            }
            
            if granted {
                Logger.logPermissionGranted("通知")
            } else {
                Logger.logPermissionDenied("通知")
            }
            
            return granted
        } catch {
            Logger.logError(error, context: "请求通知权限")
            await MainActor.run {
                notificationStatus = .denied
            }
            return false
        }
    }
    
    // MARK: - Permission Status Checks
    
    var hasPhotoLibraryAccess: Bool {
        switch photoLibraryStatus {
        case .authorized, .limited:
            return true
        default:
            return false
        }
    }
    
    var hasNotificationAccess: Bool {
        notificationStatus == .authorized
    }
    
    var allRequiredPermissionsGranted: Bool {
        hasPhotoLibraryAccess
    }
    
    // MARK: - Settings Navigation
    
    func openAppSettings() {
        Logger.ui.info("打开应用设置")
        
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - Permission Descriptions
    
    func getPermissionDescription(for permission: String) -> String {
        switch permission {
        case "photos":
            return "需要访问照片库来分析和清理重复/相似图片"
        case "notifications":
            return "需要发送通知来提醒用户清理建议"
        default:
            return "需要此权限来提供更好的服务"
        }
    }
    
    func getPermissionStatusText(for permission: String) -> String {
        switch permission {
        case "photos":
            switch photoLibraryStatus {
            case .authorized:
                return "已授权"
            case .limited:
                return "部分授权"
            case .denied:
                return "已拒绝"
            case .restricted:
                return "受限制"
            case .notDetermined:
                return "未设置"
            @unknown default:
                return "未知"
            }
        case "notifications":
            switch notificationStatus {
            case .authorized:
                return "已授权"
            case .denied:
                return "已拒绝"
            case .notDetermined:
                return "未设置"
            case .provisional:
                return "临时授权"
            case .ephemeral:
                return "临时授权"
            @unknown default:
                return "未知"
            }
        default:
            return "未知"
        }
    }
} 