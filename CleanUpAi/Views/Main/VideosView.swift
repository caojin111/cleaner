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
    @State private var showPaywall = false // 新增：Paywall弹窗
    @StateObject private var userSettings = UserSettingsManager.shared // 新增：订阅和滑动状态
    @State private var pageResetKey = UUID() // 新增：强制刷新页面
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.seniorBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部安全区域适配 + 额外间距
                    VStack(spacing: 0) {
                        // 状态栏安全区域 + 额外顶部间距
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: geometry.safeAreaInsets.top + 40) // 统一顶部间距，适配iPhone 15 Pro
                            .onAppear {
                                Logger.ui.debug("视频页状态栏安全区域高度: \(geometry.safeAreaInsets.top), 额外间距: 40")
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
                    .frame(maxHeight: geometry.size.height - geometry.safeAreaInsets.bottom - geometry.safeAreaInsets.top - 200) // 统一主内容区域高度
                    .id(pageResetKey) // 强制刷新主内容
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
        .onReceive(NotificationCenter.default.publisher(for: RecycleBinManager.itemRestoredNotification)) { _ in
            Logger.ui.info("收到回收站恢复通知，准备刷新视频分析与界面")
            Task {
                await videoAnalyzer.quickAnalysis()
                await MainActor.run {
                    currentItemIndex = 0
                    pageResetKey = UUID()
                    Logger.ui.info("VideosView 已刷新到最新状态，恢复滑动界面")
                }
            }
        }
        .navigationBarHidden(true)
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
        // Paywall弹窗
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isFromOnboarding: false)
        }
        // 评分弹窗
        .overlay(
            Group {
                if userSettings.shouldShowRating {
                    RatingView(isPresented: $userSettings.shouldShowRating)
                }
            }
        )
        // 感谢弹窗
        .alert("rate_us.thank_you.title".localized, isPresented: $userSettings.shouldShowThankYou) {
            Button("rate_us.thank_you.ok".localized) {
                userSettings.markThankYouShown()
            }
        } message: {
            Text("rate_us.thank_you.subtitle".localized)
        }
        .onChange(of: showPaywall) { newValue in
            if !newValue {
                isProcessingSwipe = false // Paywall关闭时重置滑动状态
                currentItemIndex = 0 // Paywall关闭时重置索引
                pageResetKey = UUID() // Paywall关闭时强制刷新页面
            }
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
                
                Text("videos.analyzing".localized)
                    .font(.seniorTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.seniorText)
                
                Text("videos.progress".localized(Int(videoAnalyzer.analysisProgress * 100)))
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
                Text("videos.no_duplicates".localized)
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("videos.no_duplicates_subtitle".localized)
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("videos.reanalyze".localized) {
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
            // 顶部统计（仅在清理未完成时显示）
            if currentItemIndex < videoAnalyzer.foundDuplicates.count {
                statsHeader
            }
            
            // 卡片区域
            cardStackView
                .frame(maxHeight: 450) // 统一卡片高度，与PhotosView保持一致
                .offset(y: 5) // 统一偏移距离，与PhotosView保持一致
            
            Spacer()
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 15) {
                CompactStatCard(
                    title: "videos.duplicate_videos".localized,
                    value: "\(videoAnalyzer.foundDuplicates.count)",
                    icon: "video.badge.plus",
                    color: .purple
                )
                
                CompactStatCard(
                    title: "videos.space_savings".localized,
                    value: ByteCountFormatter.string(fromByteCount: videoAnalyzer.estimatedSpaceSavings(), countStyle: .file),
                    icon: "externaldrive.badge.minus",
                    color: .green
                )
            }
            
            // 剩余滑动次数显示
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: userSettings.isSubscribed ? "infinity" : "hand.tap")
                        .font(.caption)
                        .foregroundColor(userSettings.isSubscribed ? .seniorPrimary : .seniorSecondary)
                    
                    Text(userSettings.isSubscribed ? "videos.unlimited_swipes".localized : "videos.remaining_swipes".localized(userSettings.remainingSwipes))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(userSettings.isSubscribed ? .seniorPrimary : .seniorSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((userSettings.isSubscribed ? Color.seniorPrimary : Color.seniorSecondary).opacity(0.1))
                )
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // 进度条
            ProgressView(value: Double(currentItemIndex), total: Double(videoAnalyzer.foundDuplicates.count))
                .progressViewStyle(LinearProgressViewStyle())
                .accentColor(.seniorPrimary)
                .padding(.horizontal, 16)
            
            // 缓存状态指示器
        }
        .padding(.top, 25) // 统一顶部间距，适配iPhone 15 Pro
        .padding(.horizontal, 16)
        .padding(.bottom, 12) // 统一底部间距
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
                        if userSettings.isSubscribed || userSettings.canSwipeToday {
                            handleDelete(item)
                        } else {
                            showPaywall = true
                        }
                    },
                    onSwipeRight: { item in
                        if userSettings.isSubscribed || userSettings.canSwipeToday {
                            handleKeep(item)
                        } else {
                            showPaywall = true
                        }
                    }
                )
                .id(currentItemIndex) // 用id强制刷新卡片状态
                .allowsHitTesting(!isProcessingSwipe) // 处理期间禁用滑动
                .onAppear {
                    Logger.video.debug("当前视频卡片显示: \(duplicates[currentItemIndex].fileName)")
                }
            } else {
                // 完成状态
                completionView
            }
        }
        .padding(.horizontal, 20)
        .id(pageResetKey) // 强制刷新卡片栈
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 30) {
            // 删除按钮
            ActionButton(
                icon: "trash.fill",
                title: "videos.delete".localized,
                color: .modernDelete,
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
                title: "videos.keep".localized,
                color: .modernKeep,
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
        .onAppear {
            Logger.video.debug("视频操作按钮已显示: 按钮尺寸=80x80, 使用高级设计配色方案")
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
                Text("videos.cleaning_complete".localized)
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("videos.cleaning_success".localized)
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // 新增：本次清理统计（只统计被删除的）
            let deletedItems = videoAnalyzer.foundDuplicates.filter { !$0.isMarkedForKeeping }
            VStack(spacing: 8) {
                Text("videos.processed_count".localized(deletedItems.count))
                    .font(.seniorBody)
                    .foregroundColor(.seniorText)
                Text("videos.space_saved".localized(ByteCountFormatter.string(fromByteCount: deletedItems.reduce(0) { $0 + $1.size }, countStyle: .file)))
                    .font(.seniorBody)
                    .foregroundColor(.seniorText)
            }
            
            Button("videos.view_recycle_bin".localized) {
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
        guard !isProcessingSwipe else { 
            Logger.video.debug("删除操作被阻止：正在处理中")
            return 
        }
        guard currentItemIndex < videoAnalyzer.foundDuplicates.count else { return }
        // 新增：滑动次数判断
        guard userSettings.isSubscribed || userSettings.canSwipeToday else {
            showPaywall = true
            return
        }
        isProcessingSwipe = true
        Logger.video.debug("开始处理删除操作: \(item.fileName)")
        
        recycleBinManager.moveToRecycleBin(item)
        userSettings.increaseSwipeCount() // 新增：增加滑动计数
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        nextItem()
    }
    
    private func handleKeep(_ item: MediaItem) {
        guard !isProcessingSwipe else { 
            Logger.video.debug("保留操作被阻止：正在处理中")
            return 
        }
        guard currentItemIndex < videoAnalyzer.foundDuplicates.count else { return }
        // 新增：滑动次数判断
        guard userSettings.isSubscribed || userSettings.canSwipeToday else {
            showPaywall = true
            return
        }
        isProcessingSwipe = true
        Logger.video.debug("开始处理保留操作: \(item.fileName)")
        
        videoAnalyzer.markItemForKeeping(item)
        userSettings.increaseSwipeCount() // 新增：增加滑动计数
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        nextItem()
    }
    
    private func nextItem() {
        Logger.video.debug("开始切换到下一个视频，当前索引: \(currentItemIndex)")
        
        if currentItemIndex >= videoAnalyzer.foundDuplicates.count {
            Logger.video.warning("尝试切换到无效的视频索引: \(currentItemIndex)")
            isProcessingSwipe = false // 保证状态重置
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentItemIndex += 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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

// 使用PhotosView中的CompactStatCard，保持UI一致性

#Preview {
    VideosView()
} 
