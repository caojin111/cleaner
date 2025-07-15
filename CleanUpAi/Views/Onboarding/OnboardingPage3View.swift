//
//  OnboardingPage3View.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog
import Photos

struct OnboardingPage3View: View {
    @Binding var currentPage: Int
    @State private var animatePhotos = false
    @State private var showAnalysisAnimation = false
    @State private var randomPhotos: [UIImage] = []
    @StateObject private var photoAnalyzer = PhotoAnalyzer.shared
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 图片回顾动画 - 扑克牌叠放展示
            ZStack {
                // 背景圆圈
                Circle()
                    .fill(Color.seniorPrimary.opacity(0.1))
                    .frame(width: 220, height: 220)
                
                // 扑克牌叠放展示
                ZStack {
                    ForEach(0..<min(randomPhotos.count, 5), id: \.self) { index in
                        let reverseIndex = min(randomPhotos.count, 5) - 1 - index
                        PokerCardThumbnail(
                            image: randomPhotos[reverseIndex],
                            index: reverseIndex,
                            total: min(randomPhotos.count, 5),
                            delay: Double(reverseIndex) * 0.15
                        )
                    }
                }
                .scaleEffect(animatePhotos ? 1.0 : 0.8)
                .opacity(animatePhotos ? 1.0 : 0.3)
                
                // 分析指示器
                if showAnalysisAnimation {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.seniorPrimary)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                                .shadow(color: .gray.opacity(0.3), radius: 8)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            // 文字内容
            VStack(spacing: 20) {
                Text(Constants.Onboarding.page3Title)
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                    .multilineTextAlignment(.center)
                
                Text(Constants.Onboarding.page3Subtitle)
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // 功能特点
                VStack(alignment: .leading, spacing: 12) {
                    FeatureItem(icon: "🔍", text: "智能识别相似图片")
                    FeatureItem(icon: "📊", text: "分析存储空间占用")
                    FeatureItem(icon: "🏆", text: "找出最值得保留的照片")
                    FeatureItem(icon: "🗂️", text: "按时间和类型整理")
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // 继续按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
                Logger.logPageNavigation(from: "Onboarding-3", to: "Onboarding-4")
            }) {
                HStack {
                    Text("查看我的照片")
                        .font(.seniorBody)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.body)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: Constants.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .fill(Color.seniorPrimary)
                )
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .onAppear {
            loadRandomPhotos()
            startAnimations()
        }
    }
    
    private func loadRandomPhotos() {
        Task {
            // 先请求照片权限
            let status = await requestPhotoPermission()
            guard status == .authorized || status == .limited else {
                Logger.logError(NSError(domain: "Photos", code: 1, userInfo: [NSLocalizedDescriptionKey: "照片权限未授权，状态: \(status.rawValue)"]), context: "加载随机照片")
                return
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 100 // 获取更多照片用于随机选择
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            guard assets.count > 0 else {
                Logger.analytics.info("用户相册中没有照片")
                return
            }
            
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .exact
            requestOptions.isNetworkAccessAllowed = true
            
            // 随机选择最多5张照片
            let totalAssets = min(assets.count, 100)
            let maxPhotos = min(5, assets.count)
            let indices = Array(0..<totalAssets).shuffled().prefix(maxPhotos)
            var loadedImages: [UIImage] = []
            
            Logger.analytics.info("开始加载 \(indices.count) 张随机照片，总共 \(assets.count) 张照片可选")
            
            // 使用TaskGroup并行加载图片
            await withTaskGroup(of: UIImage?.self) { group in
                for index in indices {
                    group.addTask {
                        let asset = assets.object(at: index)
                        return await self.loadImageFromAsset(asset, imageManager: imageManager, options: requestOptions)
                    }
                }
                
                for await image in group {
                    if let image = image {
                        await MainActor.run {
                            loadedImages.append(image)
                            self.randomPhotos = loadedImages
                        }
                    }
                }
            }
            
            await MainActor.run {
                Logger.analytics.info("成功加载 \(loadedImages.count) 张随机照片用于预览")
            }
        }
    }
    
    // 请求照片权限
    @MainActor
    private func requestPhotoPermission() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if currentStatus == .notDetermined {
            Logger.analytics.info("请求照片访问权限")
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        
        return currentStatus
    }
    
    // 从PHAsset加载UIImage
    private func loadImageFromAsset(_ asset: PHAsset, imageManager: PHImageManager, options: PHImageRequestOptions) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 120, height: 120),
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    Logger.logError(error, context: "加载照片缩略图失败")
                }
                continuation.resume(returning: image)
            }
        }
    }
    
    private func startAnimations() {
        // 图片动画
        withAnimation(.easeInOut(duration: 0.8)) {
            animatePhotos = true
        }
        
        // 分析指示器动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showAnalysisAnimation = true
            }
            
            // 循环动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showAnalysisAnimation = false
                }
            }
        }
    }
}

// MARK: - Poker Card Thumbnail Component

struct PokerCardThumbnail: View {
    let image: UIImage
    let index: Int
    let total: Int
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .frame(width: 80, height: 100)
            .overlay(
                Group {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .cornerRadius(8)
                        .padding(4)
                }
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .rotationEffect(.degrees(cardRotation))
            .offset(x: cardXOffset, y: cardYOffset)
            .opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).delay(delay)) {
                    isVisible = true
                }
            }
    }
    
    private var cardRotation: Double {
        let baseRotation = Double(index - (total - 1) / 2) * 15.0
        let randomFactor = Double.random(in: -5...5)
        return baseRotation + randomFactor
    }
    
    private var cardXOffset: CGFloat {
        CGFloat(index - (total - 1) / 2) * 8.0
    }
    
    private var cardYOffset: CGFloat {
        CGFloat(index - (total - 1) / 2) * 4.0
    }
}

// MARK: - Feature Item Component

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            Text(text)
                .font(.seniorBody)
                .foregroundColor(.seniorText)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingPage3View(currentPage: .constant(2))
} 