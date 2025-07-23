//
//  PaywallView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog

// MARK: - Scroll Direction Enum

enum ScrollDirection {
    case up
    case down
    case none
}

struct PaywallView: View {
    var isFromOnboarding: Bool = false
    @State private var selectedPlan = SubscriptionPlan.plans[0]
    @State private var showMainApp = false
    @State private var animateFeatures = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettingsManager.shared
    @State private var showCloseButton = false // 控制关闭按钮显示
    
    // 悬浮按钮相关状态
    @State private var scrollOffset: CGFloat = 0
    @State private var buttonSectionFrame: CGRect = .zero
    @State private var isButtonFloating = false
    @State private var isPageInitialized = false // 跟踪页面是否已初始化
    @State private var previousScrollOffset: CGFloat = 0 // 记录上一次滚动位置
    @State private var scrollDirection: ScrollDirection = .none // 滚动方向
    @State private var isButtonOverlapping = false // 按钮是否重叠
    
    var body: some View {
        // 纯全屏视图，完全覆盖整个屏幕
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // 背景渐变 - 覆盖整个屏幕
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.seniorBackground,
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 30) {
                            // 头部区域
                            headerSection
                            
                            // 功能介绍
                            featuresSection
                            
                            // 订阅方案
                            subscriptionSection
                            
                            // 按钮区域 - 添加ID用于跟踪位置
                            buttonSection
                                .id("buttonSection")
                                .background(
                                    GeometryReader { buttonGeometry in
                                        Color.clear
                                            .onAppear {
                                                buttonSectionFrame = buttonGeometry.frame(in: .named("scrollView"))
                                                
                                                // 延迟标记页面为已初始化，确保布局完成
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    isPageInitialized = true
                                                }
                                            }
                                    }
                                )
                            
                            // 底部条款
                            termsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, geometry.safeAreaInsets.top + 20) // 适配安全区域
                        .background(
                            GeometryReader { scrollGeometry in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: scrollGeometry.frame(in: .named("scrollView")).minY)
                            }
                        )
                    }
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        // 检测滚动方向
                        if value != scrollOffset {
                            scrollDirection = value > scrollOffset ? .down : .up
                            previousScrollOffset = scrollOffset
                        }
                        
                        scrollOffset = value
                        updateButtonFloatingState(geometry: geometry)
                    }
                }

                // 关闭按钮绝对定位右上角，渐显动画
                if showCloseButton {
                    Button(action: {
                        if isFromOnboarding {
                            userSettings.markOnboardingCompleted()
                            showMainApp = true
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.seniorSecondary)
                            .padding(16)
                    }
                    .position(x: geometry.size.width - 30, y: geometry.safeAreaInsets.top + 30)
                    .opacity(showCloseButton ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: showCloseButton)
                }
                
                // 悬浮订阅按钮
                if isButtonFloating {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            // 主要订阅按钮
                            Button(action: {
                                handleSubscription()
                            }) {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text(selectedPlan.trialDays != nil ? "开始免费试用" : "立即订阅")
                                            .font(.seniorBody)
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.title3)
                                    }
                                    
                                    if let trialDays = selectedPlan.trialDays {
                                        Text("\(trialDays)天免费，然后\(selectedPlan.price)")
                                            .font(.seniorCaption)
                                            .opacity(0.8)
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.seniorPrimary,
                                                    Color.seniorPrimary.opacity(0.8)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color.seniorPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                                )
                            }
                            

                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                        .background(
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                        )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: isButtonFloating)
                }
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainTabView()
        }
        .onAppear {
            Logger.logPageNavigation(from: isFromOnboarding ? "Onboarding" : "More", to: "Paywall")
            startAnimations()
            showCloseButton = false
            isPageInitialized = false // 重置初始化状态
            isButtonFloating = false // 默认不显示悬浮按钮
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showCloseButton = true
                }
            }
        }
        // 完全禁用所有手势关闭
        .interactiveDismissDisabled(true)
        .gesture(DragGesture()) // 禁用拖拽手势
        .onTapGesture { } // 禁用点击手势
    }
    
    // MARK: - 悬浮按钮状态更新
    
    private func updateButtonFloatingState(geometry: GeometryProxy) {
        let screenHeight = geometry.size.height
        let buttonBottomPosition = buttonSectionFrame.maxY + scrollOffset
        
        // 如果页面还未初始化，默认不显示悬浮按钮
        if !isPageInitialized {
            isButtonFloating = false
            return
        }
        
        // 计算按钮重叠状态
        // 当按钮底部位置接近屏幕底部时，认为按钮重叠
        let overlapThreshold: CGFloat = 50 // 增加重叠检测阈值，让重叠检测更敏感
        let isOverlapping = abs(buttonBottomPosition - screenHeight) < overlapThreshold
        
        // 更新重叠状态
        if isOverlapping != isButtonOverlapping {
            isButtonOverlapping = isOverlapping
        }
        
        // 智能按钮切换逻辑
        var shouldFloat = false
        
        if isOverlapping {
            // 按钮重叠时，根据滚动方向决定显示哪个按钮
            switch scrollDirection {
            case .down:
                // 向下滚动时，隐藏悬浮按钮，显示页面按钮
                shouldFloat = false
            case .up:
                // 向上滚动时，显示悬浮按钮，隐藏页面按钮
                shouldFloat = true
            case .none:
                // 无滚动时，保持当前状态
                shouldFloat = isButtonFloating
            }
        } else {
            // 按钮不重叠时，根据位置决定
            if buttonBottomPosition > screenHeight {
                // 按钮超出屏幕，显示悬浮按钮
                shouldFloat = true
            } else {
                // 按钮在屏幕内，隐藏悬浮按钮
                shouldFloat = false
            }
        }
        
        // 更新悬浮状态
        if shouldFloat != isButtonFloating {
            withAnimation(.easeInOut(duration: 0.3)) {
                isButtonFloating = shouldFloat
            }
            print("PaywallView: 悬浮按钮状态更新 - 应该悬浮: \(shouldFloat), 重叠: \(isOverlapping), 方向: \(scrollDirection), 按钮位置: \(buttonBottomPosition), 屏幕高度: \(screenHeight)")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Logo和标题
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.3), radius: 8)
                
                Text("CleanUp AI Pro")
                    .font(.seniorLargeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("解锁全部功能，获得最佳清理体验")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            ForEach(0..<proFeatures.count, id: \.self) { index in
                FeatureRow(
                    feature: proFeatures[index],
                    delay: Double(index) * 0.2
                )
                .opacity(animateFeatures ? 1.0 : 0.0)
                .offset(x: animateFeatures ? 0 : 50)
            }
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            Text("选择订阅方案")
                .font(.seniorTitle)
                .fontWeight(.bold)
                .foregroundColor(.seniorText)
            
            VStack(spacing: 12) {
                ForEach(SubscriptionPlan.plans) { plan in
                    SubscriptionPlanCard(
                        plan: plan,
                        isSelected: selectedPlan.id == plan.id,
                        onSelect: {
                            selectedPlan = plan
                            Logger.subscription.info("选择订阅方案: \(plan.title)")
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Button Section
    
    private var buttonSection: some View {
        VStack(spacing: 16) {
            // 主要订阅按钮
            Button(action: {
                handleSubscription()
            }) {
                VStack(spacing: 8) {
                    HStack {
                        Text(selectedPlan.trialDays != nil ? "开始免费试用" : "立即订阅")
                            .font(.seniorBody)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    
                    if let trialDays = selectedPlan.trialDays {
                        Text("\(trialDays)天免费，然后\(selectedPlan.price)")
                            .font(.seniorCaption)
                            .opacity(0.8)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.seniorPrimary,
                                    Color.seniorPrimary.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.seniorPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                )
            }
            

        }
        .opacity(isButtonFloating ? 0 : 1) // 当悬浮按钮显示时，隐藏页面按钮
        .animation(.easeInOut(duration: 0.3), value: isButtonFloating)
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            Text("订阅说明")
                .font(.seniorCaption)
                .fontWeight(.semibold)
                .foregroundColor(.seniorText)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("• 订阅将自动续费，除非在当前周期结束前24小时取消")
                Text("• 可在Apple ID设置中管理订阅和关闭自动续费")
                Text("• 免费试用期间取消不会产生费用")
            }
            .font(.caption)
            .foregroundColor(.seniorSecondary)
            .multilineTextAlignment(.leading)
            
            HStack(spacing: 20) {
                Button("隐私政策") { }
                    .font(.caption)
                    .foregroundColor(.seniorPrimary)
                
                Button("使用条款") { }
                    .font(.caption)
                    .foregroundColor(.seniorPrimary)
                
                Button("恢复购买") { }
                    .font(.caption)
                    .foregroundColor(.seniorPrimary)
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Helper Methods
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
            animateFeatures = true
        }
    }
    
    private func handleSubscription() {
        Logger.subscription.info("开始订阅流程: \(selectedPlan.title)")
        
        // TODO: 实现真实的订阅逻辑
        // 标记用户已完成首次启动流程
        userSettings.markOnboardingCompleted()
        
        // 跳转到主应用
        if isFromOnboarding {
            showMainApp = true
            Logger.logPageNavigation(from: "Paywall", to: "MainApp")
        } else {
            dismiss()
        }
    }
    
    // MARK: - Pro Features Data
    
    private let proFeatures = [
        ProFeature(icon: "🚀", title: "无限制清理重复文件", description: "AI算法精准识别"),
        ProFeature(icon: "📱", title: "释放存储空间", description: "最多节省80%空间"),
        ProFeature(icon: "🔒", title: "安全删除保护", description: "回收站机制防误删"),
        ProFeature(icon: "⚡", title: "批量处理", description: "一键清理数千文件"),
        ProFeature(icon: "🆓", title: "无广告", description: "纯净体验无打扰"), // 新增
    ]
}

// MARK: - Pro Feature Model

struct ProFeature {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let feature: ProFeature
    let delay: Double
    
    var body: some View {
        HStack(spacing: 16) {
            Text(feature.icon)
                .font(.largeTitle)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.seniorBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.seniorText)
                
                Text(feature.description)
                    .font(.seniorCaption)
                    .foregroundColor(.seniorSecondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.seniorSuccess)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .animation(.easeInOut(duration: 0.5).delay(delay), value: delay)
    }
}

// MARK: - Subscription Plan Card

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.title)
                            .font(.seniorBody)
                            .fontWeight(.bold)
                            .foregroundColor(.seniorText)
                        
                        if plan.isRecommended {
                            Text("推荐")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.orange)
                                )
                        }
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // 如果有原价，显示折扣效果
                        if let originalPrice = plan.originalPrice {
                            HStack(spacing: 8) {
                                Text(originalPrice)
                                    .font(.seniorCaption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.seniorSecondary)
                                    .strikethrough(true, color: .seniorSecondary)
                                
                                Text("40% OFF")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.red)
                                    )
                            }
                        }
                        
                        Text(plan.price)
                            .font(.seniorTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.seniorPrimary)
                    }
                    
                    if let trialDays = plan.trialDays {
                        Text("\(trialDays)天免费试用")
                            .font(.seniorCaption)
                            .foregroundColor(.seniorSuccess)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .seniorPrimary : .seniorSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.cornerRadius)
                            .stroke(
                                isSelected ? Color.seniorPrimary : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.seniorPrimary.opacity(0.2) : .gray.opacity(0.1),
                        radius: isSelected ? 8 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    PaywallView()
} 
