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
        VStack(spacing: 36) {
            Spacer()
            // LOGO/图标
            ZStack {
                Circle()
                    .fill(Color.seniorPrimary.opacity(0.18))
                    .frame(width: 180, height: 180)
                    Image(systemName: "arrow.up.trash")
                        .font(.system(size: 60, weight: .light))
                    .foregroundColor(Color.seniorPrimary)
                }
            // 文案
            VStack(spacing: 18) {
                Text("onboarding.page1.title".localized)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Text("onboarding.page1.subtitle".localized)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(.seniorText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
            // 按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
                Logger.logPageNavigation(from: "Onboarding-1", to: "Onboarding-2")
            }) {
                    Text("onboarding.page1.continue".localized)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                        Color.seniorPrimary
                )
                    .cornerRadius(28)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 36)
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            animateIcon = true
        }
    }
}

#Preview {
    OnboardingPage1View(currentPage: .constant(0))
} 