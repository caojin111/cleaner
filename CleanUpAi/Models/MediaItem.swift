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
    let id: UUID
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
        self.id = UUID() // 确保id在初始化时生成
        self.asset = asset
        self.fileURL = nil
        self.contentType = nil
        
        // 使用更合理的文件大小估算
        // 对于照片：假设JPEG压缩，每个像素约2-4字节
        // 对于视频：基于分辨率和时长估算
        var estimatedSize: Int64
        if asset.mediaType == .video {
            // 视频大小估算：分辨率 × 时长 × 比特率系数
            let duration = asset.duration
            let pixels = asset.pixelWidth * asset.pixelHeight
            let bitrateFactor = 0.1 // 假设平均比特率约为分辨率的10%
            estimatedSize = Int64(Double(pixels) * duration * bitrateFactor)
        } else {
            // 照片大小估算：基于分辨率和压缩率
            let pixels = asset.pixelWidth * asset.pixelHeight
            let compressionFactor = 0.3 // 假设JPEG压缩率约为30%
            estimatedSize = Int64(Double(pixels) * 3.0 * compressionFactor) // 3字节/像素 × 压缩率
        }
        self.size = estimatedSize
        
        self.creationDate = asset.creationDate ?? Date()
        self.fileName = "IMG_\(asset.localIdentifier.prefix(8))"
        self.mediaType = asset.mediaType == .video ? .video : .photo
        self.isDuplicate = isDuplicate
        self.similarityScore = similarityScore
    }
    
    // 从文件URL创建（音频/文档）
    init(fileURL: URL, contentType: UTType, isDuplicate: Bool = false) {
        self.id = UUID() // 确保id在初始化时生成
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
    
    // 从保存的数据恢复（用于回收站）
    init(id: UUID, fileName: String, size: Int64, creationDate: Date, mediaType: MediaType, 
         isDuplicate: Bool, similarityScore: Double, asset: PHAsset? = nil, fileURL: URL? = nil, 
         contentType: UTType? = nil, isInRecycleBin: Bool = false, deletedDate: Date? = nil) {
        self.id = id
        self.asset = asset
        self.fileURL = fileURL
        self.contentType = contentType
        self.size = size
        self.creationDate = creationDate
        self.fileName = fileName
        self.mediaType = mediaType
        self.isDuplicate = isDuplicate
        self.similarityScore = similarityScore
        self.isInRecycleBin = isInRecycleBin
        self.deletedDate = deletedDate
    }
    
    // MARK: - Computed Properties
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
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
    let id: UUID
    let title: String
    let price: String
    let originalPrice: String? // 原价（用于显示折扣）
    let duration: String
    let features: [String]
    let isRecommended: Bool
    let productIdentifier: String
    let trialDays: Int?
    
    static func getPlans() -> [SubscriptionPlan] {
        return [
            SubscriptionPlan(
                id: UUID(),
                title: "paywall.plan.yearly".localized,
                price: "$29.99", // 默认价格，会在UI层更新
                originalPrice: nil, // 可以根据需要设置原价
                duration: "paywall.plan.yearly_unit".localized,
                features: ["无限制清理重复文件", "无限制文件分析", "优先客户支持", "高级清理算法"],
                isRecommended: true,
                productIdentifier: "yearly_29.99",
                trialDays: 7
            ),
            SubscriptionPlan(
                id: UUID(),
                title: "paywall.plan.monthly".localized,
                price: "$9.99", // 默认价格，会在UI层更新
                originalPrice: nil,
                duration: "paywall.plan.monthly_unit".localized,
                features: ["无限制清理重复文件", "无限制文件分析", "基础客户支持"],
                isRecommended: false,
                productIdentifier: "monthly_9.99",
                trialDays: nil
            ),
            SubscriptionPlan(
                id: UUID(),
                title: "paywall.plan.weekly".localized,
                price: "$2.99", // 默认价格，会在UI层更新
                originalPrice: nil,
                duration: "paywall.plan.weekly_unit".localized,
                features: ["无限制清理重复文件", "有限文件分析"],
                isRecommended: false,
                productIdentifier: "weekly_2.99",
                trialDays: nil
            )
        ]
    }
    
    static var plans: [SubscriptionPlan] {
        return getPlans()
    }
} 
