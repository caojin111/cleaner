//
//  MediaItem.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import Foundation
import Photos
import UniformTypeIdentifiers

// MARK: - Media Item Model
struct MediaItem: Identifiable, Hashable {
    let id = UUID()
    let asset: PHAsset?
    let fileURL: URL?
    let contentType: UTType?
    let size: Int64
    let creationDate: Date
    let fileName: String
    let mediaType: MediaType
    let isDuplicate: Bool
    let similarityScore: Double
    var isInRecycleBin: Bool = false
    var deletedDate: Date?
    var isMarkedForKeeping: Bool = false
    
    enum MediaType: String, CaseIterable {
        case photo = "photo"
        case video = "video" 
        case audio = "audio"
        case document = "document"
        
        var displayName: String {
            switch self {
            case .photo: return "照片"
            case .video: return "视频"
            case .audio: return "音频"
            case .document: return "文档"
            }
        }
        
        var systemImageName: String {
            switch self {
            case .photo: return "photo"
            case .video: return "video"
            case .audio: return "music.note"
            case .document: return "doc"
            }
        }
    }
    
    // MARK: - Initializers
    
    // 从PHAsset创建（照片/视频）
    init(asset: PHAsset, isDuplicate: Bool = false, similarityScore: Double = 0.0) {
        self.asset = asset
        self.fileURL = nil
        self.contentType = nil
        self.size = Int64(asset.pixelWidth * asset.pixelHeight * 4) // 估算大小
        self.creationDate = asset.creationDate ?? Date()
        self.fileName = "IMG_\(asset.localIdentifier.prefix(8))"
        self.mediaType = asset.mediaType == .video ? .video : .photo
        self.isDuplicate = isDuplicate
        self.similarityScore = similarityScore
    }
    
    // 从文件URL创建（音频/文档）
    init(fileURL: URL, contentType: UTType, isDuplicate: Bool = false) {
        self.asset = nil
        self.fileURL = fileURL
        self.contentType = contentType
        self.fileName = fileURL.lastPathComponent
        self.creationDate = (try? fileURL.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
        
        // 获取文件大小
        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        self.size = Int64(fileSize)
        
        // 判断媒体类型
        if contentType.conforms(to: .audio) {
            self.mediaType = .audio
        } else if contentType.conforms(to: .movie) {
            self.mediaType = .video
        } else {
            self.mediaType = .document
        }
        
        self.isDuplicate = isDuplicate
        self.similarityScore = 0.0
    }
    
    // MARK: - Computed Properties
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: creationDate)
    }
    
    var thumbnailIdentifier: String {
        if let asset = asset {
            return asset.localIdentifier
        } else if let fileURL = fileURL {
            return fileURL.absoluteString
        } else {
            return id.uuidString
        }
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Storage Info Model
struct StorageInfo {
    let totalSpace: Int64
    let usedSpace: Int64
    let freeSpace: Int64
    let photosSpace: Int64
    let videosSpace: Int64
    let audioSpace: Int64
    let documentsSpace: Int64
    
    var usagePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }
    
    var formattedTotalSpace: String {
        ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
    }
    
    var formattedUsedSpace: String {
        ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
    }
    
    var formattedFreeSpace: String {
        ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
    }
}

// MARK: - Subscription Plan Model
struct SubscriptionPlan: Identifiable {
    let id = UUID()
    let title: String
    let price: String
    let originalPrice: String? // 原价（用于显示折扣）
    let duration: String
    let features: [String]
    let isRecommended: Bool
    let productIdentifier: String
    let trialDays: Int?
    
    static let plans: [SubscriptionPlan] = [
        SubscriptionPlan(
            title: "年度订阅",
            price: Constants.Subscription.yearlyPrice,
            originalPrice: Constants.Subscription.yearlyOriginalPrice,
            duration: "年",
            features: ["无限制清理重复文件", "无限制文件分析", "优先客户支持", "高级清理算法"],
            isRecommended: true,
            productIdentifier: "com.cleanupai.yearly",
            trialDays: 7
        ),
        SubscriptionPlan(
            title: "月度订阅",
            price: Constants.Subscription.monthlyPrice,
            originalPrice: nil,
            duration: "月",
            features: ["无限制清理重复文件", "无限制文件分析", "基础客户支持"],
            isRecommended: false,
            productIdentifier: "com.cleanupai.monthly",
            trialDays: nil
        ),
        SubscriptionPlan(
            title: "周度订阅",
            price: Constants.Subscription.weeklyPrice,
            originalPrice: nil,
            duration: "周",
            features: ["无限制清理重复文件", "有限文件分析"],
            isRecommended: false,
            productIdentifier: "com.cleanupai.weekly",
            trialDays: nil
        )
    ]
} 
