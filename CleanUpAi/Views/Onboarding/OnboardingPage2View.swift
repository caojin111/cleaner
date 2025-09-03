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
    
    // 动画状态
    @State private var animateLogo = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animatePhotoCard = false
    @State private var animateNotificationCard = false
    @State private var animateButton = false
    @State private var isContinueButtonDisabled = false // 防止连点保护
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.white.ignoresSafeArea()

                // 顶部Logo - 自适应居中定位
                Image("ob2_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: min(geometry.size.width * 0.4, 158), height: 99) // 自适应宽度
                    .position(x: geometry.size.width / 2, y: 74 + 99/2) // 居中显示
                    .opacity(animateLogo ? 1 : 0)
                    .offset(y: animateLogo ? 0 : -20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateLogo)
            
            // 主标题 - 自适应居中定位
            Text("onboarding.page2.title".localized)
                .font(.custom("Gloock-Regular", size: 30)) // 使用Gloock字体
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .frame(width: min(geometry.size.width * 0.8, 324), height: 44) // 自适应宽度
                .position(x: geometry.size.width / 2, y: 207 + 44/2) // 居中显示
                .opacity(animateTitle ? 1 : 0)
                .offset(y: animateTitle ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: animateTitle)
            
            // 副标题 - 自适应居中定位
            Text("onboarding.page2.subtitle".localized)
                .font(.system(size: 15, weight: .regular, design: .default))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .frame(width: min(geometry.size.width * 0.7, 266), height: 44) // 自适应宽度
                .position(x: geometry.size.width / 2, y: 259 + 44/2) // 居中显示
                .opacity(animateSubtitle ? 1 : 0)
                .offset(y: animateSubtitle ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: animateSubtitle)
            
            // 照片库权限卡片 - 自适应居中布局
            let leftMargin = geometry.size.width * 0.1 // 左侧边距为屏幕宽度的10%
            let rightMargin = geometry.size.width * 0.9 // 右侧位置为屏幕宽度的90%

            ZStack {
                Group {
                // 图标背景 - 自适应定位
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.043, green: 0.663, blue: 0.831, opacity: 0.25))
                    .frame(width: 50, height: 50)
                    .position(x: leftMargin + 25, y: 361 + 50/2) // 左侧定位

                // 照片图标 - 与底块位置重叠
                Image("ob2_polaroid_frame")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50/1.2, height: 50/1.5) // 缩小1.2倍
                    .position(x: leftMargin + 25, y: 361 + 50/2) // 与底块位置完全重叠
                }
                .opacity(animatePhotoCard ? 1 : 0)
                .offset(x: animatePhotoCard ? 0 : -50)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animatePhotoCard)
            }

            // 照片库权限文本 - 自适应布局
            HStack(spacing: 0) {
                // 标题 - 自适应定位
                Text("onboarding.page2.photo_permission".localized)
                    .font(.system(size: 20, weight: .bold, design: .default)) // Figma: 20px, bold
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .frame(width: geometry.size.width * 0.4, height: 22) // 自适应宽度
                    .position(x: leftMargin + geometry.size.width * 0.25 + 15, y: 364 + 22/2) // 右移15像素

                Spacer()

                // 状态 - 自适应定位
                ZStack {
                    // 状态背景
                    Image("ob2_status_bg")
                        .resizable()
                        .frame(width: 80, height: 30)
                        .position(x: rightMargin - 40, y: 364 + 22/2) // 右侧定位

                    // 状态文本
                    Text(permissionManager.getPermissionStatusText(for: "photos"))
                        .font(.system(size: 15, weight: .regular, design: .default)) // Figma: 15px, regular
                        .foregroundColor(.black)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80, height: 22)
                        .position(x: rightMargin - 40, y: 364 + 22/2) // 右侧定位
                }
            }

            // 照片库权限描述 - 自适应定位
            Text("onboarding.page2.analyze_similar_photos".localized)
                .font(.system(size: 15, weight: .regular, design: .default)) // Figma: 15px, regular
                .foregroundColor(Color.black.opacity(0.63))
                .multilineTextAlignment(.leading)
                .frame(width: geometry.size.width * 0.6, height: 22) // 自适应宽度
                .position(x: leftMargin + geometry.size.width * 0.3 + 42, y: 389 + 22/2) // 右移30像素
            
            // 通知权限卡片 - 自适应布局
            ZStack {
                Group {
                // 图标背景 - 自适应定位
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.043, green: 0.663, blue: 0.831, opacity: 0.25))
                    .frame(width: 50, height: 50)
                    .position(x: leftMargin + 25, y: 462 + 50/2) // 左侧定位

                // 通知图标 - 与底块位置重叠
                Image("ob2_notification_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50/1.2, height: 50/1.5) // 缩小1.2倍
                    .position(x: leftMargin + 25, y: 462 + 50/2) // 与底块位置完全重叠
                }
                .opacity(animateNotificationCard ? 1 : 0)
                .offset(x: animateNotificationCard ? 0 : -50)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateNotificationCard)
            }

            // 通知权限文本 - 自适应布局
            HStack(spacing: 0) {
                // 标题 - 自适应定位
                Text("onboarding.page2.notification_permission".localized)
                    .font(.system(size: 20, weight: .bold, design: .default)) // Figma: 20px, bold
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .frame(width: geometry.size.width * 0.4, height: 22) // 自适应宽度
                    .position(x: leftMargin + geometry.size.width * 0.25 + 10, y: 464 + 22/2) // 右移12像素

                Spacer()

                // 状态 - 自适应定位
                ZStack {
                    // 状态背景
                    Image("ob2_status_bg")
                        .resizable()
                        .frame(width: 80, height: 30)
                        .position(x: rightMargin - 40, y: 463 + 22/2) // 右侧定位

                    // 状态文本
                    Text(permissionManager.getPermissionStatusText(for: "notifications"))
                        .font(.system(size: 15, weight: .regular, design: .default)) // Figma: 15px, regular
                        .foregroundColor(.black)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80, height: 22)
                        .position(x: rightMargin - 40, y: 463 + 22/2) // 右侧定位
                }
            }

            // 通知权限描述 - 自适应定位
            Text("onboarding.page2.cleaning_suggestion".localized)
                .font(.system(size: 15, weight: .regular, design: .default)) // Figma: 15px, regular
                .foregroundColor(Color.black.opacity(0.63))
                .frame(width: geometry.size.width * 0.6, height: 22) // 自适应宽度
                .position(x: leftMargin + geometry.size.width * 0.3 + 26, y: 491 + 22/2) // 右移25像素
            
            // Continue按钮 - 自适应宽度和底部定位
            let buttonWidth = min(geometry.size.width * 0.8, 350) // 最大宽度350px
            Button(action: {
                // 防止连点保护
                guard !isContinueButtonDisabled else { return }
                isContinueButtonDisabled = true

                if permissionManager.hasPhotoLibraryAccess {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                    Logger.logPageNavigation(from: "Onboarding-2", to: "Onboarding-3")

                    // 1秒后重新启用按钮
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isContinueButtonDisabled = false
                    }
                } else {
                    requestPermissions()
                    // 权限请求完成后重新启用按钮
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isContinueButtonDisabled = false
                    }
                }
            }) {
                RoundedRectangle(cornerRadius: 50)
                    .fill(Color(hex: "0BA9D4"))
                    .frame(width: buttonWidth, height: 52)
                    .overlay(
                        Text(permissionManager.hasPhotoLibraryAccess ? "onboarding.page2.continue".localized : "onboarding.page2.granted".localized)
                            .font(.system(size: 25, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(width: buttonWidth * 0.8, height: 22) // 文本宽度为按钮宽度的80%
                    )
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height - 100) // 居中并定位到底部
            .contentShape(RoundedRectangle(cornerRadius: 50))
            .opacity(animateButton ? 1 : 0)
            .offset(y: animateButton ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.5), value: animateButton)
        }
        .onAppear {
            // 页面出现时更新权限状态
            permissionManager.updateCurrentStatus()
            
            // 依次触发动画
            withAnimation {
                animateLogo = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    animateTitle = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    animateSubtitle = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    animatePhotoCard = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    animateNotificationCard = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    animateButton = true
                }
            }
        }
        .alert("onboarding.page2.title".localized, isPresented: $showPermissionAlert) {
            Button("onboarding.page2.gotosetting".localized) {
                permissionManager.openAppSettings()
            }
            Button("onboarding.page2.cancel".localized, role: .cancel) { }
        } message: {
            Text("onboarding.page2.permission_required".localized)
        }
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

#Preview {
    OnboardingPage2View(currentPage: .constant(1))
}
