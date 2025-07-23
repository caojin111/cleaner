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
                    .fill(Color(red: 0.66, green: 1, blue: 0.81).opacity(0.18))
                    .frame(width: 180, height: 180)
                    Image(systemName: "arrow.up.trash")
                        .font(.system(size: 60, weight: .light))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                }
            // 文案
            VStack(spacing: 18) {
                Text(Constants.Onboarding.page1Title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Text(Constants.Onboarding.page1Subtitle)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
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
                    Text("继续")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                        LinearGradient(gradient: Gradient(colors: [Color(red: 0.85, green: 1, blue: 0.72), Color(red: 0.66, green: 1, blue: 0.81)]), startPoint: .leading, endPoint: .trailing)
                )
                    .cornerRadius(28)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 36)
        }
        .background(Color(red: 0.95, green: 1, blue: 0.96).ignoresSafeArea())
        .onAppear {
            animateIcon = true
        }
    }
}

#Preview {
    OnboardingPage1View(currentPage: .constant(0))
} 