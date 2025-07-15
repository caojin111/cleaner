//
//  PaywallView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog

struct PaywallView: View {
    @State private var selectedPlan = SubscriptionPlan.plans[0]
    @State private var showMainApp = false
    @State private var animateFeatures = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettingsManager.shared
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.seniorBackground,
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // 头部区域
                    headerSection
                    
                    // 功能介绍
                    featuresSection
                    
                    // 订阅方案
                    subscriptionSection
                    
                    // 按钮区域
                    buttonSection
                    
                    // 底部条款
                    termsSection
                }
                .padding(.horizontal, 20)
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainTabView()
        }
        .onAppear {
            Logger.logPageNavigation(from: "Onboarding", to: "Paywall")
            startAnimations()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // 关闭按钮
            HStack {
                Spacer()
                Button(action: {
                    // 允许用户跳过，直接进入主应用，同时标记onboarding完成
                    userSettings.markOnboardingCompleted()
                    showMainApp = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.seniorSecondary)
                }
            }
            .padding(.top, 10)
            
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
            
            // 稍后决定按钮
            Button(action: {
                // 即使用户选择稍后决定，也要标记onboarding已完成
                userSettings.markOnboardingCompleted()
                showMainApp = true
                Logger.logPageNavigation(from: "Paywall", to: "MainApp")
            }) {
                Text("稍后决定")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .underline()
            }
        }
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
        showMainApp = true
        Logger.logPageNavigation(from: "Paywall", to: "MainApp")
    }
    
    // MARK: - Pro Features Data
    
    private let proFeatures = [
        ProFeature(icon: "🚀", title: "智能清理重复文件", description: "AI算法精准识别"),
        ProFeature(icon: "📱", title: "释放存储空间", description: "最多节省80%空间"),
        ProFeature(icon: "🔒", title: "安全删除保护", description: "回收站机制防误删"),
        ProFeature(icon: "⚡", title: "批量处理", description: "一键清理数千文件"),
        ProFeature(icon: "📊", title: "详细分析报告", description: "可视化存储分析")
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
                    
                    Text(plan.price)
                        .font(.seniorTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.seniorPrimary)
                    
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

#Preview {
    PaywallView()
} 