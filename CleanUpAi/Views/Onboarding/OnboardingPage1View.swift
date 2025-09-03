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
                
                // 主标题文字 - 自适应居中定位
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
                .frame(width: min(geometry.size.width * 0.9, 367), height: 97) // 自适应宽度，最多367px
                .position(x: geometry.size.width / 2, y: 350 + 97/2)
                .opacity(animateTitle ? 1 : 0)
                .offset(y: animateTitle ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: animateTitle)
                
                // 限时优惠图片 - 自适应居中定位
                Image("ob1_limited_offer")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: min(geometry.size.width * 0.6, 230), height: 191) // 自适应宽度，最多230px
                    .position(x: geometry.size.width / 2, y: 160 + 191/2) // 居中显示
                    .opacity(animateImage ? 1 : 0)
                    .scaleEffect(animateImage ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateImage)
                
                // "1 Min"文字 - 自适应居中定位
                Text("1 Min")
                    .font(.system(size: 40, weight: .regular, design: .default))
                    .foregroundColor(.white)
                    .frame(width: 103.99, height: 56.96)
                    .position(x: geometry.size.width / 2, y: 219 + 56.96/2) // 居中显示
                    .opacity(animateMinText ? 1 : 0)
                    .scaleEffect(animateMinText ? 1 : 0.8)
                    .rotationEffect(.degrees(-9)) // 逆时针旋转10度
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateMinText)
                
                // Continue按钮 - 自适应宽度和底部定位
                let buttonWidth = min(geometry.size.width * 0.8, 350) // 最大宽度350px
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
                        .frame(width: buttonWidth, height: 52)
                        .overlay(
                            Text("onboarding.page1.continue".localized)
                                .font(.system(size: 25, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: buttonWidth * 0.8, height: 22) // 文本宽度为按钮宽度的80%
                                .onAppear {
                                    // 调试信息
                                    let continueText = "onboarding.page1.continue".localized
                                    Logger.ui.debug("Onboarding Page1 - Continue文本: \(continueText)")
                                }
                        )
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height - 100) // 居中并定位到底部
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
