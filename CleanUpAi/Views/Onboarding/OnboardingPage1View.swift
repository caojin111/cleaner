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
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部间距
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.top + 100)
                    
                    // 主标题
                    Text("onboarding.page1.title".localized)
                        .font(.system(size: 17, weight: .regular, design: .default))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 15)
                        .frame(maxWidth: 367)
                    
                    Spacer()
                    
                    // Continue按钮
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                        Logger.logPageNavigation(from: "Onboarding-1", to: "Onboarding-2")
                    }) {
                        Text("onboarding.page1.continue".localized)
                            .font(.system(size: 25, weight: .regular, design: .default))
                            .foregroundColor(.white)
                            .frame(width: 267, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 50)
                                    .fill(Color(red: 0.043, green: 0.663, blue: 0.831)) // #0BA9D4
                            )
                    }
                    .padding(.bottom, 61)
                }
                
                // 限时优惠图片 - 固定在特定位置
                VStack {
                    Spacer()
                        .frame(height: 180)
                    
                    ZStack {
                        // 背景图片
                        Image("ob1_limited_offer")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            
                        
                        // "1 Min"文字覆盖在图片上
                        Text("1 Min")
                            .font(.system(size: 40, weight: .regular, design: .default))
                            .foregroundColor(.black)
                            .frame(width: 0.0)
                            .offset(y: -16) // 调整位置到图片中央
                    }
                    .frame(width: /*@START_MENU_TOKEN@*/350.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            animateIcon = true
        }
    }
}

#Preview {
    OnboardingPage1View(currentPage: .constant(0))
} 
