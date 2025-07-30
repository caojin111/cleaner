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
        Logger.recycleBin.info("RecycleBinManager 初始化开始")
        loadFromUserDefaults()
        Logger.recycleBin.info("RecycleBinManager 初始化完成，当前项目数: \(self.items.count)")
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
        
        // 移除推送通知 - 用户要求去掉删除时的推送
        // self.sendDeleteNotification(fileName: item.fileName)
        Logger.recycleBin.info("文件已移至回收站: \(item.fileName) (推送通知已禁用)")
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
        
        // 移除推送通知 - 用户要求去掉删除时的推送
        // self.sendBatchDeleteNotification(count: self.items.count)
        Logger.recycleBin.info("批量文件已移至回收站: \(items.count) 个文件 (推送通知已禁用)")
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
            
            // 移除推送通知 - 用户要求去掉删除时的推送
            // self.sendBatchPermanentDeleteNotification(count: itemsToDelete.count)
            Logger.recycleBin.info("批量永久删除完成: \(itemsToDelete.count) 个文件 (推送通知已禁用)")
            
        } catch {
            Logger.logError(error, context: "批量永久删除失败，已删除项目数: \(itemsToDelete.count - self.items.count)")
            
            // 移除推送通知 - 用户要求去掉删除时的推送
            // self.sendDeleteErrorNotification()
            Logger.recycleBin.error("批量删除过程中发生错误 (推送通知已禁用)")
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
        Logger.recycleBin.info("开始保存回收站数据，项目数量: \(self.items.count)")
        do {
            let data = try JSONEncoder().encode(self.items.map { RecycleBinItem(from: $0) })
            userDefaults.set(data, forKey: recycleKey)
            Logger.recycleBin.info("成功保存回收站数据，大小: \(data.count) bytes")
        } catch {
            Logger.logError(error, context: "保存回收站数据")
        }
    }
    
    private func loadFromUserDefaults() {
        Logger.recycleBin.info("开始加载回收站数据")
        guard let data = userDefaults.data(forKey: recycleKey) else {
            Logger.recycleBin.info("UserDefaults中没有找到回收站数据")
            return
        }
        
        Logger.recycleBin.info("找到回收站数据，大小: \(data.count) bytes")
        do {
            let recycleBinItems = try JSONDecoder().decode([RecycleBinItem].self, from: data)
            Logger.recycleBin.info("成功解码 \(recycleBinItems.count) 个回收站项目")
            
            self.items = recycleBinItems.compactMap { $0.toMediaItem() }
            Logger.recycleBin.info("成功恢复 \(self.items.count) 个MediaItem")
            
            self.updateTotalSize()
            Logger.recycleBin.info("回收站数据加载完成，总大小: \(self.formattedTotalSize)")
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
        // 解析UUID
        guard let itemId = UUID(uuidString: id) else {
            Logger.recycleBin.error("无效的UUID: \(id)")
            return nil
        }
        
        // 解析媒体类型
        guard let mediaType = MediaItem.MediaType(rawValue: mediaType) else {
            Logger.recycleBin.error("无效的媒体类型: \(mediaType)")
            return nil
        }
        
        // 尝试恢复PHAsset
        var recoveredAsset: PHAsset? = nil
        if let localIdentifier = localIdentifier, !localIdentifier.isEmpty {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
            if let asset = fetchResult.firstObject {
                recoveredAsset = asset
                Logger.recycleBin.info("成功恢复PHAsset: \(fileName)")
            } else {
                Logger.recycleBin.warning("无法恢复PHAsset，localIdentifier: \(localIdentifier)")
            }
        }
        
        // 尝试恢复文件URL
        var recoveredFileURL: URL? = nil
        var recoveredContentType: UTType? = nil
        if let fileURLString = fileURLString, let fileURL = URL(string: fileURLString) {
            // 检查文件是否仍然存在
            if FileManager.default.fileExists(atPath: fileURL.path) {
                recoveredFileURL = fileURL
                recoveredContentType = UTType(filenameExtension: fileURL.pathExtension) ?? .data
                Logger.recycleBin.info("成功恢复文件URL: \(fileName)")
            } else {
                Logger.recycleBin.warning("文件不存在: \(fileURL.path)")
            }
        }
        
        // 创建MediaItem
        let mediaItem = MediaItem(
            id: itemId,
            fileName: fileName,
            size: size,
            creationDate: creationDate,
            mediaType: mediaType,
            isDuplicate: isDuplicate,
            similarityScore: similarityScore,
            asset: recoveredAsset,
            fileURL: recoveredFileURL,
            contentType: recoveredContentType,
            isInRecycleBin: true,
            deletedDate: deletedDate
        )
        
        Logger.recycleBin.info("成功恢复回收站项目: \(fileName)")
        return mediaItem
    }
} 