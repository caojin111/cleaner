//
//  PaywallView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog
import AVKit
import AVFoundation

// MARK: - Scroll Direction Enum

enum ScrollDirection {
    case up
    case down
    case none
}

struct PaywallView: View {
    let isFromOnboarding: Bool
    
    init(isFromOnboarding: Bool = false) {
        self.isFromOnboarding = isFromOnboarding
    }
    @State private var selectedPlan: SubscriptionPlan? {
        didSet {
            // 强制触发UI更新
            if let plan = selectedPlan {
                Logger.subscription.debug("Paywall: selectedPlan已更新 - ID: \(plan.id), ProductID: \(plan.productIdentifier)")
            } else {
                Logger.subscription.debug("Paywall: selectedPlan已清空")
            }
        }
    }
    @State private var showMainApp = false
    @State private var animateFeatures = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettingsManager.shared
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var showCloseButton = false // 控制关闭按钮显示
    @State private var showRestoreAlert = false // 恢复购买结果弹窗
    @State private var restoreResultMessage = "" // 恢复购买结果消息
    @State private var showSuccessAlert = false // 订阅/restore成功弹窗
    @State private var successMessage = "" // 成功消息
    @State private var cachedPlans: [SubscriptionPlan] = [] // 缓存的订阅方案
    @State private var showingPrivacyPolicy = false // 显示隐私政策页面
    @State private var showingTermsOfUse = false // 显示使用条款页面
    
    // 悬浮按钮相关状态
    @State private var scrollOffset: CGFloat = 0
    @State private var buttonSectionFrame: CGRect = .zero
    @State private var isButtonFloating = false
    @State private var isPageInitialized = false // 跟踪页面是否已初始化
    @State private var previousScrollOffset: CGFloat = 0 // 记录上一次滚动位置
    @State private var scrollDirection: ScrollDirection = .none // 滚动方向
    @State private var isButtonOverlapping = false // 按钮是否重叠
    @State private var uiRefreshTrigger = false // 用于触发UI刷新的触发器
    @State private var buttonTextUpdateTrigger = false // 专门用于触发按钮文本更新的触发器

    // 计算属性 - 订阅按钮文本，根据selectedPlan的ID变化而更新
    private var subscribeButtonText: String {
        let _ = selectedPlan?.id // 强制依赖selectedPlan的id变化
        return getSubscribeButtonText()
    }

    // 直接在body中使用的按钮文本计算属性
    private var buttonText: String {
        // 强制依赖selectedPlan的变化，确保UI更新
        let _ = selectedPlan?.id
        let _ = selectedPlan?.productIdentifier
        let _ = buttonTextUpdateTrigger // 强制依赖触发器

        let result: String
        if let planId = selectedPlan?.productIdentifier {
            switch planId {
            case "yearly_29.99":
                result = "Start Your Free Trial"
            case "monthly_9.99", "weekly_2.99":
                result = "paywall.subscribe_now".localized
            default:
                result = "paywall.subscribe_now".localized
            }
        } else {
            result = "paywall.subscribe_now".localized
        }
        
        Logger.subscription.debug("Paywall: buttonText计算 - selectedPlan: \(selectedPlan?.productIdentifier ?? "nil"), 结果: \(result)")
        return result
    }

    // 倒计时相关状态
    @State private var countdownTime: TimeInterval = 3600 // 1小时 = 3600秒
    @State private var countdownTimer: Timer? = nil
    @State private var isCountdownActive = false

    // 倒计时持久化相关常量
    private let countdownEndTimeKey = "paywall_countdown_end_time"

    // 计算剩余时间
    private var remainingTime: TimeInterval {
        let now = Date().timeIntervalSince1970
        let endTime = UserDefaults.standard.double(forKey: countdownEndTimeKey)

        if endTime > now {
            return endTime - now
        } else {
            return 0 // 时间已到
        }
    }
    
    var body: some View {
        // 纯全屏视图，完全覆盖整个屏幕
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // 背景 - 白色
                Color.white
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // 顶部标题区域
                            headerSection

                            // 视频播放区域
                            videoSection

                            // 倒计时区域
                            countdownSection

                            // 订阅方案区域
                            subscriptionSection

                            // 功能特性区域
                            featuresSection

                            // 免费试用说明区域
                            trialInfoSection

                            // 底部条款
                            termsSection
                        }
                        .padding(.top, geometry.safeAreaInsets.top - 20)
                        .background(
                            GeometryReader { scrollGeometry in
                                let offset = scrollGeometry.frame(in: .named("scrollView")).minY
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: offset)
                            }
                        )
                    }
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        // 检测滚动方向
                        if value != scrollOffset {
                            let newDirection: ScrollDirection = value > scrollOffset ? .down : .up
                            scrollDirection = newDirection
                            previousScrollOffset = scrollOffset
                        }

                        scrollOffset = value
                        updateButtonFloatingState(geometry: geometry)
                    }
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
                                        Text(buttonText)
                                            .font(.seniorBody)
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.title3)
                                    }
                                    
                                    if let selectedPlan = selectedPlan, let trialDays = selectedPlan.trialDays {
                                        Text("paywall.trial_then".localized(trialDays, selectedPlan.price))
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
                            .disabled(selectedPlan == nil || storeManager.isLoading)
                            .opacity(selectedPlan == nil || storeManager.isLoading ? 0.6 : 1.0)
                            

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
                
                // 关闭按钮 - 浮动在内容之上，不占用空间
                if showCloseButton {
                    VStack {
                        HStack {
                            Spacer()
                            
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
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.9))
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, geometry.safeAreaInsets.top + 10)
                        
                        Spacer()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainTabView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTermsOfUse) {
            TermsOfUseView()
        }
        .onAppear {
            Logger.logPageNavigation(from: isFromOnboarding ? "Onboarding" : "More", to: "Paywall")
            startAnimations()
            showCloseButton = false
            isPageInitialized = false // 重置初始化状态
            isButtonFloating = false // 默认不显示悬浮按钮

            // 启动倒计时
            startCountdown()

            // 立即开始加载产品信息
            Task {
                await storeManager.loadProducts()
            }

            // 设置默认选中的方案（年订阅）- 确保年度计划被选中
            cachedPlans = getPlansWithRealPrices()
            // 查找年度计划（productIdentifier为"yearly_29.99"的计划）
            if let yearlyPlan = cachedPlans.first(where: { $0.productIdentifier == "yearly_29.99" }) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedPlan = yearlyPlan
                    buttonTextUpdateTrigger.toggle() // 强制触发按钮文本更新
                    Logger.subscription.debug("Paywall: 初始化设置selectedPlan - ID: \(yearlyPlan.id), ProductID: \(yearlyPlan.productIdentifier)")
                }
                Logger.subscription.info("默认选中年度订阅计划: \(yearlyPlan.title)")
            } else if !cachedPlans.isEmpty {
                // 如果找不到年度计划，选择第一个计划
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedPlan = cachedPlans[0]
                    buttonTextUpdateTrigger.toggle() // 强制触发按钮文本更新
                    Logger.subscription.debug("Paywall: 初始化设置selectedPlan - ID: \(cachedPlans[0].id), ProductID: \(cachedPlans[0].productIdentifier)")
                }
                Logger.subscription.info("默认选中第一个订阅计划: \(cachedPlans[0].title)")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showCloseButton = true
                }
            }
        }
        .onChange(of: storeManager.products) { _ in
            // 当产品加载完成时，更新选中的方案和价格
            cachedPlans = getPlansWithRealPrices()
            // 确保年度计划被选中
            if let yearlyPlan = cachedPlans.first(where: { $0.productIdentifier == "yearly_29.99" }) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedPlan = yearlyPlan
                    buttonTextUpdateTrigger.toggle() // 强制触发按钮文本更新
                }
                Logger.subscription.info("产品加载完成，选中年度订阅计划: \(yearlyPlan.title)")
            } else if !cachedPlans.isEmpty && selectedPlan == nil {
                // 如果找不到年度计划且当前没有选中方案，选择第一个计划
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedPlan = cachedPlans[0]
                    buttonTextUpdateTrigger.toggle() // 强制触发按钮文本更新
                }
                Logger.subscription.info("产品加载完成，选中第一个订阅计划: \(cachedPlans[0].title)")
            }
            // 强制刷新UI以显示最新价格
            uiRefreshTrigger.toggle()
        }
        .onChange(of: storeManager.isLoading) { _ in
            // 当加载状态改变时，刷新UI
            uiRefreshTrigger.toggle()
        }
        // 完全禁用所有手势关闭
        .interactiveDismissDisabled(true)
        .gesture(DragGesture()) // 禁用拖拽手势
        .onTapGesture { } // 禁用点击手势

        .alert("paywall.restore_result".localized, isPresented: $showRestoreAlert) {
            Button("paywall.ok".localized) { }
        } message: {
            Text(restoreResultMessage)
        }
        .alert("paywall.success_title".localized, isPresented: $showSuccessAlert) {
            Button("paywall.ok".localized) {
                if isFromOnboarding {
                    showMainApp = true
                    Logger.logPageNavigation(from: "Paywall", to: "MainApp")
                } else {
                    dismiss()
                }
            }
        } message: {
            Text(successMessage)
        }
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
        VStack(spacing: 12) {
            // 标题和描述 - 副标题在上方，减少间距
            VStack(spacing: 12) {
                Text("paywall.subtitle".localized)
                    .font(.custom("Afacad", size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "000000").opacity(0.61))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .offset(y: -11) // 向上移动11像素

                Text("paywall.title".localized)
                    .font(.custom("Gloock-Regular", size: 40))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "000000"))
                    .offset(y: -8) // 向上移动8像素
            }
            .padding(.top, 10) // 减少顶部空白
        }
    }

    // MARK: - Video Section

    private var videoSection: some View {
        VideoPlayerView()
            .padding(.horizontal, 0)
    }

    // MARK: - Countdown Section

    private var countdownSection: some View {
        VStack(spacing: 16) {
            // 限时优惠标题
            Text("paywall.countdown_title".localized)
                .font(.custom("Red Hat Display", size: 18))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "212121"))

            // 倒计时显示
            HStack(spacing: 4) {
                CountdownBlock(number: formatCountdownTime().hours, label: "paywall.hours".localized)
                Text(":")
                    .font(.custom("Poppins", size: 27))
                    .foregroundColor(Color(hex: "21B4DC"))

                CountdownBlock(number: formatCountdownTime().minutes, label: "paywall.minutes".localized)
                Text(":")
                    .font(.custom("Poppins", size: 27))
                    .foregroundColor(Color(hex: "21B4DC"))

                CountdownBlock(number: formatCountdownTime().seconds, label: "paywall.seconds".localized)
            }
        }
        .padding(.top, 32)
    }
    
    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(spacing: 12) {
            if storeManager.isLoading && storeManager.products.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("正在加载订阅方案...")
                        .font(.seniorCaption)
                        .foregroundColor(.seniorSecondary)
                }
                .padding(.vertical, 40)
            } else if let errorMessage = storeManager.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(.seniorDanger)
                    Text("加载失败: \(errorMessage)")
                        .font(.seniorCaption)
                        .foregroundColor(.seniorSecondary)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        Task {
                            await storeManager.loadProducts()
                        }
                    }
                    .font(.seniorBody)
                    .foregroundColor(.seniorPrimary)
                }
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(cachedPlans) { plan in
                        NewSubscriptionPlanCard(
                            plan: plan,
                            isSelected: selectedPlan?.id == plan.id,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedPlan = plan
                                    buttonTextUpdateTrigger.toggle() // 强制触发按钮文本更新
                                    Logger.subscription.debug("Paywall: 设置selectedPlan - ID: \(plan.id), ProductID: \(plan.productIdentifier)")
                                }
                                Logger.subscription.info("选择订阅方案: \(plan.title)")
                            }
                        )
                    }

                    // 订阅按钮移到这里，在三个订阅卡片下方
                    buttonSection
                }
                .padding(.horizontal, 29)
            }
        }
        .padding(.top, 20) // 减少顶部间距，让元素顶上来
        .padding(.bottom, 0) // 移除底部间距，让元素紧贴
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        GeometryReader { geometry in
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "0DCCFF"), location: 0.0),
                        .init(color: Color.white, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.18)
                
                VStack(spacing: 24) {
                    // 标题文本
                    Text("Unlock all features for the best\ncleaning experience")
                        .font(.custom("Gloock-Regular", size: 25)) // 使用Gloock字体
                        .foregroundColor(Color(hex: "212121"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 18)
                        .padding(.horizontal, 16)
                    
                                        // 功能对比区域 - 响应式布局设计，实现覆盖效果
                    ZStack {
                        // Free 列 - 底层
                        HStack(spacing: 16) {
                            VStack(spacing: 0) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white) // 改为白色
                                        .frame(height: 356) // 固定高度

                                    VStack(spacing: 16) {
                                        // Free标题区域加上Vector图标
                                        ZStack {
                                            Image("free_vector_icon")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 60, height: 45)

                                            Text("Free")
                                                .font(.custom("Afacad", size: 26))
                                                .fontWeight(.bold)
                                                .foregroundColor(Color(hex: "212121"))
                                                .offset(y: -1) // 向上移动3像素，让文字在图标内
                                        }
                                        .padding(.top, 16)
                                        .offset(x: -20, y: -10) // 向左移动10像素，向上移动30像素

                                        // Free功能列表
                                        VStack(spacing: 16) {
                                            FeatureCompareRow(
                                                icon: "xmark.circle",
                                                iconColor: Color(hex: "7A7F8D"),
                                                text: "Limited swipes\nchances",
                                                textColor: Color(hex: "7A7F8D")
                                            )

                                            FeatureCompareRow(
                                                icon: "xmark.circle",
                                                iconColor: Color(hex: "7A7F8D"),
                                                text: "More Ads",
                                                textColor: Color(hex: "7A7F8D")
                                            )

                                            FeatureCompareRow(
                                                icon: "xmark.circle",
                                                iconColor: Color(hex: "7A7F8D"),
                                                text: "No Analysis of memory professionals",
                                                textColor: Color(hex: "7A7F8D")
                                            )
                                        }
                                        .padding(.horizontal, 12)

                                        Spacer()
                                    }
                                }
                            }
                            .frame(width: 161) // 固定宽度161px

                            Spacer()
                        }
                        .padding(.horizontal, 16)

                        // Pro 列 - 上层，覆盖Free
                        HStack(spacing: 16) {
                            Spacer()

                            VStack(spacing: 0) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(hex: "1FB3DD"))
                                        .frame(height: 430) // 固定高度430px，增加20像素让文字完整显示

                                    VStack(spacing: 16) {
                                        // Pro标题区域加上Vector图标
                                        ZStack {
                                            Image("pro_vector_icon")
                                                .renderingMode(.template)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 60, height: 45)
                                                .foregroundColor(Color(hex: "F695F1")) // 应用颜色

                                            Text("Pro")
                                                .font(.custom("Afacad", size: 26))
                                                .fontWeight(.bold)
                                                .foregroundColor(Color.white)
                                                .offset(y: -1) // 向上移动3像素，让文字在图标内
                                        }
                                        .padding(.top, 16)
                                        .offset(x: -20, y: -30) // 向左移动10像素，向上移动30像素

                                        // Pro功能列表
                                        VStack(spacing: 16) {
                                            FeatureCompareRow(
                                                icon: "checkmark.circle.fill",
                                                iconColor: Color(hex: "F7C948"),
                                                text: "Unlimited swipes chances",
                                                textColor: Color.white
                                            )

                                            FeatureCompareRow(
                                                icon: "checkmark.circle.fill",
                                                iconColor: Color(hex: "F7C948"),
                                                text: "No ads",
                                                textColor: Color.white
                                            )

                                            FeatureCompareRow(
                                                icon: "checkmark.circle.fill",
                                                iconColor: Color(hex: "F7C948"),
                                                text: "Professional memory analysis keeps your phone safe and healthy",
                                                textColor: Color.white
                                            )
                                        }
                                        .padding(.horizontal, 12)

                                        Spacer()
                                    }
                                }
                            }
                            .frame(width: 217) // 固定宽度217px，向左扩展20像素，比Free宽
                        }
                        .padding(.horizontal, 16)

                        // 功能对比背景图片 - 响应式调整（对调位置）
                                                HStack(spacing: max(16, (geometry.size.width - 320) / 4)) {
                            Image("function_compare_background_2")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: min(105, geometry.size.width * 0.15 * 1.5), maxHeight: 105) // 变大1.5倍
                                .offset(x: -20, y: 130) // 向下移动40像素，向左移动20像素

                            Image("function_compare_background_1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: min(180, geometry.size.width * 0.25 * 1.5), maxHeight: 210) // 变大1.5倍
                                .offset(y: 128) // 向下移动28像素
                        }
                    }
                }
            }
        }
        .frame(height: 500) // 固定整体高度
        .padding(.top, 27)
    }

    // MARK: - Trial Info Section

    private var trialInfoSection: some View {
        VStack(spacing: 32) {
            // About free trial 标题
            VStack(spacing: 12) {
                Text("About free trial")
                    .font(.custom("Red Hat Display", size: 24))
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: "212121"))
            }
            
            // Trial benefits - 根据Figma设计重新布局
            VStack(spacing: 16) {
                TrialBenefitRow(
                    iconName: "perspective_img_cropped",
                    iconBackgroundColor: Color(hex: "E6FAEE"),
                    title: "No risk",
                    description: "Cancel anytime during the trial"
                )

                TrialBenefitRow(
                    iconName: "perspective_img_cropped",
                    iconBackgroundColor: Color(hex: "FFF3E4"),
                    title: "No charges",
                    description: "No hidden charges during the trial"
                )

                TrialBenefitRow(
                    iconName: "perspective_img_cropped",
                    iconBackgroundColor: Color(hex: "FFEFEF"),
                    title: "Easy to cancel",
                    description: "Cancel the trial by one click from Google Play"
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .padding(.top, 45)
        .padding(.horizontal, 17)
    }
    

    
    // MARK: - Button Section

    private var buttonSection: some View {
        VStack(spacing: 16) {
            // 主要订阅按钮 - 匹配Figma设计
            Button(action: {
                handleSubscription()
            }) {
                Text(buttonText)
                    .font(.custom("Afacad", size: 25)) // 增大5号到25
                    .fontWeight(.bold)
                    .foregroundColor(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(1.0) // 不允许缩放，确保完整显示
                    .layoutPriority(1) // 最高布局优先级
                    .frame(maxWidth: .infinity, alignment: .center) // 居中显示
                .padding(.horizontal, 20) // 适当的水平内边距
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "1FB3DD"))
                        .shadow(color: Color(hex: "1FB3DD").opacity(0.3), radius: 10, x: 0, y: 4)
                )
            }
            .disabled(selectedPlan == nil || storeManager.isLoading)
            .opacity(selectedPlan == nil || storeManager.isLoading ? 0.6 : 1.0)
        }
        .padding(.top, 8) // 减少顶部间距，让按钮紧贴订阅卡片
        .opacity(isButtonFloating ? 0 : 1) // 当悬浮按钮显示时，隐藏页面按钮
        .animation(.easeInOut(duration: 0.3), value: isButtonFloating)
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 20) {
            // Subscription Terms 标题
            Text("Subscription Terms")
                .font(.custom("Afacad", size: 25))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "000000"))
            
            // 条款说明文本
            VStack(alignment: .leading, spacing: 8) {
                Text("· Subscriptions will auto-renew unless cancelled 24 hours before the current period ends")
                Text("· You can manage subscriptions and turn off auto-renewval in Apple ID settings")
                Text("· Cancelling during the free trial period will not incur any charges")
            }
            .font(.custom("Poppins", size: 15))
            .foregroundColor(Color(hex: "000000").opacity(0.61))
            .lineSpacing(4)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 20)
            
            // 底部链接
            Text("Privacy Policy             Terms of Use             Restore Purchase")
                .font(.custom("Inter", size: 12))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "1FB3DD"))
                .multilineTextAlignment(.center)
                .onTapGesture {
                    // 可以在这里处理点击事件，区分不同的链接
                }
        }
        .padding(.top, 45)
        .padding(.bottom, 30)
    }
    
    // MARK: - Helper Methods

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
            animateFeatures = true
        }
    }

    private func startCountdown() {
        countdownTimer?.invalidate()

        // 检查是否有持久化的倒计时
        let savedEndTime = UserDefaults.standard.double(forKey: countdownEndTimeKey)
        let now = Date().timeIntervalSince1970

        if savedEndTime > now {
            // 还有剩余时间，使用剩余时间
            countdownTime = savedEndTime - now
            Logger.subscription.debug("Paywall: 使用持久化倒计时，剩余时间: \(Int(countdownTime))秒")
        } else {
            // 时间已到或首次使用，重新开始1小时倒计时
            countdownTime = 3600
            let newEndTime = now + 3600
            UserDefaults.standard.set(newEndTime, forKey: countdownEndTimeKey)
            Logger.subscription.debug("Paywall: 开始新的倒计时")
        }

        isCountdownActive = true

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownTime > 0 {
                countdownTime -= 1
            } else {
                // 倒计时结束，重置为1小时
                countdownTime = 3600
                let newEndTime = Date().timeIntervalSince1970 + 3600
                UserDefaults.standard.set(newEndTime, forKey: countdownEndTimeKey)
                Logger.subscription.debug("Paywall: 倒计时重置，开始新的1小时")
            }
        }
    }

    private func formatCountdownTime() -> (hours: String, minutes: String, seconds: String) {
        let hours = Int(countdownTime) / 3600
        let minutes = Int(countdownTime) % 3600 / 60
        let seconds = Int(countdownTime) % 60

        return (
            String(format: "%02d", hours),
            String(format: "%02d", minutes),
            String(format: "%02d", seconds)
        )
    }
    
    private func getPlansWithRealPrices() -> [SubscriptionPlan] {
        let basePlans = SubscriptionPlan.getPlans()

        // 添加调试日志
        for plan in basePlans {
            Logger.subscription.debug("Paywall: 原始方案 - ID: \(plan.productIdentifier), trialDays: \(String(describing: plan.trialDays))")
        }

        return basePlans.map { plan in
            // 根据产品ID获取真实价格
            let realPrice: String
            switch plan.productIdentifier {
            case "yearly_29.99":
                realPrice = storeManager.yearlyPrice
            case "monthly_9.99":
                realPrice = storeManager.monthlyPrice
            case "weekly_2.99":
                realPrice = storeManager.weeklyPrice
            default:
                realPrice = plan.price
            }

            // 创建新的计划实例，使用真实价格，但保持原有的id和trialDays
            let newPlan = SubscriptionPlan(
                id: plan.id,
                title: plan.title,
                price: realPrice,
                originalPrice: plan.originalPrice,
                duration: plan.duration,
                features: plan.features,
                isRecommended: plan.isRecommended,
                productIdentifier: plan.productIdentifier,
                trialDays: plan.trialDays
            )

            Logger.subscription.debug("Paywall: 更新后方案 - ID: \(newPlan.productIdentifier), trialDays: \(String(describing: newPlan.trialDays)), price: \(newPlan.price)")

            return newPlan
        }
    }
    
    private func handleSubscription() {
        guard let selectedPlan = selectedPlan else {
            Logger.subscription.error("未选择订阅方案")
            return
        }
        
        Logger.subscription.info("开始订阅流程: \(selectedPlan.title)")
        
        // 获取对应的StoreKit产品
        guard let product = storeManager.getProduct(identifier: selectedPlan.productIdentifier) else {
            Logger.subscription.error("未找到产品: \(selectedPlan.productIdentifier)")
            return
        }
        
        // 执行购买
        Task {
            do {
                if let transaction = try await storeManager.purchase(product) {
                    // 购买成功
                    await MainActor.run {
                        userSettings.isSubscribed = true
                        userSettings.markOnboardingCompleted()
                        successMessage = "paywall.subscription_success".localized
                        showSuccessAlert = true
                        Logger.subscription.info("订阅成功: \(selectedPlan.title)")
                    }
                } else {
                    // 用户取消或待处理
                    Logger.subscription.info("订阅未完成: \(selectedPlan.title)")
                }
            } catch {
                await MainActor.run {
                    Logger.subscription.error("订阅失败: \(error.localizedDescription)")
                    // 这里可以显示错误提示
                }
            }
        }
    }
    
    private func handleRestorePurchases() {
        Logger.subscription.info("开始恢复购买流程")
        
        Task {
            do {
                let hasValidSubscription = try await storeManager.restorePurchases()
                
                            await MainActor.run {
                if hasValidSubscription {
                    userSettings.isSubscribed = true
                    successMessage = "paywall.restore_success_message".localized
                    showSuccessAlert = true
                    Logger.subscription.info("恢复购买成功，找到有效订阅")
                } else {
                    restoreResultMessage = "paywall.restore_no_subscription".localized
                    showRestoreAlert = true
                    Logger.subscription.info("恢复购买完成，但未找到有效订阅")
                }
            }
            } catch {
                await MainActor.run {
                    restoreResultMessage = "paywall.restore_failed".localized(error.localizedDescription)
                    showRestoreAlert = true
                    Logger.subscription.error("恢复购买失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func getSubscribeButtonText() -> String {
        guard let selectedPlan = selectedPlan else {
            Logger.subscription.debug("Paywall: 未选择订阅方案，返回默认文本")
            return "paywall.subscribe_now".localized
        }

        Logger.subscription.debug("Paywall: 当前选中方案 - ID: \(selectedPlan.productIdentifier)")

        // 根据产品ID直接判断按钮文本
        switch selectedPlan.productIdentifier {
        case "yearly_29.99":
            Logger.subscription.debug("Paywall: 年订阅，显示'start_free_trial'")
            return "paywall.start_free_trial".localized
        case "monthly_9.99":
            Logger.subscription.debug("Paywall: 月订阅，显示'subscribe_now'")
            return "paywall.subscribe_now".localized
        case "weekly_2.99":
            Logger.subscription.debug("Paywall: 周订阅，显示'subscribe_now'")
            return "paywall.subscribe_now".localized
        default:
            Logger.subscription.debug("Paywall: 未知订阅类型，显示'subscribe_now'")
            return "paywall.subscribe_now".localized
        }
    }

    // 在body中直接调用的函数，确保每次渲染都会重新计算
    private func getButtonTextForSelectedPlan() -> String {
        guard let selectedPlan = selectedPlan else {
            return "paywall.subscribe_now".localized
        }

        // 根据产品ID直接判断按钮文本
        switch selectedPlan.productIdentifier {
        case "yearly_29.99":
            return "paywall.start_free_trial".localized
        case "monthly_9.99", "weekly_2.99":
            return "paywall.subscribe_now".localized
        default:
            return "paywall.subscribe_now".localized
        }
    }

}



// MARK: - Subscription Plan Card

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var borderAnimation = false
    @State private var animationEnabled = false
    
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
                            Text("paywall.recommended".localized)
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
                                
                                Text("paywall.discount".localized)
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
                                                            Text("paywall.trial_days".localized(trialDays))
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
                            .scaleEffect(borderAnimation ? 1.08 : 1.0)
                            .opacity(borderAnimation ? 0.6 : 1.0)
                    )
                    .shadow(
                        color: isSelected ? Color.seniorPrimary.opacity(0.3) : .gray.opacity(0.1),
                        radius: isSelected ? 12 : 2,
                        x: 0,
                        y: isSelected ? 6 : 1
                    )
            )
            .animation(animationEnabled ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .easeOut(duration: 0.2), value: borderAnimation)
            .onChange(of: isSelected) { newValue in
                if newValue {
                    // 选中时启用动画并开始闪烁
                    animationEnabled = true
                    borderAnimation = true
                    Logger.ui.debug("订阅卡片选中: \(plan.title), 动画已启用")
                } else {
                    // 取消选中时禁用动画并重置状态
                    animationEnabled = false
                    borderAnimation = false
                    Logger.ui.debug("订阅卡片取消选中: \(plan.title), 动画已禁用")
                }
            }
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



// MARK: - Countdown Block Component

struct CountdownBlock: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            // 数字
            Text(number)
                .font(.custom("Poppins", size: 35))
                .fontWeight(.bold) // 加粗字体
                .foregroundColor(Color(hex: "21B4DC"))

            // 标签
            Text(label)
                .font(.custom("Poppins", size: 13))
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "7A7F8D"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 70, height: 80) // 增加宽度从64到70，避免SECONDS换行
    }
}

// MARK: - Video Player Component

struct VideoPlayerView: View {
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true) // 禁止用户交互
                    .allowsHitTesting(false) // 禁止触摸事件
                    .onAppear {
                        // 确保视频静音
                        player.isMuted = true
                        player.volume = 0.0
                        player.play()

                        // 设置循环播放
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player.currentItem,
                            queue: .main
                        ) { _ in
                            player.seek(to: .zero)
                            // 重新确保静音
                            player.isMuted = true
                            player.volume = 0.0
                            player.play()
                        }
                    }
                    // 添加音频轨道监听，确保静音
                    .onChange(of: player.currentItem) { newItem in
                        if let item = newItem {
                            // 确保所有音频轨道都被静音
                            for track in item.tracks {
                                if track.assetTrack?.mediaType == .audio {
                                    track.isEnabled = false
                                }
                            }
                        }
                    }
                    .onDisappear {
                        player.pause()
                        NotificationCenter.default.removeObserver(self)
                    }
            } else {
                // 加载视频
                Color.clear
                    .onAppear {
                        if let videoURL = Bundle.main.url(forResource: "cljux-fd6hd", withExtension: "mp4") {
                            player = AVPlayer(url: videoURL)
                            // 设置视频静音
                            player?.isMuted = true
                            player?.volume = 0.0

                            // 设置音频会话为静音模式
                            do {
                                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                                try AVAudioSession.sharedInstance().setActive(true)
                            } catch {
                                Logger.subscription.debug("设置音频会话失败: \(error.localizedDescription)")
                            }
                        }
                    }
            }

            // 播放按钮覆盖层
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("crown_icon")
                        .resizable()
                        .frame(width: 58, height: 59)
                        .offset(y: 92)
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(height: 219)
    }
}

// MARK: - New Subscription Plan Card

struct NewSubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var borderAnimation = false
    @State private var animationEnabled = false

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color(hex: "1FB3DD") : Color(hex: "D9D9D9"), lineWidth: 3)
                    )

                VStack(spacing: 0) {
                    // 顶部推荐条
                    if plan.isRecommended {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "21B4DC")) // 还原为蓝色
                                .frame(height: 26)
                            Text("SAVE 78%")
                                .font(.custom("Afacad", size: 16))
                                .fontWeight(.bold)
                                .foregroundColor(Color.white)
                        }
                        .padding(.top, 1)
                    }

                    // 主要内容
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(plan.title)
                                    .font(.custom("Afacad", size: 23)) // 缩小5号：28-5=23
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "212121"))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)

                                if plan.isRecommended {
                                    Text("Recommended")
                                        .font(.custom("Afacad", size: 14)) // 调整字体大小
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color(hex: "FFAC00"))
                                        .cornerRadius(10)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                            }

                            Text(plan.price)
                                .font(.custom("Poppins", size: 28))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "21B4DC"))

                            if let trialDays = plan.trialDays {
                                Text("7 days free trial")
                                    .font(.custom("Poppins", size: 15))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "33CC66"))
                            }
                        }

                        Spacer()

                        // 选择指示器
                        VStack {
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundColor(isSelected ? Color(hex: "1FB3DD") : Color(hex: "D9D9D9"))
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .frame(height: plan.isRecommended ? 140 : 93) // 非推荐卡片高度为推荐卡片的2/3
            .animation(animationEnabled ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .easeOut(duration: 0.2), value: borderAnimation)
            .onChange(of: isSelected) { newValue in
                if newValue {
                    animationEnabled = true
                    borderAnimation = true
                } else {
                    animationEnabled = false
                    borderAnimation = false
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}



// MARK: - Feature Compare Row

struct FeatureCompareRow: View {
    let icon: String
    let iconColor: Color
    let text: String
    let textColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 21))
                .foregroundColor(iconColor)
                .frame(width: 21, height: 21)
                .flexibleFrame(minWidth: 21)

            Text(text)
                .font(.custom("Poppins", size: 16))
                .fontWeight(.medium)
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .lineLimit(nil) // 移除行数限制，让文字完整显示
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - FlexibleFrame View Modifier

extension View {
    func flexibleFrame(minWidth: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, maxHeight: CGFloat? = nil) -> some View {
        self.frame(minWidth: minWidth, maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight)
    }
}

// MARK: - Trial Benefit Row

struct TrialBenefitRow: View {
    let iconName: String
    let iconBackgroundColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 图标容器
            ZStack {
                RoundedRectangle(cornerRadius: 999)
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)

                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Red Hat Display", size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "212121"))

                Text(description)
                    .font(.custom("Poppins", size: 16))
                    .foregroundColor(Color(hex: "7A7A7A"))
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}

#Preview {
    PaywallView(isFromOnboarding: false)
} 
