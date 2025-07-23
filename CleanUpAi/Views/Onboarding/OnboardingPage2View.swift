//
//  OnboardingPage2View.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog

struct OnboardingPage2View: View {
    @Binding var currentPage: Int
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var isRequestingPermissions = false
    @State private var showPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 36) {
            Spacer()
            // 图标
            Image(systemName: "checkmark.shield")
                .font(.system(size: 70, weight: .light))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
            // 文案
            VStack(spacing: 18) {
                Text(Constants.Onboarding.page2Title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Text("为了提供更好的清理体验，我们需要您的授权")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            // 权限卡片
            VStack(spacing: 16) {
                PermissionRow(
                    icon: "📸",
                    title: "照片库权限",
                    description: "分析和清理相似照片",
                    status: permissionManager.getPermissionStatusText(for: "photos")
                )
                PermissionRow(
                    icon: "🔔",
                    title: "通知权限",
                    description: "及时提醒清理建议",
                    status: permissionManager.getPermissionStatusText(for: "notifications")
                )
                PermissionRow(
                    icon: "📁",
                    title: "文件访问",
                    description: "可选择要清理的文件",
                    status: "手动选择"
                )
            }
            .padding(.horizontal, 24)
            Spacer()
            // 按钮组
            VStack(spacing: 16) {
                Button(action: { requestPermissions() }) {
                        Text(isRequestingPermissions ? "请求中..." : Constants.Onboarding.page2Button)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 0.85, green: 1, blue: 0.72), Color(red: 0.66, green: 1, blue: 0.81)]), startPoint: .leading, endPoint: .trailing)
                    )
                        .cornerRadius(28)
                }
                .disabled(isRequestingPermissions)
                if permissionManager.hasPhotoLibraryAccess {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                        Logger.logPageNavigation(from: "Onboarding-2", to: "Onboarding-3")
                    }) {
                            Text("继续")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                                LinearGradient(gradient: Gradient(colors: [Color(red: 0.85, green: 1, blue: 0.72), Color(red: 0.66, green: 1, blue: 0.81)]), startPoint: .leading, endPoint: .trailing)
                        )
                            .cornerRadius(28)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 36)
        }
        .background(Color(red: 0.95, green: 1, blue: 0.96).ignoresSafeArea())
        .alert("权限设置", isPresented: $showPermissionAlert) {
            Button("去设置") {
                permissionManager.openAppSettings()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("请在设置中开启照片库权限以继续使用应用")
        }
    }
    
    private func requestPermissions() {
        isRequestingPermissions = true
        
        Task {
            // 同时请求照片库和通知权限
            let photoPermissionGranted = await permissionManager.requestPhotoLibraryPermission()
            let notificationPermissionGranted = await permissionManager.requestNotificationPermission()
            
            await MainActor.run {
                isRequestingPermissions = false
                
                Logger.analytics.info("权限请求结果 - 照片库: \(photoPermissionGranted), 通知: \(notificationPermissionGranted)")
                
                if !photoPermissionGranted {
                    showPermissionAlert = true
                } else {
                    // 照片库权限是必须的，通知权限可选
                    Logger.logPageNavigation(from: "Onboarding-2", to: "Onboarding-3")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                }
            }
        }
    }
}

// MARK: - Permission Row Component

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let status: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Text(icon)
                .font(.largeTitle)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.seniorBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.seniorText)
                    
                    Spacer()
                    
                    Text(status)
                        .font(.seniorCaption)
                        .foregroundColor(.seniorSecondary)
                }
                
                Text(description)
                    .font(.seniorCaption)
                    .foregroundColor(.seniorSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    OnboardingPage2View(currentPage: .constant(1))
} 