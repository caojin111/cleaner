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
        VStack(spacing: 40) {
            Spacer()
            
            // 权限图标
            Image(systemName: "checkmark.shield")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.seniorPrimary)
            
            // 标题和说明
            VStack(spacing: 20) {
                Text(Constants.Onboarding.page2Title)
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                    .multilineTextAlignment(.center)
                
                Text("为了提供最佳的清理体验，我们需要您的授权")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            // 权限列表
            VStack(spacing: 16) {
                PermissionRow(
                    icon: "📸",
                    title: "照片库权限",
                    description: "分析和清理相似图片",
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
                    description: "您可以选择要清理的文件",
                    status: "手动选择"
                )
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // 按钮组
            VStack(spacing: 16) {
                // 授权按钮
                Button(action: {
                    requestPermissions()
                }) {
                    HStack {
                        if isRequestingPermissions {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isRequestingPermissions ? "请求中..." : Constants.Onboarding.page2Button)
                            .font(.seniorBody)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: Constants.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.cornerRadius)
                            .fill(Color.seniorPrimary)
                    )
                }
                .disabled(isRequestingPermissions)
                
                // 继续按钮（权限授权后显示）
                if permissionManager.hasPhotoLibraryAccess {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                        Logger.logPageNavigation(from: "Onboarding-2", to: "Onboarding-3")
                    }) {
                        HStack {
                            Text("继续")
                                .font(.seniorBody)
                                .fontWeight(.semibold)
                            
                            Image(systemName: "arrow.right")
                                .font(.body)
                        }
                        .foregroundColor(.seniorPrimary)
                        .frame(maxWidth: .infinity, minHeight: Constants.buttonHeight)
                        .background(
                            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                                .stroke(Color.seniorPrimary, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
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