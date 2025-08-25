//
//  SwipeableVideoCard.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Photos
import AVFoundation
import OSLog

struct SwipeableVideoCard: View {
    let item: MediaItem
    let onSwipeLeft: (MediaItem) -> Void
    let onSwipeRight: (MediaItem) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var videoThumbnail: UIImage?
    @State private var isSwipeAnimating = false
    @State private var videoDuration: String = ""
    @State private var currentAssetId: String = ""
    
    // 用于唯一标识卡片，防止状态混乱
    private var cardID: String {
        "\(item.fileName)_\(item.id)"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 视频预览
            ZStack {
                if let thumbnail = videoThumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 280, height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 280, height: 320)
                        .overlay(
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                    .padding(.bottom, 8)
                                
                                Text("videos.loading".localized)
                                    .font(.seniorCaption)
                                    .foregroundColor(.white)
                            }
                        )
                }
                
                // 播放按钮覆盖层
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        // 视频时长标签
                        if !videoDuration.isEmpty {
                            Text(videoDuration)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.black.opacity(0.7))
                                )
                        }
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                }
                
                // 中心播放图标
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            // 视频信息
            VStack(spacing: 8) {
                Text(item.fileName)
                    .font(.seniorBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.seniorText)
                    .lineLimit(1)
                
                HStack(spacing: 20) {
                    Label(item.formattedSize, systemImage: "externaldrive")
                    Label(item.formattedDate, systemImage: "calendar")
                }
                .font(.seniorCaption)
                .foregroundColor(.seniorSecondary)
                
                if item.isDuplicate {
                    Text("videos.similarity".localized(Int(item.similarityScore * 100)))
                        .font(.seniorCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isSwipeAnimating {
                        offset = value.translation
                        rotation = Double(value.translation.width / 10)
                    }
                }
                .onEnded { value in
                    handleSwipeEnd(value)
                }
        )
        .overlay(
            swipeIndicators
        )
        .onAppear {
            // 只重置动画状态，不重置缩略图
            offset = .zero
            rotation = 0
            isSwipeAnimating = false
            
            // 检测内容是否变化，如果变化则重新加载
            let newAssetId = item.asset?.localIdentifier ?? item.id.uuidString
            if currentAssetId != newAssetId && !newAssetId.isEmpty {
                currentAssetId = newAssetId
                videoThumbnail = nil
                videoDuration = ""
                Logger.video.debug("视频内容变化，重新加载: \(item.fileName)")
            }
            
            loadVideoThumbnail()
            Logger.video.debug("视频卡片显示: \(item.fileName)")
        }
    }
    
    private func resetCardState() {
        offset = .zero
        rotation = 0
        videoThumbnail = nil
        videoDuration = ""
        isSwipeAnimating = false
        Logger.video.debug("重置视频卡片状态: \(item.fileName)")
    }
    
    private func loadVideoThumbnail() {
        guard let asset = item.asset else { return }
        
        // 如果已经有缩略图且是同一个资源，则不重新加载
        if videoThumbnail != nil && !videoDuration.isEmpty {
            return
        }
        
        let videoAnalyzer = VideoAnalyzer.shared
        
        // 首先尝试从缓存获取缩略图
        if let cachedThumbnail = videoAnalyzer.getCachedThumbnail(for: asset) {
            videoThumbnail = cachedThumbnail
            Logger.video.debug("从缓存加载视频缩略图: \(item.fileName)")
        } else {
            // 如果缓存中没有，则异步加载
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.resizeMode = .exact
        requestOptions.isNetworkAccessAllowed = true
        
        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 280, height: 320),
            contentMode: .aspectFill,
            options: requestOptions
        ) { image, info in
            DispatchQueue.main.async {
                if let image = image {
                    self.videoThumbnail = image
                        Logger.video.debug("动态加载视频缩略图: \(self.item.fileName)")
                } else if let error = info?[PHImageErrorKey] as? Error {
                    Logger.logError(error, context: "加载视频缩略图失败: \(self.item.fileName)")
                }
                }
            }
        }
        
        // 尝试从缓存获取视频时长
        if let cachedDuration = videoAnalyzer.getCachedDuration(for: asset) {
            videoDuration = cachedDuration
            Logger.video.debug("从缓存加载视频时长: \(item.fileName)")
        } else {
            // 如果缓存中没有，则计算时长
        let duration = asset.duration
        if duration > 0 {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            videoDuration = String(format: "%d:%02d", minutes, seconds)
            }
        }
    }
    
    private var swipeIndicators: some View {
        ZStack {
            // 左滑删除指示器
            if offset.width < -Constants.swipeHintThreshold {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.modernDelete, lineWidth: 3)
                    .overlay(
                        VStack {
                            Image(systemName: "trash.fill")
                                .font(.largeTitle)
                                .foregroundColor(.modernDelete)
                            Text("videos.delete".localized)
                                .font(.seniorBody)
                                .fontWeight(.bold)
                                .foregroundColor(.modernDelete)
                        }
                    )
                    .opacity(min(abs(offset.width) / Constants.swipeThreshold, 1.0))
            }
            
            // 右滑保留指示器
            if offset.width > Constants.swipeHintThreshold {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.modernKeep, lineWidth: 3)
                    .overlay(
                        VStack {
                            Image(systemName: "heart.fill")
                                .font(.largeTitle)
                                .foregroundColor(.modernKeep)
                            Text("videos.keep".localized)
                                .font(.seniorBody)
                                .fontWeight(.bold)
                                .foregroundColor(.modernKeep)
                        }
                    )
                    .opacity(min(offset.width / Constants.swipeThreshold, 1.0))
            }
        }
    }
    
    private func handleSwipeEnd(_ value: DragGesture.Value) {
        guard !isSwipeAnimating else { 
            Logger.video.debug("滑动动画被阻止：正在处理中")
            return 
        }
        
        if value.translation.width < -Constants.swipeThreshold {
            // 左滑删除
            isSwipeAnimating = true
            Logger.video.debug("执行左滑删除: \(item.fileName)")
            
            withAnimation(.easeOut(duration: 0.3)) {
                offset = CGSize(width: -1000, height: 0)
                rotation = -30
            }
            
            // 延迟执行回调，确保动画开始
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onSwipeLeft(item)
                // 修复：滑动回调后重置动画状态，防止卡死
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isSwipeAnimating = false
                }
            }
            
        } else if value.translation.width > Constants.swipeThreshold {
            // 右滑保留
            isSwipeAnimating = true
            Logger.video.debug("执行右滑保留: \(item.fileName)")
            
            withAnimation(.easeOut(duration: 0.3)) {
                offset = CGSize(width: 1000, height: 0)
                rotation = 30
            }
            
            // 延迟执行回调，确保动画开始
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onSwipeRight(item)
                // 修复：滑动回调后重置动画状态，防止卡死
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isSwipeAnimating = false
                }
            }
            
        } else {
            // 回弹
            withAnimation(.spring()) {
                offset = .zero
                rotation = 0
            }
        }
    }
} 