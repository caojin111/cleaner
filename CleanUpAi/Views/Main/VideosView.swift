//
//  VideosView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Photos
import Foundation
import UIKit
import OSLog

struct VideosView: View {
    @StateObject private var videoAnalyzer = VideoAnalyzer.shared
    @StateObject private var recycleBinManager = RecycleBinManager.shared
    @State private var currentItemIndex = 0
    @State private var showingAnalysis = false
    @State private var isProcessingSwipe = false // 防止连续滑动
    @State private var cacheStatus = (thumbnails: 0, durations: 0)
    @State private var cacheTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.seniorBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部安全区域适配
                    VStack(spacing: 0) {
                        // 状态栏安全区域
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: geometry.safeAreaInsets.top)
                            .onAppear {
                                Logger.ui.debug("视频页状态栏安全区域高度: \(geometry.safeAreaInsets.top)")
                            }
                    }
                    
                    // 主要内容
                    Group {
                        if videoAnalyzer.isAnalyzing {
                            analysisView
                        } else if videoAnalyzer.foundDuplicates.isEmpty {
                            emptyStateView
                        } else {
                            mainContentWithoutButtons
                        }
                    }
                    .frame(maxHeight: geometry.size.height - geometry.safeAreaInsets.bottom - geometry.safeAreaInsets.top - 200)
                    
                    Spacer()
                }
                
                // 底部按钮 - 固定在屏幕底部
                let duplicates = videoAnalyzer.foundDuplicates
                if !videoAnalyzer.isAnalyzing && !duplicates.isEmpty && currentItemIndex < duplicates.count {
                    VStack {
                        Spacer()
                        actionButtons
                            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 20)
                            .offset(y: 65)
                    }
                }
            }
        }
        .onAppear {
            startAnalysisIfNeeded()
            startCacheStatusMonitoring()
            Logger.ui.debug("VideosView 已显示，开始检查分析状态")
        }
        .onDisappear {
            cacheTimer?.invalidate()
            cacheTimer = nil
            Logger.ui.debug("VideosView 已隐藏，清理缓存监控")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            // 内存警告时清理缓存
            videoAnalyzer.clearThumbnailCache()
            Logger.video.warning("收到内存警告，已清理视频缓存")
        }
    }
    
    // MARK: - Analysis View
    
    private var analysisView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 分析动画
            VStack(spacing: 20) {
                ProgressView(value: videoAnalyzer.analysisProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
                    .accentColor(.seniorPrimary)
                
                Text("正在分析视频...")
                    .font(.seniorTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.seniorText)
                
                Text("已处理 \(Int(videoAnalyzer.analysisProgress * 100))%")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
            }
            
            Spacer()
        }
        .onAppear {
            showingAnalysis = true
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 空状态图标
            Image(systemName: "video.badge.checkmark")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.seniorSecondary)
            
            VStack(spacing: 16) {
                Text("没有发现重复视频")
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("您的视频库看起来很整洁！")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("重新分析") {
                Task {
                    await videoAnalyzer.startAnalysis()
                }
            }
            .font(.seniorBody)
            .fontWeight(.semibold)
            .foregroundColor(.seniorPrimary)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(Color.seniorPrimary, lineWidth: 2)
            )
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Main Content Without Buttons
    
    private var mainContentWithoutButtons: some View {
        VStack(spacing: 0) {
            // 顶部统计
            statsHeader
            
            // 卡片区域
            cardStackView
                .frame(maxHeight: 500)
                .offset(y: 10)
            
            Spacer()
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 15) {
                CompactVideoStatCard(
                    title: "重复视频",
                    value: "\(videoAnalyzer.foundDuplicates.count)",
                    icon: "video.badge.plus",
                    color: .purple
                )
                
                CompactVideoStatCard(
                    title: "可节省",
                    value: ByteCountFormatter.string(fromByteCount: videoAnalyzer.estimatedSpaceSavings(), countStyle: .file),
                    icon: "externaldrive.badge.minus",
                    color: .green
                )
            }
            
            // 进度条
            ProgressView(value: Double(currentItemIndex), total: Double(videoAnalyzer.foundDuplicates.count))
                .progressViewStyle(LinearProgressViewStyle())
                .accentColor(.seniorPrimary)
                .padding(.horizontal, 16)
            
            // 缓存状态指示器
            let duplicatesCount = videoAnalyzer.foundDuplicates.count
            if cacheStatus.thumbnails < duplicatesCount && duplicatesCount > 0 {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .rotationEffect(.degrees(45))
                    
                    Text("正在优化体验... \(cacheStatus.thumbnails)/\(duplicatesCount)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            } else if cacheStatus.thumbnails >= duplicatesCount && duplicatesCount > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Text("已优化，可流畅滑动")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
        }
        .padding(.top, 25)
        .padding(.horizontal, 16)
        .padding(.bottom, 15)
        .background(
            Color.white
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
        )
        .shadow(color: .gray.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 12)
        .onAppear {
            Logger.video.debug("视频统计卡片已显示: 重复视频数量=\(videoAnalyzer.foundDuplicates.count), 当前索引=\(currentItemIndex)")
        }
    }
    
    // MARK: - Card Stack View
    
    private var cardStackView: some View {
        ZStack {
            let duplicates = videoAnalyzer.foundDuplicates
            if currentItemIndex < duplicates.count {
                // 背景卡片（下一张） - 现在使用预缓存的缩略图
                if currentItemIndex + 1 < duplicates.count {
                    SwipeableVideoCard(
                        item: duplicates[currentItemIndex + 1],
                        onSwipeLeft: { _ in },
                        onSwipeRight: { _ in }
                    )
                    .scaleEffect(0.95)
                    .opacity(0.6)
                    .offset(y: 10)
                    .allowsHitTesting(false)
                    .onAppear {
                        Logger.video.debug("背景视频卡片显示: \(duplicates[currentItemIndex + 1].fileName)")
                    }
                }
                
                // 当前卡片 - 使用预缓存的缩略图
                SwipeableVideoCard(
                    item: duplicates[currentItemIndex],
                    onSwipeLeft: { item in
                        handleDelete(item)
                    },
                    onSwipeRight: { item in
                        handleKeep(item)
                    }
                )
                .allowsHitTesting(!isProcessingSwipe)
                .onAppear {
                    Logger.video.debug("当前视频卡片显示: \(duplicates[currentItemIndex].fileName)")
                }
            } else {
                // 完成状态
                completionView
            }
        }
        .padding(.horizontal, 20)
        .id("videoCardStack_\(currentItemIndex)")
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 30) {
            // 删除按钮
            ActionButton(
                icon: "trash.fill",
                title: "删除",
                color: .seniorDanger,
                action: {
                    let duplicates = videoAnalyzer.foundDuplicates
                    if currentItemIndex < duplicates.count && !isProcessingSwipe {
                        handleDelete(duplicates[currentItemIndex])
                    }
                }
            )
            .disabled(isProcessingSwipe)
            .opacity(isProcessingSwipe ? 0.6 : 1.0)
            
            // 保留按钮
            ActionButton(
                icon: "heart.fill",
                title: "保留",
                color: .seniorSuccess,
                action: {
                    let duplicates = videoAnalyzer.foundDuplicates
                    if currentItemIndex < duplicates.count && !isProcessingSwipe {
                        handleKeep(duplicates[currentItemIndex])
                    }
                }
            )
            .disabled(isProcessingSwipe)
            .opacity(isProcessingSwipe ? 0.6 : 1.0)
        }
        .padding(.horizontal, 40)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .background(
            Color.white
                .ignoresSafeArea(.all, edges: .bottom)
        )
        .shadow(color: .gray.opacity(0.15), radius: 8, x: 0, y: -4)
        .onAppear {
            Logger.video.debug("视频操作按钮已显示: 按钮尺寸=72x72, 位置偏移=65像素")
        }
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 30) {
            // 完成图标
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.seniorSuccess)
            
            VStack(spacing: 16) {
                Text("视频清理完成！")
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("您已成功清理了所有重复视频\n手机空间得到了优化")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("查看回收站") {
                // TODO: 导航到回收站
                Logger.logPageNavigation(from: "VideosView", to: "RecycleBinView")
            }
            .font(.seniorBody)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .fill(Color.seniorPrimary)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func startAnalysisIfNeeded() {
        if videoAnalyzer.foundDuplicates.isEmpty && !videoAnalyzer.isAnalyzing {
            Task {
                await videoAnalyzer.startAnalysis()
            }
        }
    }
    
    private func handleDelete(_ item: MediaItem) {
        guard !isProcessingSwipe else { return }
        guard currentItemIndex < videoAnalyzer.foundDuplicates.count else { return }
        
        isProcessingSwipe = true
        Logger.video.debug("开始处理删除操作: \(item.fileName)")
        
        recycleBinManager.moveToRecycleBin(item)
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        nextItem()
    }
    
    private func handleKeep(_ item: MediaItem) {
        guard !isProcessingSwipe else { return }
        guard currentItemIndex < videoAnalyzer.foundDuplicates.count else { return }
        
        isProcessingSwipe = true
        Logger.video.debug("开始处理保留操作: \(item.fileName)")
        
        videoAnalyzer.markItemForKeeping(item)
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        nextItem()
    }
    
    private func nextItem() {
        Logger.video.debug("开始切换到下一个视频，当前索引: \(currentItemIndex)")
        
        guard currentItemIndex < videoAnalyzer.foundDuplicates.count else {
            Logger.video.warning("尝试切换到无效的视频索引: \(currentItemIndex)")
            isProcessingSwipe = false
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentItemIndex += 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isProcessingSwipe = false
            Logger.video.debug("滑动保护状态已重置，当前索引: \(currentItemIndex)")
        }
    }
    
    private func startCacheStatusMonitoring() {
        // 先清除之前的Timer
        cacheTimer?.invalidate()
        
        cacheTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {
                let status = self.videoAnalyzer.getCacheStatus()
                self.cacheStatus = status
                
                // 如果缓存完成，停止监控
                let duplicatesCount = self.videoAnalyzer.foundDuplicates.count
                if status.thumbnails >= duplicatesCount && duplicatesCount > 0 {
                    timer.invalidate()
                    self.cacheTimer = nil
                    Logger.video.info("缓存监控完成: \(status.thumbnails) 个缩略图已缓存")
                }
            }
        }
    }
}

// MARK: - Compact Video Stat Card

struct CompactVideoStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.seniorText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.seniorSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.06))
        )
    }
}

#Preview {
    VideosView()
} 
