//
//  PhotosView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Photos
import Foundation
import UIKit
import OSLog
import FirebaseAnalytics

struct PhotosView: View {
    @StateObject private var photoAnalyzer = PhotoAnalyzer.shared
    @StateObject private var recycleBinManager = RecycleBinManager.shared
    @State private var currentItemIndex = 0
    @State private var showingAnalysis = false
    @State private var isProcessingSwipe = false // 防止连续滑动
    @Binding var selectedTab: Int
    @State private var showPaywall = false // 新增：Paywall弹窗
    @StateObject private var userSettings = UserSettingsManager.shared // 新增：订阅和滑动状态
    @State private var pageResetKey = UUID() // 新增：强制刷新页面
    @State private var showingPhotoDetails = false // 新增：显示照片详情
    @State private var photoDetailsText = "" // 新增：照片详情文本
    
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
                                Logger.ui.debug("状态栏安全区域高度: \(geometry.safeAreaInsets.top), 额外间距: 40")
                            }
                    }
                    
                    // 主要内容
                    Group {
                        if photoAnalyzer.isAnalyzing {
                            analysisView
                        } else if photoAnalyzer.foundDuplicates.isEmpty {
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
                if !photoAnalyzer.isAnalyzing && !photoAnalyzer.foundDuplicates.isEmpty && currentItemIndex < photoAnalyzer.foundDuplicates.count {
                    VStack {
                        Spacer()
                        actionButtons
                            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 20)
                            .offset(y: 65) // 向下偏移65像素（原50+15）避免遮挡相似度文字
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startAnalysisIfNeeded()
            Logger.ui.debug("PhotosView 已显示，开始检查分析状态")

            // Firebase Analytics: 记录照片页面浏览
            FirebaseManager.shared.logScreenView(screenName: "PhotosView")
            FirebaseManager.shared.logUserAction(action: "photos_screen_viewed")
        }
        .onReceive(NotificationCenter.default.publisher(for: RecycleBinManager.itemRestoredNotification)) { notification in
            Logger.ui.info("收到回收站恢复通知，准备刷新照片分析与界面")
            Task {
                await photoAnalyzer.startAnalysis()
                await MainActor.run {
                    currentItemIndex = 0
                    pageResetKey = UUID()
                    Logger.ui.info("PhotosView 已刷新到最新状态，恢复滑动界面")
                }
            }
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
        // 照片详情弹窗
        .alert("照片详情", isPresented: $showingPhotoDetails) {
            Button("确定") { }
        } message: {
            Text(photoDetailsText)
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
                ProgressView(value: photoAnalyzer.analysisProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
                    .accentColor(.seniorPrimary)
                
                Text("photos.analyzing".localized)
                    .font(.seniorTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.seniorText)
                
                Text("photos.progress".localized(Int(photoAnalyzer.analysisProgress * 100)))
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
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.seniorSecondary)
            
            VStack(spacing: 16) {
                Text("photos.no_duplicates".localized)
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("photos.no_duplicates_subtitle".localized)
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("photos.reanalyze".localized) {
                Task {
                    await photoAnalyzer.startAnalysis()
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
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // 顶部统计（仅在清理未完成时显示）
            if currentItemIndex < photoAnalyzer.foundDuplicates.count {
                statsHeader
            }
            
            // 卡片区域 - 统一高度设置
            cardStackView
                .frame(maxHeight: 350) // 统一卡片高度
            
            Spacer() // 弹性空间
            
            // 底部操作按钮（仅在有待处理项目时显示）
            if currentItemIndex < photoAnalyzer.foundDuplicates.count {
                actionButtons
                    .padding(.bottom, 20) // 额外底部安全距离
            }
        }
    }
    
    // MARK: - Main Content Without Buttons
    
    private var mainContentWithoutButtons: some View {
        VStack(spacing: 0) {
            // 顶部统计（仅在清理未完成时显示）
            if currentItemIndex < photoAnalyzer.foundDuplicates.count {
                statsHeader
            }
            
            // 卡片区域 - 统一高度设置
            cardStackView
                .frame(maxHeight: 450) // 统一卡片高度
                .offset(y: 5) // 统一偏移距离
            
            Spacer() // 弹性空间
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 15) { // 增加卡片间距提升美观性
                CompactStatCard(
                    title: "photos.duplicate_photos".localized,
                    value: "\(photoAnalyzer.foundDuplicates.count)",
                    icon: "photo.stack",
                    color: .purple
                )
                
                CompactStatCard(
                    title: "photos.space_savings".localized,
                    value: ByteCountFormatter.string(fromByteCount: photoAnalyzer.estimatedSpaceSavings(), countStyle: .file),
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
                    
                    Text(userSettings.isSubscribed ? "photos.unlimited_swipes".localized : "photos.remaining_swipes".localized(userSettings.remainingSwipes))
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
            ProgressView(value: Double(currentItemIndex), total: Double(photoAnalyzer.foundDuplicates.count))
                .progressViewStyle(LinearProgressViewStyle())
                .accentColor(.seniorPrimary)
                .padding(.horizontal, 16) // 恢复到合适的padding
        }
        .padding(.top, 25) // 统一顶部间距，适配iPhone 15 Pro
        .padding(.horizontal, 16) // 统一水平padding
        .padding(.bottom, 12) // 统一底部间距
        .background(
            Color.white
                .clipShape(
                    RoundedRectangle(cornerRadius: 16) // 增加圆角提升美观性
                )
        )
        .shadow(color: .gray.opacity(0.1), radius: 8, x: 0, y: 4) // 优化阴影效果
        .padding(.horizontal, 12) // 为背景卡片添加外边距
        .onAppear {
            Logger.ui.debug("统计卡片已显示: 重复照片数量=\(photoAnalyzer.foundDuplicates.count), 当前索引=\(currentItemIndex)")
        }
    }
    
    // MARK: - Card Stack View
    
    private var cardStackView: some View {
        ZStack {
            if currentItemIndex < photoAnalyzer.foundDuplicates.count {
                // 背景卡片（下一张）
                if currentItemIndex + 1 < photoAnalyzer.foundDuplicates.count {
                    SwipeablePhotoCard(
                        item: photoAnalyzer.foundDuplicates[currentItemIndex + 1],
                        onSwipeLeft: { _ in },
                        onSwipeRight: { _ in }
                    )
                    .scaleEffect(0.95)
                    .opacity(0.6)
                    .offset(y: 10)
                    .allowsHitTesting(false) // 背景卡片不可交互
                    .id("background_\(currentItemIndex + 1)") // 确保背景卡片正确更新
                }
                
                // 当前卡片
                SwipeablePhotoCard(
                    item: photoAnalyzer.foundDuplicates[currentItemIndex],
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
                .allowsHitTesting(!isProcessingSwipe) // 处理期间禁用滑动
                .id("current_\(currentItemIndex)") // 确保当前卡片正确更新
            } else {
                // 完成状态
                completionView
            }
        }
        .padding(.horizontal, 20)
        .onChange(of: currentItemIndex) { newIndex in
            Logger.ui.debug("卡片索引已更新: \(newIndex)")
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 30) {
            // 删除按钮
            ActionButton(
                icon: "trash.fill",
                title: "photos.delete".localized,
                color: .modernDelete,
                action: {
                    if currentItemIndex < photoAnalyzer.foundDuplicates.count && !isProcessingSwipe {
                        handleDelete(photoAnalyzer.foundDuplicates[currentItemIndex])
                    }
                }
            )
            .disabled(isProcessingSwipe) // 处理期间禁用按钮
            .opacity(isProcessingSwipe ? 0.6 : 1.0)
            
            // 保留按钮
            ActionButton(
                icon: "heart.fill",
                title: "photos.keep".localized,
                color: .modernKeep,
                action: {
                    if currentItemIndex < photoAnalyzer.foundDuplicates.count && !isProcessingSwipe {
                        handleKeep(photoAnalyzer.foundDuplicates[currentItemIndex])
                    }
                }
            )
            .disabled(isProcessingSwipe) // 处理期间禁用按钮
            .opacity(isProcessingSwipe ? 0.6 : 1.0)
        }
        .padding(.horizontal, 40)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .onAppear {
            Logger.ui.debug("操作按钮已显示: 按钮尺寸=80x80, 使用高级设计配色方案")
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
                Text("photos.cleaning_complete".localized)
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("photos.cleaning_success".localized)
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // 新增：本次清理统计（只统计被删除的）
            let deletedItems = photoAnalyzer.foundDuplicates.filter { !$0.isMarkedForKeeping }
            VStack(spacing: 8) {
                Text("photos.processed_count".localized(deletedItems.count))
                    .font(.seniorBody)
                    .foregroundColor(.seniorText)
                Text("photos.space_saved".localized(ByteCountFormatter.string(fromByteCount: deletedItems.reduce(0) { $0 + $1.size }, countStyle: .file)))
                    .font(.seniorBody)
                    .foregroundColor(.seniorText)
            }
            
            Button("photos.view_recycle_bin".localized) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 2 // 回收站Tab的索引（更新后的位置）
                }
                Logger.logPageNavigation(from: "PhotosView", to: "RecycleBinView")
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
        if photoAnalyzer.foundDuplicates.isEmpty && !photoAnalyzer.isAnalyzing {
            Task {
                await photoAnalyzer.startAnalysis()
            }
        }
    }
    
    private func handleDelete(_ item: MediaItem) {
        guard !isProcessingSwipe else { 
            Logger.ui.debug("删除操作被阻止：正在处理中")
            return 
        }
        // 新增：滑动次数判断
        guard userSettings.isSubscribed || userSettings.canSwipeToday else {
            showPaywall = true
            return
        }
        isProcessingSwipe = true
        Logger.ui.debug("开始处理删除操作: \(item.fileName)")
        
        recycleBinManager.moveToRecycleBin(item)
        userSettings.increaseSwipeCount() // 新增：增加滑动计数
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        nextItem()
    }
    
    private func handleKeep(_ item: MediaItem) {
        guard !isProcessingSwipe else { 
            Logger.ui.debug("保留操作被阻止：正在处理中")
            return 
        }
        // 新增：滑动次数判断
        guard userSettings.isSubscribed || userSettings.canSwipeToday else {
            showPaywall = true
            return
        }
        isProcessingSwipe = true
        Logger.ui.debug("开始处理保留操作: \(item.fileName)")
        
        photoAnalyzer.markItemForKeeping(item)
        userSettings.increaseSwipeCount() // 新增：增加滑动计数
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        nextItem()
    }
    
    private func nextItem() {
        Logger.ui.debug("开始切换到下一个项目，当前索引: \(currentItemIndex)")
        
        // 确保索引不会超出范围
        guard currentItemIndex < photoAnalyzer.foundDuplicates.count else {
            Logger.ui.debug("已到达最后一张照片，无需切换")
            isProcessingSwipe = false
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentItemIndex += 1
        }
        
        Logger.ui.debug("索引已更新为: \(currentItemIndex)")
        
        // 延迟重置滑动保护状态，确保动画完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isProcessingSwipe = false
            Logger.ui.debug("滑动保护状态已重置，当前索引: \(currentItemIndex)")
        }
    }
    
    private func showPhotoDetails() {
        guard currentItemIndex < photoAnalyzer.foundDuplicates.count else { return }
        let item = photoAnalyzer.foundDuplicates[currentItemIndex]
        
        let details = photoAnalyzer.getPhotoDetails(for: item)
        
        photoDetailsText = details
        showingPhotoDetails = true
        Logger.ui.debug("显示照片详情: \(item.fileName)")
    }
}

// MARK: - Swipeable Photo Card

struct SwipeablePhotoCard: View {
    let item: MediaItem
    let onSwipeLeft: (MediaItem) -> Void
    let onSwipeRight: (MediaItem) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var photoImage: UIImage?
    @State private var isSwipeAnimating = false // 防止滑动动画期间的重复操作
    
    // 用于唯一标识卡片，防止状态混乱
    private var cardID: String {
        "\(item.fileName)_\(item.id)"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 照片预览
            Group {
                if let image = photoImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                    .padding(.bottom, 8)
                                
                                Text("photos.loading".localized)
                                    .font(.seniorCaption)
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
            .frame(width: 280, height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // 照片信息
            VStack(spacing: 8) {
                Text(item.fileName)
                    .font(.seniorBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.seniorText)
                
                HStack(spacing: 20) {
                    Label(item.formattedSize, systemImage: "externaldrive")
                    Label(item.formattedDate, systemImage: "calendar")
                }
                .font(.seniorCaption)
                .foregroundColor(.seniorSecondary)
                
                if item.isDuplicate {
                    Text("photos.similarity".localized(Int(item.similarityScore * 100)))
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
                    // 只有在非滑动动画状态时才响应手势
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
            // 滑动指示器
            swipeIndicators
        )
        .onAppear {
            resetCardState()
            loadPhotoImage()
            Logger.ui.debug("卡片已显示: \(item.fileName), ID: \(cardID)")
        }
        .id(cardID) // 确保每张卡片有唯一标识
        .onChange(of: item.id) { _ in
            // 当item.id改变时，重置卡片状态
            resetCardState()
            loadPhotoImage()
            Logger.ui.debug("卡片内容已更新: \(item.fileName)")
        }
    }
    
    private func resetCardState() {
        offset = .zero
        rotation = 0
        photoImage = nil
        isSwipeAnimating = false
        Logger.ui.debug("重置卡片状态: \(item.fileName)")
    }
    
    private func loadPhotoImage() {
        guard let asset = item.asset else { return }
        
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
                    self.photoImage = image
                    Logger.ui.debug("成功加载照片: \(self.item.fileName)")
                } else if let error = info?[PHImageErrorKey] as? Error {
                    Logger.logError(error, context: "加载照片失败: \(self.item.fileName)")
                }
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
                            Text("photos.delete".localized)
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
                            Text("photos.keep".localized)
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
            Logger.ui.debug("滑动动画被阻止：正在处理中")
            return 
        }
        
        if value.translation.width < -Constants.swipeThreshold {
            // 左滑删除
            isSwipeAnimating = true
            Logger.ui.debug("执行左滑删除: \(item.fileName)")
            
            withAnimation(.easeOut(duration: 0.3)) {
                offset = CGSize(width: -1000, height: 0)
                rotation = -30
            }
            
            // 延迟执行回调，确保动画开始
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onSwipeLeft(item)
            }
            
        } else if value.translation.width > Constants.swipeThreshold {
            // 右滑保留
            isSwipeAnimating = true
            Logger.ui.debug("执行右滑保留: \(item.fileName)")
            
            withAnimation(.easeOut(duration: 0.3)) {
                offset = CGSize(width: 1000, height: 0)
                rotation = 30
            }
            
            // 延迟执行回调，确保动画开始
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onSwipeRight(item)
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

// MARK: - Supporting Views

// MARK: - Compact Stat Card (紧凑版统计卡片)

struct CompactStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) { // 从6缩小到4
            Image(systemName: icon)
                .font(.body) // 从.title3进一步缩小到.body
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline) // 从.seniorBody进一步缩小到.subheadline
                .fontWeight(.bold)
                .foregroundColor(.seniorText)
                .lineLimit(1)
                .minimumScaleFactor(0.7) // 从0.8进一步缩小到0.7
            
            Text(title)
                .font(.caption2) // 从.caption进一步缩小到.caption2
                .foregroundColor(.seniorSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8) // 从10缩小到8
        .padding(.horizontal, 10) // 从12缩小到10
        .background(
            RoundedRectangle(cornerRadius: 8) // 从10缩小到8
                .fill(color.opacity(0.06)) // 从0.08进一步降低到0.06，更淡的背景
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.seniorTitle)
                .fontWeight(.bold)
                .foregroundColor(.seniorText)
            
            Text(title)
                .font(.seniorCaption)
                .foregroundColor(.seniorSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(color.opacity(0.1))
        )
    }
}



// MARK: - Settings View (Placeholder)

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("photos.settings".localized)
                    .font(.seniorTitle)
                Text("photos.coming_soon".localized)
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PhotosView(selectedTab: .constant(0))
} 
