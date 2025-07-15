//
//  MoreView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import OSLog

struct MoreView: View {
    @State private var showingSupportUs = false
    @State private var showingPrivacyPolicy = false
    @State private var showingContactUs = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.seniorBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 应用信息区域
                        appInfoSection
                        
                        // 功能列表
                        functionsSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("更多")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingSupportUs) {
            SupportUsView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingContactUs) {
            ContactUsView()
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        VStack(spacing: 16) {
            // 应用图标
            Image("AppIcon") // 如果没有AppIcon，会显示为空
                .resizable()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                .onAppear {
                    Logger.ui.debug("显示应用图标")
                }
            
            VStack(spacing: 8) {
                Text("CleanUp AI")
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("智能照片清理助手")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Functions Section
    
    private var functionsSection: some View {
        VStack(spacing: 12) {
            MoreMenuItem(
                icon: "heart.fill",
                title: "Support us",
                subtitle: "支持我们继续改进",
                color: .pink,
                action: {
                    showingSupportUs = true
                    Logger.ui.debug("用户点击Support us")
                }
            )
            
            MoreMenuItem(
                icon: "info.circle.fill",
                title: "Version",
                subtitle: "当前版本 1.0.0",
                color: .blue,
                action: {
                    Logger.ui.debug("用户查看版本信息")
                }
            )
            
            MoreMenuItem(
                icon: "person.fill",
                title: "Developer",
                subtitle: "CleanU AI Team",
                color: .purple,
                action: {
                    Logger.ui.debug("用户查看开发者信息")
                }
            )
            
            MoreMenuItem(
                icon: "shield.fill",
                title: "Privacy Policy",
                subtitle: "隐私政策",
                color: .green,
                action: {
                    showingPrivacyPolicy = true
                    Logger.ui.debug("用户查看隐私政策")
                }
            )
            
            MoreMenuItem(
                icon: "arrow.counterclockwise",
                title: "Restore",
                subtitle: "恢复购买",
                color: .orange,
                action: {
                    handleRestore()
                }
            )
            
            MoreMenuItem(
                icon: "envelope.fill",
                title: "Contact us",
                subtitle: "联系我们",
                color: .cyan,
                action: {
                    showingContactUs = true
                    Logger.ui.debug("用户点击Contact us")
                }
            )
            
            MoreMenuItem(
                icon: "star.fill",
                title: "Rate us",
                subtitle: "给我们评分",
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
    
    private func handleRateUs() {
        Logger.ui.info("用户点击评分")
        if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - More Menu Item

struct MoreMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.seniorBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.seniorText)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.seniorCaption)
                        .foregroundColor(.seniorSecondary)
                        .lineLimit(1)
                }
                
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

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("隐私政策")
                        .font(.seniorTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.seniorText)
                    
                    Text("CleanUp AI 重视您的隐私。我们仅在您的设备本地处理您的照片，不会上传到任何服务器。")
                        .font(.seniorBody)
                        .foregroundColor(.seniorText)
                    
                    Text("• 所有照片分析都在本地进行\n• 我们不收集您的个人照片\n• 我们不会与第三方分享您的数据\n• 您的隐私受到完全保护")
                        .font(.seniorBody)
                        .foregroundColor(.seniorText)
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Privacy Policy")
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