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
        
        items.append(updatedItem)
        updateTotalSize()
        saveToUserDefaults()
        
        // 发送通知
        sendDeleteNotification(fileName: item.fileName)
    }
    
    func moveMultipleToRecycleBin(_ items: [MediaItem]) {
        for item in items {
            var updatedItem = item
            updatedItem.isInRecycleBin = true
            updatedItem.deletedDate = Date()
            self.items.append(updatedItem)
            
            Logger.logFileDelete(item.fileName)
        }
        
        updateTotalSize()
        saveToUserDefaults()
        
        // 发送批量删除通知
        sendBatchDeleteNotification(count: items.count)
    }
    
    func restore(_ item: MediaItem) {
        Logger.logFileRestore(item.fileName)
        
        items.removeAll { $0.id == item.id }
        updateTotalSize()
        saveToUserDefaults()
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
            items.removeAll { $0.id == item.id }
            updateTotalSize()
            saveToUserDefaults()
            
            Logger.recycleBin.info("项目已永久删除: \(item.fileName)")
        } catch {
            Logger.logError(error, context: "永久删除文件")
        }
    }
    
    func permanentlyDeleteAll() async {
        Logger.recycleBin.info("永久删除所有回收站项目")
        
        let itemsToDelete = items
        
        for item in itemsToDelete {
            await permanentlyDelete(item)
        }
        
        items.removeAll()
        updateTotalSize()
        saveToUserDefaults()
    }
    
    func emptyRecycleBin() {
        Logger.recycleBin.info("清空回收站")
        
        items.removeAll()
        updateTotalSize()
        saveToUserDefaults()
    }
    
    // MARK: - Data Persistence
    
    private func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(items.map { RecycleBinItem(from: $0) })
            userDefaults.set(data, forKey: recycleKey)
        } catch {
            Logger.logError(error, context: "保存回收站数据")
        }
    }
    
    private func loadFromUserDefaults() {
        guard let data = userDefaults.data(forKey: recycleKey) else { return }
        
        do {
            let recycleBinItems = try JSONDecoder().decode([RecycleBinItem].self, from: data)
            items = recycleBinItems.compactMap { $0.toMediaItem() }
            updateTotalSize()
        } catch {
            Logger.logError(error, context: "加载回收站数据")
        }
    }
    
    private func updateTotalSize() {
        totalDeletedSize = items.reduce(0) { $0 + $1.size }
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
    
    // MARK: - Computed Properties
    
    var itemCount: Int {
        items.count
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalDeletedSize, countStyle: .file)
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
    
    func getItemsByType(_ type: MediaItem.MediaType) -> [MediaItem] {
        items.filter { $0.mediaType == type }
    }
    
    func getOldestItems(limit: Int = 10) -> [MediaItem] {
        items.sorted { $0.deletedDate ?? Date() < $1.deletedDate ?? Date() }
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