import SwiftUI
import Foundation
import OSLog
import AVKit

struct OnboardingTransitionView_New: View {
    @Binding var currentPage: Int
    @State private var progress: CGFloat = 0.0
    @State private var progressText = "0%"
    @State private var player: AVPlayer?
    @State private var isExiting = false
    @State private var hideVideo = false
    @State private var analysisTask: Task<Void, Never>?
    @State private var analysisComplete = false
    
    private let analysisTime: Double = 5.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                // 顶部视频播放器
                if let player = player, !hideVideo {
                    VideoPlayer(player: player)
                        .frame(width: geometry.size.width, height: 300)
                        .allowsHitTesting(false)
                        .overlay(
                            // 白色蒙版遮掉视频黑边
                            Group {
                                if !isExiting {
                                    Path { path in
                                        // 外层矩形
                                        path.addRect(CGRect(x: 0, y: 0, width: 410, height: 300))
                                        // 减去中间圆角矩形
                                        path.addRoundedRect(in: CGRect(x: (410-300)/2-4, y: (300-300)/2, width: 300, height: 300), cornerRadii: RectangleCornerRadii(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10))
                                    }
                                    .fill(Color.white, style: FillStyle(eoFill: true))
                                }
                            }
                        )
                        .position(x: geometry.size.width/2, y: 200)
                }
                
                // 标题文本
                Text("onboarding.transition.analyzing".localized)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .frame(width: 324, height: 44)
                    .position(x: geometry.size.width/2, y: 450) // y: 450 - 50
                
                // 描述文本
                Text("onboarding.transition.subtitle".localized)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .frame(width: 266, height: 44)
                    .position(x: geometry.size.width/2, y: 500) // y: 500 - 50
                
                // 进度条和进度文本
                VStack(spacing: 16) {
                    // 进度条
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0.0, to: progress)
                            .stroke(
                                Color(red: 0.043, green: 0.663, blue: 0.831), // #0BA9D4
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        Text(progressText)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.043, green: 0.663, blue: 0.831))
                    }
                    
                    // 进度描述文本
                    Text("onboarding.transition.progress_text".localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .position(x: geometry.size.width/2, y: 650) // y: 650 - 50
            }
        }
        .onAppear {
            setupVideo()
            startAnalysis()
            Logger.logPageNavigation(from: "Onboarding-3", to: "AI-Analysis")
        }
    }
    
    private func setupVideo() {
        if let videoURL = Bundle.main.url(forResource: "0A6401D9-E4F7-4C50-8425-441D715D1E89", withExtension: "MP4") {
            let player = AVPlayer(url: videoURL)
            self.player = player
            
            // 设置循环播放
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                player.seek(to: .zero)
                player.play()
            }
            
            player.play()
        } else {
            Logger.logError(NSError(domain: "Video", code: 1, userInfo: [NSLocalizedDescriptionKey: "视频资源未找到"]), context: "加载过渡页视频")
        }
    }
    
    private func startAnalysis() {
        // 开始真实的分析操作
        analysisTask = Task {
            // 调用PhotoAnalyzer进行真实分析
            await PhotoAnalyzer.shared.startAnalysis()
            await MainActor.run {
                analysisComplete = true
            }
            Logger.analytics.info("真实分析操作已完成")
        }
        
        // 开始进度条动画，但根据分析完成情况调整速度
        startProgressAnimation()
        
        // 监控分析完成状态
        Task {
            // 等待最短展示时间（5秒）
            try? await Task.sleep(nanoseconds: UInt64(analysisTime * 1_000_000_000))
            
            // 如果分析还没完成，继续等待，但最多等待额外3秒
            var extraWaitTime: Double = 0
            while !analysisComplete && extraWaitTime < 3.0 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒检查一次
                extraWaitTime += 0.1
            }
            
            // 分析完成后，确保进度条到达100%
            await MainActor.run {
                // 如果进度还没到99%，先快速到达99%
                if progress < 0.99 {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        progress = 0.99
                        progressText = "99%"
                    }
                }
                
                // 然后平滑到达100%
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        progress = 1.0
                        progressText = "100%"
                    }
                }
            }
            
            // 等待进度条动画完成
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 开始退出动画
            await MainActor.run {
                // 第一步：视频消失
                withAnimation(.easeInOut(duration: 0.3)) {
                    hideVideo = true
                }
                
                // 第二步：0.3秒后蒙版消失
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isExiting = true
                }
                
                // 第三步：0.2秒后页面消失
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                    
                    // 清理资源
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        player?.pause()
                        player = nil
                        analysisTask?.cancel()
                        analysisTask = nil
                    }
                }
                
                Logger.logPageNavigation(from: "AI-Analysis", to: "Onboarding-4")
                Logger.analytics.info("AI分析过渡页面完成")
            }
        }
    }
    
    private func startProgressAnimation() {
        // 定义检查点和每个检查点的时间比例
        let checkpoints = [
            (progress: 0.05, timeRatio: 0.1),  // 5%用时10%
            (progress: 0.25, timeRatio: 0.2),  // 25%用时20%
            (progress: 0.45, timeRatio: 0.2),  // 45%用时20%
            (progress: 0.75, timeRatio: 0.25), // 75%用时25%
            (progress: 0.99, timeRatio: 0.25)  // 99%用时25%
        ]
        
        var currentDelay: Double = 0
        
        // 为每个检查点创建动画
        for (index, checkpoint) in checkpoints.enumerated() {
            let duration = analysisTime * checkpoint.timeRatio
            
            DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                // 如果分析已完成，不再更新进度
                if !analysisComplete {
                    withAnimation(.easeInOut(duration: duration)) {
                        progress = checkpoint.progress
                        progressText = "\(Int(checkpoint.progress * 100))%"
                    }
                    Logger.analytics.debug("AI分析进度: \(Int(checkpoint.progress * 100))%")
                }
            }
            
            currentDelay += duration
        }
    }
}

#Preview {
    OnboardingTransitionView_New(currentPage: .constant(3))
}
