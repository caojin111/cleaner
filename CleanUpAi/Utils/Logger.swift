//
//  Logger.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    // MARK: - Logger Categories
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let fileManager = Logger(subsystem: subsystem, category: "FileManager")
    static let permissions = Logger(subsystem: subsystem, category: "Permissions")
    static let analytics = Logger(subsystem: subsystem, category: "Analytics")
    static let photoAnalyzer = Logger(subsystem: subsystem, category: "PhotoAnalyzer")
    static let recycleBin = Logger(subsystem: subsystem, category: "RecycleBin")
    static let subscription = Logger(subsystem: subsystem, category: "Subscription")
    
    // MARK: - Convenience Methods
    static func logAppLaunch() {
        ui.info("🚀 CleanUp AI 应用启动")
    }
    
    static func logPageNavigation(from: String, to: String) {
        ui.info("📱 页面导航: \(from) → \(to)")
    }
    
    static func logPermissionRequest(_ permission: String) {
        permissions.info("🔐 请求权限: \(permission)")
    }
    
    static func logPermissionGranted(_ permission: String) {
        permissions.info("✅ 权限已授权: \(permission)")
    }
    
    static func logPermissionDenied(_ permission: String) {
        permissions.warning("❌ 权限被拒绝: \(permission)")
    }
    
    static func logFileAnalysisStart(count: Int) {
        fileManager.info("🔍 开始分析 \(count) 个文件")
    }
    
    static func logFileAnalysisComplete(duplicates: Int) {
        fileManager.info("✅ 分析完成，发现 \(duplicates) 个重复文件")
    }
    
    static func logFileDelete(_ fileName: String) {
        fileManager.info("🗑️ 文件已删除: \(fileName)")
    }
    
    static func logFileRestore(_ fileName: String) {
        fileManager.info("♻️ 文件已恢复: \(fileName)")
    }
    
    static func logError(_ error: Error, context: String) {
        Logger(subsystem: subsystem, category: "Error").error("❌ 错误[\(context)]: \(error.localizedDescription)")
    }
} 