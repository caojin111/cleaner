//
//  VideoAnalyzer.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import Foundation
import Photos
import SwiftUI
import OSLog
import AVFoundation

@MainActor
class VideoAnalyzer: ObservableObject {
    static let shared = VideoAnalyzer()
    
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var foundDuplicates: [MediaItem] = []
    @Published var allVideos: [MediaItem] = []
    @Published var videoCount: Int = 0
    
    private var keptItems: Set<String> = []
    
    // 视频缩略图缓存
    private var thumbnailCache: [String: UIImage] = [:]
    private var durationCache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "video.cache", qos: .utility)
    
    private init() {}
    
    // MARK: - Main Analysis Functions
    
    func startAnalysis() async {
        Logger.logPageNavigation(from: "视频页", to: "视频分析开始")
        
        isAnalyzing = true
        analysisProgress = 0.0
        foundDuplicates.removeAll()
        allVideos.removeAll()
        keptItems.removeAll()
        
        // 1. 获取所有视频
        let assets = await fetchAllVideoAssets()
        videoCount = assets.count
        Logger.logFileAnalysisStart(count: videoCount)
        
        // 2. 创建MediaItem对象
        let mediaItems = await createMediaItems(from: assets)
        allVideos = mediaItems
        analysisProgress = 0.3
        
        // 3. 分析重复项
        let duplicates = await findDuplicates(in: mediaItems)
        foundDuplicates = duplicates
        analysisProgress = 0.8
        
        // 4. 按文件大小排序（大文件优先删除）
        foundDuplicates.sort { $0.size > $1.size }
        analysisProgress = 1.0
        
        await Task.sleep(500_000_000) // 0.5秒延迟，让用户看到完成状态
        isAnalyzing = false
        
        // 5. 开始预缓存所有视频缩略图
        await startThumbnailPreCache()
        
        Logger.logFileAnalysisComplete(duplicates: foundDuplicates.count)
    }
    
    func quickAnalysis() async {
        await startAnalysis()
    }
    
    // MARK: - Asset Fetching
    
    private func fetchAllVideoAssets() async -> [PHAsset] {
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let assetsFetchResult = PHAsset.fetchAssets(with: fetchOptions)
            var assets: [PHAsset] = []
            
            assetsFetchResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
            
            Logger.video.info("获取到 \(assets.count) 个视频文件")
            continuation.resume(returning: assets)
        }
    }
    
    private func createMediaItems(from assets: [PHAsset]) async -> [MediaItem] {
        var mediaItems: [MediaItem] = []
        let totalCount = assets.count
        
        for (index, asset) in assets.enumerated() {
            let mediaItem = MediaItem(asset: asset)
            mediaItems.append(mediaItem)
            
            // 更新进度
            let progress = 0.1 + (Double(index) / Double(totalCount)) * 0.2
            await MainActor.run {
                analysisProgress = progress
            }
        }
        
        Logger.video.info("创建了 \(mediaItems.count) 个视频媒体项目")
        return mediaItems
    }
    
    // MARK: - Duplicate Detection
    
    private func findDuplicates(in items: [MediaItem]) async -> [MediaItem] {
        var duplicates: [MediaItem] = []
        let totalCount = items.count
        
        for i in 0..<items.count {
            let currentItem = items[i]
            
            // 更新进度
            let progress = 0.3 + (Double(i) / Double(totalCount)) * 0.5
            await MainActor.run {
                analysisProgress = progress
            }
            
            // 检查与其他视频的相似性
            for j in (i+1)..<items.count {
                let compareItem = items[j]
                
                let similarity = await calculateVideoSimilarity(currentItem, compareItem)
                
                if similarity > 0.8 { // 80% 相似度阈值
                    // 标记较小的文件为重复项
                    let duplicateItem = currentItem.size < compareItem.size ? currentItem : compareItem
                    var markedItem = duplicateItem
                    if let asset = duplicateItem.asset {
                        markedItem = MediaItem(
                            asset: asset,
                            isDuplicate: true,
                            similarityScore: similarity
                        )
                        if !duplicates.contains(where: { $0.id == markedItem.id }) {
                            duplicates.append(markedItem)
                            Logger.video.debug("发现重复视频: \(markedItem.fileName), 相似度: \(similarity)")
                        }
                    }
                }
            }
        }
        
        Logger.video.info("发现 \(duplicates.count) 个重复视频")
        return duplicates
    }
    
    private func calculateVideoSimilarity(_ item1: MediaItem, _ item2: MediaItem) async -> Double {
        // 基础相似性检查：文件大小、时长、分辨率
        guard let asset1 = item1.asset, let asset2 = item2.asset else {
            return 0.0
        }
        
        var similarity: Double = 0.0
        
        // 1. 时长相似性 (35%) - 降低权重
        let duration1 = asset1.duration
        let duration2 = asset2.duration
        if duration1 > 0 && duration2 > 0 {
            let durationDiff = abs(duration1 - duration2)
            let maxDuration = max(duration1, duration2)
            let durationSimilarity = max(0, 1.0 - (durationDiff / maxDuration))
            similarity += durationSimilarity * 0.35
        }
        
        // 2. 分辨率相似性 (25%) - 降低权重
        let width1 = asset1.pixelWidth
        let height1 = asset1.pixelHeight
        let width2 = asset2.pixelWidth
        let height2 = asset2.pixelHeight
        
        if width1 > 0 && height1 > 0 && width2 > 0 && height2 > 0 {
            let aspectRatio1 = Double(width1) / Double(height1)
            let aspectRatio2 = Double(width2) / Double(height2)
            let aspectDiff = abs(aspectRatio1 - aspectRatio2)
            let aspectSimilarity = max(0, 1.0 - aspectDiff)
            similarity += aspectSimilarity * 0.25
        }
        
        // 3. 文件大小相似性 (25%) - 增加权重
        let sizeDiff = abs(item1.size - item2.size)
        let maxSize = max(item1.size, item2.size)
        if maxSize > 0 {
            let sizeSimilarity = max(0, 1.0 - (Double(sizeDiff) / Double(maxSize)))
            similarity += sizeSimilarity * 0.25
        }
        
        // 4. 创建时间相似性 (15%) - 增加权重
        let timeDiff = abs(item1.creationDate.timeIntervalSince(item2.creationDate))
        let timeThreshold: TimeInterval = 1800 // 30分钟
        let timeSimilarity = max(0, 1.0 - (timeDiff / timeThreshold))
        similarity += timeSimilarity * 0.15
        
        // 确保相似度在0-1之间
        let finalSimilarity = min(1.0, similarity)
        
        // 添加随机系数，让相似度在50%-100%之间浮动
        let randomFactor = Double.random(in: 0.5...1.0)
        let adjustedSimilarity = finalSimilarity * randomFactor
        
        // 记录详细的相似度计算日志
        Logger.video.debug("视频相似度计算: \(item1.fileName) vs \(item2.fileName) = \(String(format: "%.1f", adjustedSimilarity * 100))% (原始: \(String(format: "%.1f", finalSimilarity * 100))%, 随机系数: \(String(format: "%.2f", randomFactor)))")
        
        return adjustedSimilarity
    }
    
    // MARK: - Item Management
    
    func markItemForKeeping(_ item: MediaItem) {
        keptItems.insert(item.id.uuidString)
        foundDuplicates.removeAll { $0.id == item.id }
        Logger.video.info("标记保留视频: \(item.fileName)")
    }
    
    func isItemMarkedForKeeping(_ item: MediaItem) -> Bool {
        return keptItems.contains(item.id.uuidString)
    }
    
    // MARK: - Storage Calculation
    
    func estimatedSpaceSavings() -> Int64 {
        return foundDuplicates.reduce(0) { $0 + $1.size }
    }
    
    // MARK: - Reset
    
    func reset() {
        isAnalyzing = false
        analysisProgress = 0.0
        foundDuplicates.removeAll()
        allVideos.removeAll()
        keptItems.removeAll()
        videoCount = 0
        clearThumbnailCache()
        Logger.video.info("重置视频分析器")
    }
    
    // MARK: - Thumbnail Cache Management
    
    private func startThumbnailPreCache() async {
        Logger.video.info("开始预缓存 \(self.foundDuplicates.count) 个视频缩略图")
        
        // 使用TaskGroup并发加载缩略图
        await withTaskGroup(of: Void.self) { group in
            for item in self.foundDuplicates {
                group.addTask {
                    await self.preloadThumbnail(for: item)
                }
            }
        }
        
        Logger.video.info("预缓存完成: \(self.thumbnailCache.count) 个缩略图")
    }
    
    private func preloadThumbnail(for item: MediaItem) async {
        guard let asset = item.asset else { return }
        
        let cacheKey = asset.localIdentifier
        guard !cacheKey.isEmpty else { return }
        
        // 检查是否已经缓存
        let shouldLoad = cacheQueue.sync {
            return self.thumbnailCache[cacheKey] == nil
        }
        
        if !shouldLoad {
            return
        }
        
        await withCheckedContinuation { continuation in
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .exact
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.isSynchronous = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 280, height: 320),
                contentMode: .aspectFill,
                options: requestOptions
            ) { [weak self] image, info in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if let image = image {
                    self.cacheQueue.async {
                        self.thumbnailCache[cacheKey] = image
                        
                        // 同时缓存视频时长
                        let duration = asset.duration
                        if duration > 0 {
                            let minutes = Int(duration) / 60
                            let seconds = Int(duration) % 60
                            self.durationCache[cacheKey] = String(format: "%d:%02d", minutes, seconds)
                        }
                        
                        Logger.video.debug("预缓存视频缩略图: \(item.fileName)")
                    }
                }
                continuation.resume()
            }
        }
    }
    
    // 获取缓存的缩略图
    func getCachedThumbnail(for asset: PHAsset) -> UIImage? {
        let identifier = asset.localIdentifier
        guard !identifier.isEmpty else { return nil }
        
        return cacheQueue.sync {
            return self.thumbnailCache[identifier]
        }
    }
    
    // 获取缓存的视频时长
    func getCachedDuration(for asset: PHAsset) -> String? {
        let identifier = asset.localIdentifier
        guard !identifier.isEmpty else { return nil }
        
        return cacheQueue.sync {
            return self.durationCache[identifier]
        }
    }
    
    // 清理缓存
    func clearThumbnailCache() {
        cacheQueue.async {
            self.thumbnailCache.removeAll()
            self.durationCache.removeAll()
            Logger.video.info("清理视频缩略图缓存")
        }
    }
    
    // 获取缓存状态
    func getCacheStatus() -> (thumbnails: Int, durations: Int) {
        return cacheQueue.sync {
            return (self.thumbnailCache.count, self.durationCache.count)
        }
    }
} 