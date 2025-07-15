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
        var duplicates: [MediaItem] = []
        var processedHashes: Set<String> = []
        let totalCount = mediaItems.count
        
        for (index, item) in mediaItems.enumerated() {
            // 生成简单的哈希（基于文件大小和创建日期）
            let hash = generateSimpleHash(for: item)
            
            if processedHashes.contains(hash) {
                // 发现重复项
                var duplicateItem = item
                duplicateItem = MediaItem(
                    asset: item.asset!,
                    isDuplicate: true,
                    similarityScore: calculateSimilarityScore(for: item)
                )
                duplicates.append(duplicateItem)
            } else {
                processedHashes.insert(hash)
            }
            
            // 更新进度
            let progress = 0.3 + (Double(index) / Double(totalCount)) * 0.5
            await MainActor.run {
                analysisProgress = progress
            }
        }
        
        return duplicates
    }
    
    private func generateSimpleHash(for item: MediaItem) -> String {
        // 简单的哈希算法：基于文件大小和像素尺寸
        guard let asset = item.asset else { return UUID().uuidString }
        
        let sizeHash = "\(asset.pixelWidth)x\(asset.pixelHeight)"
        let durationHash = asset.duration > 0 ? "\(Int(asset.duration))" : "0"
        
        return "\(sizeHash)_\(durationHash)"
    }
    
    private func calculateSimilarityScore(for item: MediaItem) -> Double {
        // 模拟相似度计算，实际项目中可以使用更复杂的算法
        return Double.random(in: 0.7...0.99)
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
} 