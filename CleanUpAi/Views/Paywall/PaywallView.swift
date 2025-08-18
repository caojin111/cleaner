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
    let isFromOnboarding: Bool
    
    init(isFromOnboarding: Bool = false) {
        self.isFromOnboarding = isFromOnboarding
    }
    @State private var selectedPlan: SubscriptionPlan?
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
    
    var body: some View {
        // 纯全屏视图，完全覆盖整个屏幕
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // 背景渐变 - 覆盖整个屏幕
                let gradientColors = [Color.seniorBackground, Color.white]
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
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
                        .padding(.top, geometry.safeAreaInsets.top + 10) // 减少顶部间距
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
                                        Text(selectedPlan?.trialDays != nil ? "paywall.start_free_trial".localized : "paywall.subscribe_now".localized)
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
                }
                Logger.subscription.info("默认选中年度订阅计划: \(yearlyPlan.title)")
            } else if !cachedPlans.isEmpty {
                // 如果找不到年度计划，选择第一个计划
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedPlan = cachedPlans[0]
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
                }
                Logger.subscription.info("产品加载完成，选中年度订阅计划: \(yearlyPlan.title)")
            } else if !cachedPlans.isEmpty && selectedPlan == nil {
                // 如果找不到年度计划且当前没有选中方案，选择第一个计划
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedPlan = cachedPlans[0]
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
        VStack(spacing: 20) {
            // Logo和标题
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.3), radius: 8)
                
                Text("paywall.title".localized)
                    .font(.seniorLargeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("paywall.subtitle".localized)
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
            Text("paywall.select_plan".localized)
                .font(.seniorTitle)
                .fontWeight(.bold)
                .foregroundColor(.seniorText)
            
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
                        SubscriptionPlanCard(
                            plan: plan,
                            isSelected: selectedPlan?.id == plan.id,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedPlan = plan
                                }
                                Logger.subscription.info("选择订阅方案: \(plan.title)")
                            }
                        )

                    }
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
                        Text(selectedPlan?.trialDays != nil ? "paywall.start_free_trial".localized : "paywall.subscribe_now".localized)
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
                                gradient: Gradient(colors: [Color.seniorPrimary, Color.seniorPrimary.opacity(0.8)]),
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
        .opacity(isButtonFloating ? 0 : 1) // 当悬浮按钮显示时，隐藏页面按钮
        .animation(.easeInOut(duration: 0.3), value: isButtonFloating)
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            Text("paywall.subscription_terms".localized)
                .font(.seniorCaption)
                .fontWeight(.semibold)
                .foregroundColor(.seniorText)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("paywall.term1".localized)
                Text("paywall.term2".localized)
                Text("paywall.term3".localized)
            }
            .font(.caption)
            .foregroundColor(.seniorSecondary)
            .multilineTextAlignment(.leading)
            
            HStack(spacing: 20) {
                Button("paywall.privacy_policy".localized) { 
                    // 直接显示隐私政策页面
                    Logger.ui.info("用户从Paywall点击隐私政策")
                    showingPrivacyPolicy = true
                }
                .font(.caption)
                .foregroundColor(.seniorPrimary)
                
                Button("paywall.terms_of_use".localized) { 
                    // 直接显示使用条款页面
                    Logger.ui.info("用户从Paywall点击使用条款")
                    showingTermsOfUse = true
                }
                .font(.caption)
                .foregroundColor(.seniorPrimary)
                
                Button("paywall.restore_purchase".localized) { 
                    handleRestorePurchases()
                }
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
    
    private func getPlansWithRealPrices() -> [SubscriptionPlan] {
        let basePlans = SubscriptionPlan.getPlans()
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
            
            // 创建新的计划实例，使用真实价格，但保持原有的id
            return SubscriptionPlan(
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
    
    // MARK: - Pro Features Data
    
    private let proFeatures = [
        ProFeature(icon: "🚀", title: "paywall.feature.unlimited_cleaning".localized, description: "paywall.feature.ai_detection".localized),
        ProFeature(icon: "📱", title: "paywall.feature.free_space".localized, description: "paywall.feature.save_80".localized),
        ProFeature(icon: "🔒", title: "paywall.feature.safe_delete".localized, description: "paywall.feature.recycle_bin".localized),
        ProFeature(icon: "⚡", title: "paywall.feature.batch".localized, description: "paywall.feature.one_click_clean".localized),
        ProFeature(icon: "🆓", title: "paywall.feature.no_ads".localized, description: "paywall.feature.clean_experience".localized), // 新增
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(feature.description)
                    .font(.seniorCaption)
                    .foregroundColor(.seniorSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(minWidth: 200, maxWidth: .infinity, alignment: .leading)
            
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

#Preview {
    PaywallView(isFromOnboarding: false)
} 
