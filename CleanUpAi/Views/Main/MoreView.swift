//
//  MoreView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import OSLog
import WebKit

struct MoreView: View {
    @State private var showingPaywall = false
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("更多")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(isFromOnboarding: false)
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .onAppear {
            Logger.ui.debug("MoreView: 初始化更多视图")
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
                Text("PRO 优惠")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("高级功能")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: { showingPaywall = true }) {
                Text("立即获取")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
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
                icon: "info.circle.fill",
                title: "Version",
                color: .blue,
                action: {
                    Logger.ui.debug("用户查看版本信息")
                }
            )
            
            MoreMenuItem(
                icon: "person.fill",
                title: "Developer",
                color: .purple,
                action: {
                    Logger.ui.debug("用户查看开发者信息")
                }
            )
            
            MoreMenuItem(
                icon: "shield.fill",
                title: "Privacy Policy",
                color: .green,
                action: {
                    showingPrivacyPolicy = true
                    Logger.ui.debug("用户查看隐私政策")
                }
            )
            
            MoreMenuItem(
                icon: "arrow.counterclockwise",
                title: "Restore",
                color: .orange,
                action: {
                    handleRestore()
                }
            )
            
            MoreMenuItem(
                icon: "envelope.fill",
                title: "Contact us",
                color: .cyan,
                action: {
                    handleContactUs()
                }
            )
            
            MoreMenuItem(
                icon: "star.fill",
                title: "Rate us",
                color: .yellow,
                action: {
                    handleRateUs()
                }
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleRestore() {
        Logger.ui.info("用户执行恢复购买操作")
        // TODO: 实现恢复购买逻辑
    }
    
    private func handleContactUs() {
        Logger.ui.info("用户点击Contact us")
        if let url = URL(string: "mailto:dxycj250@gmail.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func handleRateUs() {
        Logger.ui.info("用户点击评分")
        // TODO: 请将YOUR_APP_ID替换为实际App Store ID
        if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - More Menu Item

struct MoreMenuItem: View {
    let icon: String
    let title: String
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
                // 文本信息
                    Text(title)
                        .font(.seniorBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.seniorText)
                        .lineLimit(1)
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

// MARK: - Support Views

struct SupportUsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)
                
                VStack(spacing: 16) {
                    Text("感谢您的支持")
                        .font(.seniorTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.seniorText)
                    
                    Text("您的支持是我们继续改进的动力\n我们会持续为您提供更好的服务")
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
                    Button("完成") {
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
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("加载隐私政策...")
                            .font(.seniorBody)
                            .foregroundColor(.seniorSecondary)
                    }
                } else if let error = loadError {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("加载失败")
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
                    Button("完成") {
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
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.cyan)
                
                VStack(spacing: 16) {
                    Text("联系我们")
                        .font(.seniorTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.seniorText)
                    
                    Text("如有任何问题或建议\n请通过以下方式联系我们")
                        .font(.seniorBody)
                        .foregroundColor(.seniorSecondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    Button("发送邮件") {
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
                    Button("完成") {
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