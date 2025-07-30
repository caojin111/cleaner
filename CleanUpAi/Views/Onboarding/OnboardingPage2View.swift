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
                .foregroundColor(Color.seniorPrimary)
            // 文案
            VStack(spacing: 18) {
                Text(Constants.Onboarding.page2Title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Text("onboarding.page2.subtitle".localized)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(.seniorText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            // 权限卡片
            VStack(spacing: 16) {
                PermissionRow(
                    icon: "📸",
                    title: "onboarding.page2.photo_permission".localized,
                    description: "onboarding.page2.analyze_similar_photos".localized,
                    status: permissionManager.getPermissionStatusText(for: "photos")
                )
                PermissionRow(
                    icon: "🔔",
                    title: "onboarding.page2.notification_permission".localized,
                    description: "onboarding.page2.cleaning_suggestion".localized,
                    status: permissionManager.getPermissionStatusText(for: "notifications")
                )
            }
            .padding(.horizontal, 24)
            Spacer()
            // 按钮组
            VStack(spacing: 16) {
                Button(action: { requestPermissions() }) {
                        Text(isRequestingPermissions ? "onboarding.page2.requesting".localized : Constants.Onboarding.page2Button)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                            Color.seniorPrimary
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
                            Text("onboarding.page2.continue".localized)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                                Color.seniorPrimary
                        )
                            .cornerRadius(28)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 36)
        }
        .background(Color.white.ignoresSafeArea())
        .alert("onboarding.page2.title".localized, isPresented: $showPermissionAlert) {
            Button("onboarding.page2.gotosetting".localized) {
                permissionManager.openAppSettings()
            }
            Button("onboarding.page2.cancel".localized, role: .cancel) { }
        } message: {
            Text("onboarding.page2.permission_required".localized)
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