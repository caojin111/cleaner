//
//  PhotoAnalyzer.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import Foundation
import Photos
import SwiftUI
import OSLog

@MainActor
class PhotoAnalyzer: ObservableObject {
    static let shared = PhotoAnalyzer()
    
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var foundDuplicates: [MediaItem] = []
    @Published var allPhotos: [MediaItem] = []
    @Published var photoCount: Int = 0
    
    private init() {}
    
    // MARK: - Main Analysis Functions
    
    func startAnalysis() async {
        Logger.logPageNavigation(from: "权限页", to: "分析开始")
        
        let startTime = Date()
        isAnalyzing = true
        analysisProgress = 0.0
        foundDuplicates.removeAll()
        allPhotos.removeAll()
        
        // 1. 获取所有照片和视频
        let assets = await fetchAllAssets()
        photoCount = assets.count
        Logger.logFileAnalysisStart(count: photoCount)
        
        // 2. 创建MediaItem对象
        let mediaItems = await createMediaItems(from: assets)
        allPhotos = mediaItems
        analysisProgress = 0.3
        
        // 3. 分析重复项
        let duplicates = await findDuplicates(in: mediaItems)
        foundDuplicates = duplicates
        analysisProgress = 0.8
        
        // 4. 按相似度排序
        foundDuplicates.sort { $0.similarityScore > $1.similarityScore }
        analysisProgress = 1.0
        
        let totalTime = Date().timeIntervalSince(startTime)
        Logger.photoAnalyzer.info("分析完成！总耗时: \(String(format: "%.2f", totalTime))秒")
        Logger.photoAnalyzer.info("性能统计: \(self.photoCount)张照片，发现\(duplicates.count)个重复，平均每张耗时\(String(format: "%.3f", totalTime / Double(self.photoCount)))秒")
        
        Logger.logFileAnalysisComplete(duplicates: duplicates.count)
        
        isAnalyzing = false
    }
    
    func getPhotoCount() async -> Int {
        let assets = await fetchAllAssets()
        photoCount = assets.count
        return photoCount
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchAllAssets() async -> [PHAsset] {
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let assetsFetchResult = PHAsset.fetchAssets(with: fetchOptions)
            var assets: [PHAsset] = []
            
            assetsFetchResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
            
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
        
        return mediaItems
    }
    
    private func findDuplicates(in mediaItems: [MediaItem]) async -> [MediaItem] {
        Logger.photoAnalyzer.info("开始优化分析，总照片数: \(mediaItems.count)")
        
        // 1. 按媒体类型分组
        let photos = mediaItems.filter { $0.mediaType == .photo }
        let videos = mediaItems.filter { $0.mediaType == .video }
        
        Logger.photoAnalyzer.info("分组完成 - 照片: \(photos.count), 视频: \(videos.count)")
        
        // 2. 并行处理照片和视频
        async let photoDuplicates = findDuplicatesInGroup(photos, groupName: "照片")
        async let videoDuplicates = findDuplicatesInGroup(videos, groupName: "视频")
        
        // 3. 等待所有结果
        let (photoResults, videoResults) = await (photoDuplicates, videoDuplicates)
        
        // 4. 合并结果
        let allDuplicates = photoResults + videoResults
        
        Logger.photoAnalyzer.info("分析完成，发现 \(allDuplicates.count) 个重复文件")
        return allDuplicates
    }
    
    private func findDuplicatesInGroup(_ items: [MediaItem], groupName: String) async -> [MediaItem] {
        guard items.count > 1 else { return [] }
        
        var duplicates: [MediaItem] = []
        let totalCount = items.count
        var processedCount = 0
        
        Logger.photoAnalyzer.info("开始分析\(groupName)组，数量: \(items.count)")
        
        // 根据数量调整批次大小
        let batchSize = max(1, min(items.count / 4, 50)) // 最多50个一批，避免内存占用过大
        
        // 使用TaskGroup进行并行处理
        await withTaskGroup(of: [MediaItem].self) { group in
            for batchStart in stride(from: 0, to: items.count, by: batchSize) {
                let batchEnd = min(batchStart + batchSize, items.count)
                let batchItems = Array(items[batchStart..<batchEnd])
                
                group.addTask {
                    return await self.processBatch(batchItems, allItems: items, groupName: groupName)
                }
            }
            
            // 收集所有批次的结果
            for await batchDuplicates in group {
                duplicates.append(contentsOf: batchDuplicates)
                processedCount += batchSize
                
                // 更新进度
                let progress = 0.3 + (Double(processedCount) / Double(totalCount)) * 0.5
                await MainActor.run {
                    analysisProgress = progress
                }
            }
        }
        
        // 去重
        let uniqueDuplicates = removeDuplicateItems(duplicates)
        Logger.photoAnalyzer.info("\(groupName)组分析完成，发现 \(uniqueDuplicates.count) 个重复")
        
        return uniqueDuplicates
    }
    
    // 去重方法，避免使用Set（因为MediaItem的Hashable可能有问题）
    private func removeDuplicateItems(_ items: [MediaItem]) -> [MediaItem] {
        var uniqueItems: [MediaItem] = []
        var seenIds: Set<UUID> = []
        
        for item in items {
            if !seenIds.contains(item.id) {
                seenIds.insert(item.id)
                uniqueItems.append(item)
            }
        }
        
        return uniqueItems
    }
    
    private func processBatch(_ batchItems: [MediaItem], allItems: [MediaItem], groupName: String) async -> [MediaItem] {
        var batchDuplicates: [MediaItem] = []
        
        for currentItem in batchItems {
            // 只与当前项目之后的项目比较，避免重复比较
            if let currentIndex = allItems.firstIndex(where: { $0.id == currentItem.id }) {
                for j in (currentIndex + 1)..<allItems.count {
                    let compareItem = allItems[j]
                    
                    // 快速预筛选，减少不必要的详细计算
                    if await quickPreFilter(currentItem, compareItem) {
                        let similarity = await calculatePhotoSimilarity(currentItem, compareItem)
                        
                        if similarity > 0.85 { // 85% 相似度阈值
                            // 标记较小的文件为重复项
                            let duplicateItem = currentItem.size < compareItem.size ? currentItem : compareItem
                            if let asset = duplicateItem.asset {
                                let markedItem = MediaItem(
                                    asset: asset,
                                    isDuplicate: true,
                                    similarityScore: similarity
                                )
                                batchDuplicates.append(markedItem)
                                Logger.photoAnalyzer.debug("发现重复\(groupName): \(markedItem.fileName), 相似度: \(String(format: "%.1f", similarity * 100))%")
                            }
                        }
                    }
                }
            }
        }
        
        return batchDuplicates
    }
    
    // 快速预筛选，减少不必要的详细计算
    private func quickPreFilter(_ item1: MediaItem, _ item2: MediaItem) async -> Bool {
        guard let asset1 = item1.asset, let asset2 = item2.asset else { return false }
        
        // 1. 媒体类型必须相同
        if asset1.mediaType != asset2.mediaType { return false }
        
        // 2. 文件大小差异不能太大（超过50%）
        let sizeDiff = abs(item1.size - item2.size)
        let maxSize = max(item1.size, item2.size)
        if maxSize > 0 && (Double(sizeDiff) / Double(maxSize)) > 0.5 { return false }
        
        // 3. 创建时间不能相差太远（超过1小时）
        let timeDiff = abs(item1.creationDate.timeIntervalSince(item2.creationDate))
        if timeDiff > 3600 { return false }
        
        return true
    }
    
    private func calculatePhotoSimilarity(_ item1: MediaItem, _ item2: MediaItem) async -> Double {
        // 基础相似性检查：分辨率、文件大小、创建时间
        guard let asset1 = item1.asset, let asset2 = item2.asset else {
            return 0.0
        }
        
        var similarity: Double = 0.0
        
        // 1. 分辨率相似性 (25%) - 降低权重
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
            
            // 额外检查分辨率差异
            let resolution1 = width1 * height1
            let resolution2 = width2 * height2
            let resolutionDiff = abs(Double(resolution1 - resolution2)) / Double(max(resolution1, resolution2))
            let resolutionSimilarity = max(0, 1.0 - resolutionDiff)
            similarity += resolutionSimilarity * 0.05
        }
        
        // 2. 文件大小相似性 (35%) - 增加权重
        let sizeDiff = abs(item1.size - item2.size)
        let maxSize = max(item1.size, item2.size)
        if maxSize > 0 {
            let sizeSimilarity = max(0, 1.0 - (Double(sizeDiff) / Double(maxSize)))
            similarity += sizeSimilarity * 0.35
        }
        
        // 3. 创建时间相似性 (20%) - 增加权重和时间阈值
        let timeDiff = abs(item1.creationDate.timeIntervalSince(item2.creationDate))
        let timeThreshold: TimeInterval = 300 // 5分钟
        let timeSimilarity = max(0, 1.0 - (timeDiff / timeThreshold))
        similarity += timeSimilarity * 0.20
        
        // 4. 媒体类型匹配 (10%)
        if asset1.mediaType == asset2.mediaType {
            similarity += 0.1
        }
        
        // 5. 如果是视频，还要考虑时长相似性
        if asset1.mediaType == .video && asset2.mediaType == .video {
            let duration1 = asset1.duration
            let duration2 = asset2.duration
            if duration1 > 0 && duration2 > 0 {
                let durationDiff = abs(duration1 - duration2)
                let maxDuration = max(duration1, duration2)
                let durationSimilarity = max(0, 1.0 - (durationDiff / maxDuration))
                similarity += durationSimilarity * 0.05
            }
        }
        
        // 确保相似度在0-1之间
        let finalSimilarity = min(1.0, max(0.0, similarity))
        
        // 添加随机系数，让相似度在50%-100%之间浮动
        let randomFactor = Double.random(in: 0.5...1.0)
        let adjustedSimilarity = finalSimilarity * randomFactor
        
        // 记录详细的相似度计算日志
        Logger.photoAnalyzer.debug("照片相似度计算: \(item1.fileName) vs \(item2.fileName) = \(String(format: "%.1f", adjustedSimilarity * 100))% (原始: \(String(format: "%.1f", finalSimilarity * 100))%, 随机系数: \(String(format: "%.2f", randomFactor)))")
        
        return adjustedSimilarity
    }
    
    // MARK: - Public Helper Methods
    
    func getRecommendedItemsForDeletion(limit: Int = 50) -> [MediaItem] {
        // 优先推荐重复度高的项目
        let sortedDuplicates = foundDuplicates
            .filter { !$0.isMarkedForKeeping }
            .sorted { $0.similarityScore > $1.similarityScore }
        
        return Array(sortedDuplicates.prefix(limit))
    }
    
    func estimatedSpaceSavings() -> Int64 {
        return foundDuplicates.reduce(0) { $0 + $1.size }
    }
    
    func markItemForKeeping(_ item: MediaItem) {
        if let index = foundDuplicates.firstIndex(where: { $0.id == item.id }) {
            foundDuplicates[index] = MediaItem(
                asset: item.asset!,
                isDuplicate: item.isDuplicate,
                similarityScore: item.similarityScore
            )
        }
    }
    
    // MARK: - Debug Methods
    
    /// 获取照片的详细信息，用于调试相似度计算
    func getPhotoDetails(for item: MediaItem) -> String {
        guard let asset = item.asset else { return "无法获取照片信息" }
        
        let details = """
        文件名: \(item.fileName)
        分辨率: \(asset.pixelWidth) x \(asset.pixelHeight)
        文件大小: \(item.formattedSize)
        创建时间: \(item.formattedDate)
        媒体类型: \(item.mediaType.displayName)
        相似度: \(String(format: "%.1f", item.similarityScore * 100))%
        """
        
        if asset.mediaType == .video {
            let minutes = Int(asset.duration) / 60
            let seconds = Int(asset.duration) % 60
            let duration = String(format: "%d:%02d", minutes, seconds)
            return details + "\n视频时长: \(duration)"
        }
        
        return details
    }
    
    /// 分析两个照片的相似度详情
    func analyzeSimilarityDetails(between item1: MediaItem, and item2: MediaItem) async -> String {
        guard let asset1 = item1.asset, let asset2 = item2.asset else {
            return "无法获取照片信息"
        }
        
        let similarity = await calculatePhotoSimilarity(item1, item2)
        
        // 计算各项指标的相似度
        let width1 = asset1.pixelWidth
        let height1 = asset1.pixelHeight
        let width2 = asset2.pixelWidth
        let height2 = asset2.pixelHeight
        
        let aspectRatio1 = Double(width1) / Double(height1)
        let aspectRatio2 = Double(width2) / Double(height2)
        let aspectDiff = abs(aspectRatio1 - aspectRatio2)
        let aspectSimilarity = max(0, 1.0 - aspectDiff)
        
        let sizeDiff = abs(item1.size - item2.size)
        let maxSize = max(item1.size, item2.size)
        let sizeSimilarity = max(0, 1.0 - (Double(sizeDiff) / Double(maxSize)))
        
        let timeDiff = abs(item1.creationDate.timeIntervalSince(item2.creationDate))
        let timeSimilarity = max(0, 1.0 - (timeDiff / 60))
        
        let details = """
        相似度分析结果: \(String(format: "%.1f", similarity * 100))%
        
        详细对比:
        1. 分辨率相似度: \(String(format: "%.1f", aspectSimilarity * 100))%
           - \(item1.fileName): \(width1) x \(height1)
           - \(item2.fileName): \(width2) x \(height2)
        
        2. 文件大小相似度: \(String(format: "%.1f", sizeSimilarity * 100))%
           - \(item1.fileName): \(item1.formattedSize)
           - \(item2.fileName): \(item2.formattedSize)
        
        3. 时间相似度: \(String(format: "%.1f", timeSimilarity * 100))%
           - 时间差: \(String(format: "%.0f", timeDiff))秒
        """
        
        return details
    }
} 