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
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 动画图标
            ZStack {
                // 背景圆圈
                Circle()
                    .fill(Color.seniorPrimary.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                // 清理图标
                VStack(spacing: 10) {
                    Image(systemName: "arrow.up.trash")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.seniorPrimary)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: animateIcon
                        )
                    
                    // 清理进度动画
                    ProgressView(value: animateIcon ? 0.8 : 0.2)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 100)
                        .animation(
                            Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                            value: animateIcon
                        )
                }
            }
            
            // 文字内容
            VStack(spacing: 20) {
                Text(Constants.Onboarding.page1Title)
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                    .multilineTextAlignment(.center)
                
                Text(Constants.Onboarding.page1Subtitle)
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // 继续按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
                Logger.logPageNavigation(from: "Onboarding-1", to: "Onboarding-2")
            }) {
                HStack {
                    Text("继续")
                        .font(.seniorBody)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.body)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: Constants.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .fill(Color.seniorPrimary)
                )
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .onAppear {
            animateIcon = true
        }
    }
}

#Preview {
    OnboardingPage1View(currentPage: .constant(0))
} 