import SwiftUI
import Foundation
import OSLog
import Photos

struct OnboardingPage3View_New: View {
    @Binding var currentPage: Int
    var onPrepareAnalysis: (() -> Void)? = nil
    @State private var animatePhotos = false
    @State private var randomPhotos: [UIImage] = []
    @StateObject private var photoAnalyzer = PhotoAnalyzer.shared
    @State private var isContinueButtonDisabled = false // 防止连点保护
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                // 顶部照片卡片堆叠
                ZStack {
                    ForEach(0..<min(randomPhotos.count, 5), id: \.self) { index in
                        let reverseIndex = min(randomPhotos.count, 5) - 1 - index
                        PhotoCard(
                            image: randomPhotos[reverseIndex],
                            index: reverseIndex,
                            total: min(randomPhotos.count, 5),
                            delay: Double(reverseIndex) * 0.15
                        )
                    }
                }
                .scaleEffect(animatePhotos ? 1.0 : 0.8)
                .opacity(animatePhotos ? 1.0 : 0.3)
                .position(x: geometry.size.width / 2, y: 250)
                
                // 标题文本
                Text("onboarding.page3.title".localized)
                    .font(.custom("Gloock-Regular", size: 30))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .frame(width: 324, height: 44)
                    .position(x: geometry.size.width / 2, y: 490) // y: 550 - 60
                
                // 描述文本
                Text("onboarding.page3.subtitle".localized)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.black.opacity(0.63))
                    .multilineTextAlignment(.center)
                    .frame(width: 266, height: 44)
                    .position(x: geometry.size.width / 2, y: 540) // y: 600 - 60
                
                // Continue按钮 - 保持原有位置，统一字体样式
                Button(action: {
                    // 防止连点保护
                    guard !isContinueButtonDisabled else { return }
                    isContinueButtonDisabled = true

                    // 在跳转前开始分析
                    onPrepareAnalysis?()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                    Logger.logPageNavigation(from: "Onboarding-3", to: "Onboarding-4")

                    // 1秒后重新启用按钮
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isContinueButtonDisabled = false
                    }
                }) {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color(hex: "0BA9D4"))
                        .frame(width: 267, height: 52)
                        .overlay(
                            Text("onboarding.page3.continue".localized)
                                .font(.system(size: 25, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: 150.0, height: 22)
                        )
                }
                .position(x: 62 + 267/2, y: 670)
                .contentShape(RoundedRectangle(cornerRadius: 50))
            }
        }
        .onAppear {
            loadRandomPhotos()
            startAnimations()
        }
    }
    
    private func loadRandomPhotos() {
        Task {
            let status = await requestPhotoPermission()
            guard status == .authorized || status == .limited else {
                Logger.logError(NSError(domain: "Photos", code: 1, userInfo: [NSLocalizedDescriptionKey: "照片权限未授权，状态: \(status.rawValue)"]), context: "加载随机照片")
                return
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 100
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            guard assets.count > 0 else {
                Logger.analytics.info("用户相册中没有照片")
                return
            }
            
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .fast
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.version = .current
            
            let totalAssets = min(assets.count, 100)
            let maxPhotos = min(5, assets.count)
            let indices = Array(0..<totalAssets).shuffled().prefix(maxPhotos)
            var loadedImages: [UIImage] = []
            
            Logger.analytics.info("开始加载 \(indices.count) 张随机照片，总共 \(assets.count) 张照片可选")
            
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
    
    @MainActor
    private func requestPhotoPermission() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if currentStatus == .notDetermined {
            Logger.analytics.info("请求照片访问权限")
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        
        return currentStatus
    }
    
    private func loadImageFromAsset(_ asset: PHAsset, imageManager: PHImageManager, options: PHImageRequestOptions) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 201, height: 290), // 使用固定分辨率
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
        withAnimation(.easeInOut(duration: 0.8)) {
            animatePhotos = true
        }
    }
}

// MARK: - Photo Card Component
struct PhotoCard: View {
    let image: UIImage
    let index: Int
    let total: Int
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .frame(width: 201, height: 290)
            .overlay(
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 193, height: 282)
                    .clipped()
                    .cornerRadius(8)
                    .padding(4)
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

#Preview {
    OnboardingPage3View_New(currentPage: .constant(2))
}
