//
//  MoreView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import OSLog
import WebKit
import UserNotifications

struct MoreView: View {
    @State private var showingPaywall = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfUse = false
    @State private var showingRestoreAlert = false
    @State private var restoreResultMessage = ""
    @State private var currentPlanType: String = "Yearly Plan"
    @State private var showingNotificationAlert = false
    @State private var notificationAlertMessage = ""
    @State private var isInitialized = false // 防止初始化时的onChange触发
    @State private var hasShownNotificationResult = false // 防止重复显示通知结果弹窗
    @StateObject private var storeManager = StoreKitManager.shared
    @StateObject private var userSettings = UserSettingsManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.seniorBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 应用信息区域
                        appInfoSection
                        
                        proCardSection
                        // 功能列表
                        functionsSection
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 0)
                }
            }
            .navigationTitle("more.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView(isFromOnboarding: false)
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTermsOfUse) {
            TermsOfUseView()
        }
        .alert("more.restore_result".localized, isPresented: $showingRestoreAlert) {
            Button("more.ok".localized) { }
        } message: {
            Text(restoreResultMessage)
        }
        .alert("more.notification_result".localized, isPresented: $showingNotificationAlert) {
            Button("more.ok".localized) { }
        } message: {
            Text(notificationAlertMessage)
        }
        .onAppear {
            Logger.ui.debug("MoreView: 初始化更多视图")
            if userSettings.isSubscribed {
                loadCurrentPlanType()
            }
            // 只在第一次进入时检查通知状态
            if !isInitialized {
                checkNotificationStatus()
            }
        }
        .onDisappear {
            // 离开页面时重置通知结果状态，为下次进入做准备
            hasShownNotificationResult = false
            showingNotificationAlert = false // 重置弹窗状态
            Logger.ui.debug("MoreView: 离开页面，重置通知结果状态")
        }
        .onChange(of: showingPrivacyPolicy) { newValue in
            if newValue {
                Logger.ui.debug("MoreView: 显示隐私政策界面")
            }
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        EmptyView()
    }
    
    // MARK: - PRO卡片 Section
    
    private var proCardSection: some View {
        HStack(alignment: .center, spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "crown.fill")
                    .foregroundColor(Color.green)
                    .font(.system(size: 26, weight: .bold))
                }
            VStack(alignment: .leading, spacing: 4) {
                Text("more.pro_card.title".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("more.pro_card.subtitle".localized)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            if userSettings.isSubscribed {
                // 已订阅状态：显示当前plan类型
                Text(getCurrentPlanType())
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.green)
                    )
            } else {
                // 未订阅状态：显示Get Now按钮
                Button(action: { showingPaywall = true }) {
                    Text("more.pro_card.button".localized)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 24/255, green: 32/255, blue: 29/255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.18), lineWidth: 1)
        )
    }
    
    // MARK: - Functions Section
    
    private var functionsSection: some View {
        VStack(spacing: 12) {
            MoreMenuItem(
                icon: "arrow.counterclockwise",
                title: "more.menu.restore".localized,
                subtitle: nil,
                color: .orange,
                action: {
                    handleRestore()
                }
            )
            
            MoreMenuItem(
                icon: "star.fill",
                title: "more.menu.rate_us".localized,
                subtitle: nil,
                color: .yellow,
                action: {
                    handleRateUs()
                }
            )
            
            MoreMenuItem(
                icon: "envelope.fill",
                title: "more.menu.contact_us".localized,
                subtitle: nil,
                color: .cyan,
                action: {
                    handleContactUs()
                }
            )
            
            // 每日清理提醒 - 开关样式
            MoreMenuItemWithToggle(
                icon: "bell.fill",
                title: getDailyReminderTitle(),
                subtitle: getDailyReminderSubtitle(),
                color: .orange,
                isOn: $userSettings.isNotificationEnabled,
                onToggle: handleDailyReminderToggle
            )
            
            MoreMenuItem(
                icon: "shield.fill",
                title: "more.menu.privacy_policy".localized,
                subtitle: nil,
                color: .green,
                action: {
                    showingPrivacyPolicy = true
                    Logger.ui.debug("用户查看隐私政策")
                }
            )
            
            MoreMenuItem(
                icon: "doc.text.fill",
                title: "more.menu.terms_of_use".localized,
                subtitle: nil,
                color: .indigo,
                action: {
                    showingTermsOfUse = true
                    Logger.ui.debug("用户查看使用条款")
                }
            )
            
            MoreMenuItem(
                icon: "person.fill",
                title: "more.menu.developer".localized,
                subtitle: "app.developer".localized,
                color: .purple,
                action: {
                    Logger.ui.debug("用户查看开发者信息")
                }
            )
            
            MoreMenuItem(
                icon: "info.circle.fill",
                title: "more.menu.version".localized,
                subtitle: "app.version".localized,
                color: .blue,
                action: {
                    Logger.ui.debug("用户查看版本信息")
                }
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleRestore() {
        Logger.ui.info("用户执行恢复购买操作")
        
        Task {
            do {
                let hasValidSubscription = try await storeManager.restorePurchases()
                
                await MainActor.run {
                    if hasValidSubscription {
                        userSettings.isSubscribed = true
                        restoreResultMessage = "more.restore_success".localized
                        Logger.ui.info("恢复购买成功，找到有效订阅")
                    } else {
                        restoreResultMessage = "more.restore_no_subscription".localized
                        Logger.ui.info("恢复购买完成，但未找到有效订阅")
                    }
                    showingRestoreAlert = true
                }
            } catch {
                await MainActor.run {
                    restoreResultMessage = "more.restore_failed".localized(error.localizedDescription)
                    showingRestoreAlert = true
                    Logger.ui.error("恢复购买失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleContactUs() {
        Logger.ui.info("用户点击Contact us")
        if let url = URL(string: "mailto:dxycj250@gmail.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func handleRateUs() {
        Logger.ui.info("用户点击评分")
        if let url = URL(string: "https://apps.apple.com/app/id6748984268?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Notification Methods
    
    private func checkNotificationStatus() {
        Task {
            let permissionStatus = await notificationManager.checkNotificationPermission()
            let isScheduled = await notificationManager.isDailyReminderScheduled()
            
            await MainActor.run {
                let newStatus = permissionStatus == .authorized && isScheduled
                Logger.ui.info("通知状态初始化: 权限=\(permissionStatus.rawValue), 已设置=\(isScheduled), 状态=\(newStatus)")
                
                // 只在第一次启动时检查系统状态，然后保存到UserSettingsManager
                if !isInitialized {
                    userSettings.isNotificationEnabled = newStatus
                    isInitialized = true
                    Logger.ui.debug("MoreView通知状态初始化完成: \(newStatus)")
                }
            }
        }
    }
    
    private func handleDailyReminderToggle() {
        // 只有在初始化完成后才处理切换事件
        guard isInitialized else {
            Logger.ui.debug("MoreView尚未初始化完成，忽略切换事件")
            return
        }
        
        // 获取切换前的状态，因为userSettings.isNotificationEnabled已经被Toggle改变了
        let wasEnabled = !userSettings.isNotificationEnabled
        Logger.ui.info("用户主动切换每日提醒设置，从 \(wasEnabled) 切换到 \(userSettings.isNotificationEnabled)")
        
        Task {
            if userSettings.isNotificationEnabled {
                // 用户想要开启提醒
                Logger.ui.debug("尝试开启每日提醒")
                let granted = await notificationManager.requestNotificationPermission()
                
                await MainActor.run {
                    if granted {
                        Task {
                            await notificationManager.scheduleDailyCleanupReminder()
                            await MainActor.run {
                                userSettings.isNotificationEnabled = true
                                notificationAlertMessage = "more.notification_enabled".localized
                                showingNotificationAlert = true
                                hasShownNotificationResult = true
                                Logger.ui.info("每日提醒已开启")
                            }
                        }
                    } else {
                        // 权限被拒绝，恢复开关状态
                        userSettings.isNotificationEnabled = false
                        notificationAlertMessage = "more.notification_permission_denied".localized
                        showingNotificationAlert = true
                        hasShownNotificationResult = true
                        Logger.ui.warning("通知权限被拒绝")
                    }
                }
            } else {
                // 用户想要关闭提醒
                Logger.ui.debug("尝试关闭每日提醒")
                await notificationManager.removeDailyCleanupReminder()
                await MainActor.run {
                    userSettings.isNotificationEnabled = false
                    notificationAlertMessage = "more.notification_disabled".localized
                    showingNotificationAlert = true
                    hasShownNotificationResult = true
                    Logger.ui.info("每日提醒已关闭")
                }
            }
        }
    }
    
    // MARK: - Subscription Plan Helper
    
    private func getCurrentPlanType() -> String {
        return currentPlanType
    }
    
    // MARK: - Daily Reminder Helper
    
    private func getDailyReminderSubtitle() -> String {
        let enabledText = "more.menu.daily_reminder.enabled".localized
        let disabledText = "more.menu.daily_reminder.disabled".localized
        
        Logger.ui.debug("Daily reminder subtitle - enabled: '\(enabledText)', disabled: '\(disabledText)'")
        
        return userSettings.isNotificationEnabled ? enabledText : disabledText
    }
    
    private func getDailyReminderTitle() -> String {
        let title = "more.menu.daily_reminder.title".localized
        Logger.ui.debug("Daily reminder title: '\(title)'")
        return title
    }
    
    private func loadCurrentPlanType() {
        Task {
            if let planType = await storeManager.getCurrentSubscriptionPlan() {
                await MainActor.run {
                    switch planType {
                    case "yearly":
                        currentPlanType = "more.pro_card.yearly_plan".localized
                    case "monthly":
                        currentPlanType = "more.pro_card.monthly_plan".localized
                                    case "weekly":
                    currentPlanType = "more.pro_card.weekly_plan".localized
                default:
                    currentPlanType = "more.pro_card.yearly_plan".localized
                    }
                }
            }
        }
    }
}

// MARK: - More Menu Item

struct MoreMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color)
                    )
                
                // 文本信息 - 增加最小宽度确保文本完整显示
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 20)) // 缩小10号，从seniorBody(25)改为15
                        .fontWeight(.semibold)
                        .foregroundColor(.seniorText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.seniorCaption)
                            .foregroundColor(.seniorSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(minWidth: 140, maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.seniorSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - More Menu Item with Toggle

struct MoreMenuItemWithToggle: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    @Binding var isOn: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color)
                )
            
            // 文本信息 - 增加最小宽度确保文本完整显示
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20)) // 缩小10号，从seniorBody(25)改为15
                    .fontWeight(.semibold)
                    .foregroundColor(.seniorText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.seniorCaption)
                        .foregroundColor(.seniorSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(minWidth: 140, maxWidth: .infinity, alignment: .leading)
            
            // 开关 - 固定宽度
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
                .frame(width: 51) // 标准开关宽度
                .onChange(of: isOn) { _ in
                    onToggle()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Support Views

struct SupportUsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)
                
                VStack(spacing: 16) {
                                    Text("more.support.title".localized)
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("more.support.subtitle".localized)
                        .font(.seniorBody)
                        .foregroundColor(.seniorSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding(30)
            .navigationTitle("Support Us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("more.contact.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Privacy Policy View with WebView

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var htmlContent: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("more.privacy.loading".localized)
                            .font(.seniorBody)
                            .foregroundColor(.seniorSecondary)
                    }
                } else if let error = loadError {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("more.privacy.load_failed".localized)
                            .font(.seniorTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.seniorText)
                        
                        Text(error)
                            .font(.seniorBody)
                            .foregroundColor(.seniorSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button("重试") {
                            loadPrivacyPolicy()
                        }
                        .font(.seniorBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.seniorPrimary)
                        )
                    }
                    .padding(30)
                } else {
                    FileWebView(
                        htmlContent: htmlContent,
                        isLoading: $isLoading,
                        loadError: $loadError
                    )
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("more.contact.done".localized) {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
            .onAppear {
                Logger.ui.debug("PrivacyPolicyView: 初始化隐私政策视图")
                loadPrivacyPolicy()
            }
        }
    }
    
    private func loadPrivacyPolicy() {
        isLoading = true
        loadError = nil
        
        // 方案1：尝试从Bundle加载（推荐）
        if let bundleURL = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "html") {
            do {
                let content = try String(contentsOf: bundleURL, encoding: .utf8)
                Logger.ui.debug("从Bundle成功读取HTML文件，长度: \(content.count)")
                htmlContent = content
                isLoading = false
                return
            } catch {
                Logger.ui.error("从Bundle读取HTML文件失败: \(error.localizedDescription)")
            }
        }
        
        // 方案2：尝试从文件系统加载
        let filePath = "/Users/apple/Desktop/CleanUpAi/CleanUpAi/Privacy Policy.html"
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            Logger.ui.debug("从文件系统成功读取HTML文件，长度: \(content.count)")
            htmlContent = content
            isLoading = false
            return
        } catch {
            Logger.ui.error("从文件系统读取HTML文件失败: \(error.localizedDescription)")
        }
        
        // 方案3：使用内联HTML作为备用
        Logger.ui.debug("使用内联HTML作为备用方案")
        htmlContent = getFallbackHTML()
        isLoading = false
    }
    
    private func getFallbackHTML() -> String {
        return """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Privacy Policy - CleanUp AI</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    margin: 0;
                    padding: 20px;
                    background-color: #f5f5f5;
                    color: #333;
                    line-height: 1.6;
                }
                .container {
                    max-width: 600px;
                    margin: 0 auto;
                    background: white;
                    padding: 30px;
                    border-radius: 12px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }
                h1 {
                    color: #007AFF;
                    text-align: center;
                    margin-bottom: 30px;
                    font-size: 28px;
                }
                h2 {
                    color: #333;
                    margin-top: 30px;
                    margin-bottom: 15px;
                    font-size: 20px;
                }
                p {
                    margin-bottom: 15px;
                }
                ul {
                    margin-bottom: 15px;
                    padding-left: 20px;
                }
                li {
                    margin-bottom: 8px;
                }
                .highlight {
                    background-color: #e3f2fd;
                    padding: 15px;
                    border-radius: 8px;
                    border-left: 4px solid #2196F3;
                    margin: 20px 0;
                }
                .contact-info {
                    background-color: #f8f9fa;
                    padding: 20px;
                    border-radius: 8px;
                    margin: 20px 0;
                }
                .warning {
                    background-color: #fff3cd;
                    color: #856404;
                    padding: 15px;
                    border-radius: 8px;
                    border: 1px solid #ffeaa7;
                    margin: 20px 0;
                }
                .footer {
                    text-align: center;
                    margin-top: 40px;
                    padding-top: 20px;
                    border-top: 1px solid #eee;
                    color: #666;
                    font-size: 14px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Privacy Policy</h1>
                <p><em>This privacy policy applies to the CleanUp AI app...</em></p>
                
                <h2>Information Collection and Use</h2>
                <ul>
                    <li>We do not collect any personal information</li>
                    <li>All processing is done locally on your device</li>
                    <li>No data is transmitted to external servers</li>
                </ul>
                
                <div class="highlight">
                    <strong>Important:</strong> Your privacy is our top priority. All photo and video analysis is performed locally on your device.
                </div>
                
                <h2>Third Party Access</h2>
                <ul>
                    <li><em>Google Play Services</em></li>
                    <li><em>Google Analytics for Firebase</em></li>
                    <li><em>Firebase Crashlytics</em></li>
                </ul>
                
                <div class="contact-info">
                    <h3>Contact Us</h3>
                    <p><em>If you have any questions about this Privacy Policy, please contact us at <span class="email">dxycj250@gmail.com</span>.</em></p>
                </div>
                
                <div class="warning">
                    <strong>Effective Date:</strong> This privacy policy is effective as of 2025-07-22
                </div>
                
                <div class="footer">
                    <p>© 2024 CleanUp AI. All rights reserved.</p>
                    <p>This Privacy Policy applies to all versions of the CleanUp AI application.</p>
                </div>
            </div>
        </body>
        </html>
        """
    }
}

// MARK: - File WebView

struct FileWebView: UIViewRepresentable {
    let htmlContent: String
    @Binding var isLoading: Bool
    @Binding var loadError: String?
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.bounces = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if htmlContent.isEmpty {
            Logger.ui.error("HTML内容为空")
            loadError = "HTML内容为空"
            isLoading = false
            return
        }
        
        Logger.ui.debug("加载HTML内容，长度: \(htmlContent.count)")
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: FileWebView
        
        init(_ parent: FileWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Logger.ui.debug("WebView开始加载")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Logger.ui.debug("WebView加载完成")
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Logger.ui.error("WebView加载失败: \(error.localizedDescription)")
            parent.isLoading = false
            parent.loadError = "WebView加载失败: \(error.localizedDescription)"
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Logger.ui.error("WebView初始加载失败: \(error.localizedDescription)")
            parent.isLoading = false
            parent.loadError = "WebView初始加载失败: \(error.localizedDescription)"
        }
    }
}





struct ContactUsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.cyan)
                
                VStack(spacing: 16) {
                    Text("more.contact.title".localized)
                        .font(.seniorTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.seniorText)
                    
                    Text("more.contact.subtitle".localized)
                        .font(.seniorBody)
                        .foregroundColor(.seniorSecondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    Button("more.contact.send_email".localized) {
                        if let url = URL(string: "mailto:support@cleanupai.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.seniorBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.seniorPrimary)
                    )
                }
                
                Spacer()
            }
            .padding(30)
            .navigationTitle("Contact Us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("more.contact.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MoreView()
} 