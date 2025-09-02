//
//  OnboardingPage1View.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog

struct OnboardingPage1View: View {
    @Binding var currentPage: Int
    @State private var animateIcon = false
    @State private var animateTitle = false
    @State private var animateImage = false
    @State private var animateMinText = false
    @State private var animateButton = false
    @State private var isContinueButtonDisabled = false // 防止连点保护
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.white.ignoresSafeArea()
                
                // 主标题文字 - 精确位置：x: 15, y: 422, width: 367, height: 97
                HStack(spacing: 0) {
                    Text("Just ")
                        .font(.custom("Gloock-Regular", size: 30))
                        .foregroundColor(.black)
                    + Text("1 min")
                        .font(.custom("Gloock-Regular", size: 39)) // 30 + 9 = 39
                        .foregroundColor(Color(red: 0.0, green: 0.561, blue: 0.773)) // #008FC5
                    + Text(" a day,\nclean your photo library")
                        .font(.custom("Gloock-Regular", size: 30))
                        .foregroundColor(.black)
                }
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .frame(width: 367, height: 97)
                .position(x: 15 + 367/2, y: 350 + 97/2)
                .opacity(animateTitle ? 1 : 0)
                .offset(y: animateTitle ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: animateTitle)
                
                // 限时优惠图片 - 精确位置：x: 86, y: 180, width: 230, height: 191
                Image("ob1_limited_offer")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 230, height: 191)
                    .position(x: 86 + 230/2, y: 160 + 191/2) // 从180调整到160，向上移动20像素
                    .opacity(animateImage ? 1 : 0)
                    .scaleEffect(animateImage ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateImage)
                
                // "1 Min"文字 - 精确位置：x: 165, y: 239, width: 103.99, height: 56.96
                Text("1 Min")
                    .font(.system(size: 40, weight: .regular, design: .default))
                    .foregroundColor(.white)
                    .frame(width: 103.99, height: 56.96)
                    .position(x: 180 + 103.99/2, y: 219 + 56.96/2) // 向右移动7像素，从239调整到219，向上移动20像素
                    .opacity(animateMinText ? 1 : 0)
                    .scaleEffect(animateMinText ? 1 : 0.8)
                    .rotationEffect(.degrees(-9)) // 逆时针旋转10度
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateMinText)
                
                // Continue按钮 - 保持原有位置，统一字体样式
                Button(action: {
                    // 防止连点保护
                    guard !isContinueButtonDisabled else { return }
                    isContinueButtonDisabled = true

                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                    Logger.logPageNavigation(from: "Onboarding-1", to: "Onboarding-2")

                    // 1秒后重新启用按钮
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isContinueButtonDisabled = false
                    }
                }) {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color(hex: "0BA9D4"))
                        .frame(width: 267, height: 52)
                        .overlay(
                            Text("onboarding.page1.continue".localized)
                                .font(.system(size: 25, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: 150.0, height: 22)
                                .onAppear {
                                    // 调试信息
                                    let continueText = "onboarding.page1.continue".localized
                                    Logger.ui.debug("Onboarding Page1 - Continue文本: \(continueText)")
                                }
                        )
                }
                .position(x: 62 + 267/2, y: 670)
                .contentShape(RoundedRectangle(cornerRadius: 50))
                .opacity(animateButton ? 1 : 0)
                .offset(y: animateButton ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateButton)
            }
        }
        .onAppear {
            // 依次触发动画
            withAnimation {
                animateImage = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    animateMinText = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    animateTitle = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    animateButton = true
                }
            }
        }
    }
}

#Preview {
    OnboardingPage1View(currentPage: .constant(0))
} 
