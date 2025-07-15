//
//  RecycleBinManager.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import Foundation
import Photos
import SwiftUI
import OSLog
import UserNotifications

@MainActor
class RecycleBinManager: ObservableObject {
    static let shared = RecycleBinManager()
    
    @Published var items: [MediaItem] = []
    @Published var totalDeletedSize: Int64 = 0
    
    private let userDefaults = UserDefaults.standard
    private let recycleKey = "RecycleBinItems"
    
    private init() {
        loadFromUserDefaults()
    }
    
    // MARK: - Main Operations
    
    func moveToRecycleBin(_ item: MediaItem) {
        Logger.logFileDelete(item.fileName)
        
        var updatedItem = item
        updatedItem.isInRecycleBin = true
        updatedItem.deletedDate = Date()
        
        self.items.append(updatedItem)
        self.updateTotalSize()
        self.saveToUserDefaults()
        
        // 发送通知
        self.sendDeleteNotification(fileName: item.fileName)
    }
    
    func moveMultipleToRecycleBin(_ items: [MediaItem]) {
        for item in items {
            var updatedItem = item
            updatedItem.isInRecycleBin = true
            updatedItem.deletedDate = Date()
            self.items.append(updatedItem)
            
            Logger.logFileDelete(item.fileName)
        }
        
        self.updateTotalSize()
        self.saveToUserDefaults()
        
        // 发送批量删除通知
        self.sendBatchDeleteNotification(count: self.items.count)
    }
    
    func restore(_ item: MediaItem) {
        Logger.logFileRestore(item.fileName)
        
        self.items.removeAll { $0.id == item.id }
        self.updateTotalSize()
        self.saveToUserDefaults()
    }
    
    func permanentlyDelete(_ item: MediaItem) async {
        Logger.recycleBin.info("永久删除项目: \(item.fileName)")
        
        do {
            if let asset = item.asset {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.deleteAssets([asset] as NSArray)
                }
            } else if let fileURL = item.fileURL {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            // 从回收站移除
            self.items.removeAll { $0.id == item.id }
            self.updateTotalSize()
            self.saveToUserDefaults()
            
            Logger.recycleBin.info("项目已永久删除: \(item.fileName)")
        } catch {
            Logger.logError(error, context: "永久删除文件")
        }
    }
    
    func permanentlyDeleteAll() async {
        let startTime = Date()
        Logger.recycleBin.info("开始批量永久删除所有回收站项目，总数: \(self.items.count)")
        
        guard !self.items.isEmpty else {
            Logger.recycleBin.info("回收站为空，无需删除")
            return
        }
        
        let itemsToDelete = self.items
        var photoAssets: [PHAsset] = []
        var fileURLs: [URL] = []
        
        // 分类收集需要删除的资源
        for item in itemsToDelete {
            if let asset = item.asset {
                photoAssets.append(asset)
                Logger.recycleBin.debug("添加照片资源到批量删除列表: \(item.fileName)")
            } else if let fileURL = item.fileURL {
                fileURLs.append(fileURL)
                Logger.recycleBin.debug("添加文件到批量删除列表: \(item.fileName)")
            }
        }
        
        Logger.recycleBin.info("资源分类完成 - 照片: \(photoAssets.count), 文件: \(fileURLs.count)")
        
        do {
            // 批量删除照片资源（真正的批量操作）
            if !photoAssets.isEmpty {
                Logger.recycleBin.info("开始批量删除 \(photoAssets.count) 个照片资源")
                
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.deleteAssets(photoAssets as NSArray)
                }
                
                Logger.recycleBin.info("照片批量删除完成，耗时: \(Date().timeIntervalSince(startTime))秒")
            }
            
            // 批量删除文件系统文件
            if !fileURLs.isEmpty {
                Logger.recycleBin.info("开始批量删除 \(fileURLs.count) 个文件系统文件")
                
                for (index, fileURL) in fileURLs.enumerated() {
                    try FileManager.default.removeItem(at: fileURL)
                    Logger.recycleBin.debug("删除文件 (\(index + 1)/\(fileURLs.count)): \(fileURL.lastPathComponent)")
                }
                
                Logger.recycleBin.info("文件系统文件批量删除完成")
            }
            
            // 清空回收站列表
            self.items.removeAll()
            self.updateTotalSize()
            self.saveToUserDefaults()
            
            let totalTime = Date().timeIntervalSince(startTime)
            Logger.recycleBin.info("批量删除全部完成！共删除 \(itemsToDelete.count) 个项目，总耗时: \(String(format: "%.2f", totalTime))秒")
            
            // 发送批量删除完成通知
            self.sendBatchPermanentDeleteNotification(count: itemsToDelete.count)
            
        } catch {
            Logger.logError(error, context: "批量永久删除失败，已删除项目数: \(itemsToDelete.count - self.items.count)")
            
            // 发送错误通知
            self.sendDeleteErrorNotification()
        }
    }
    
    func emptyRecycleBin() {
        Logger.recycleBin.info("清空回收站")
        
        self.items.removeAll()
        self.updateTotalSize()
        self.saveToUserDefaults()
    }
    
    // MARK: - Data Persistence
    
    private func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(self.items.map { RecycleBinItem(from: $0) })
            userDefaults.set(data, forKey: recycleKey)
        } catch {
            Logger.logError(error, context: "保存回收站数据")
        }
    }
    
    private func loadFromUserDefaults() {
        guard let data = userDefaults.data(forKey: recycleKey) else { return }
        
        do {
            let recycleBinItems = try JSONDecoder().decode([RecycleBinItem].self, from: data)
            self.items = recycleBinItems.compactMap { $0.toMediaItem() }
            self.updateTotalSize()
        } catch {
            Logger.logError(error, context: "加载回收站数据")
        }
    }
    
    private func updateTotalSize() {
        totalDeletedSize = self.items.reduce(0) { $0 + $1.size }
    }
    
    // MARK: - Notifications
    
    private func sendDeleteNotification(fileName: String) {
        let content = UNMutableNotificationContent()
        content.title = "文件已删除"
        content.body = "\(fileName) 已移至回收站"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendBatchDeleteNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "批量删除完成"
        content.body = "已将 \(count) 个文件移至回收站"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendBatchPermanentDeleteNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "批量永久删除完成"
        content.body = "已永久删除 \(count) 个文件"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendDeleteErrorNotification() {
        let content = UNMutableNotificationContent()
        content.title = "删除失败"
        content.body = "批量删除过程中发生错误"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Computed Properties
    
    var itemCount: Int {
        self.items.count
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalDeletedSize, countStyle: .file)
    }
    
    var isEmpty: Bool {
        self.items.isEmpty
    }
    
    func getItemsByType(_ type: MediaItem.MediaType) -> [MediaItem] {
        self.items.filter { $0.mediaType == type }
    }
    
    func getOldestItems(limit: Int = 10) -> [MediaItem] {
        self.items.sorted { $0.deletedDate ?? Date() < $1.deletedDate ?? Date() }
              .prefix(limit)
              .map { $0 }
    }
}

// MARK: - Serializable RecycleBin Item

private struct RecycleBinItem: Codable {
    let id: String
    let fileName: String
    let size: Int64
    let creationDate: Date
    let deletedDate: Date?
    let mediaType: String
    let isDuplicate: Bool
    let similarityScore: Double
    let localIdentifier: String?
    let fileURLString: String?
    
    init(from mediaItem: MediaItem) {
        self.id = mediaItem.id.uuidString
        self.fileName = mediaItem.fileName
        self.size = mediaItem.size
        self.creationDate = mediaItem.creationDate
        self.deletedDate = mediaItem.deletedDate
        self.mediaType = mediaItem.mediaType.rawValue
        self.isDuplicate = mediaItem.isDuplicate
        self.similarityScore = mediaItem.similarityScore
        self.localIdentifier = mediaItem.asset?.localIdentifier
        self.fileURLString = mediaItem.fileURL?.absoluteString
    }
    
    func toMediaItem() -> MediaItem? {
        // 注意：这里只是简化的恢复逻辑，实际项目中需要更复杂的处理
        // 因为PHAsset不能直接从localIdentifier恢复
        return nil
    }
} 