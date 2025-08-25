//
//  ActionButton.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
            }
            .frame(width: 80, height: 80)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color,
                                color.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.3), radius: 12, x: 0, y: 6)
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .bottomTrailing,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: true)
    }
}

// MARK: - Modern Button Styles
struct ModernActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
            }
            .frame(width: 80, height: 80)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color,
                                color.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.3), radius: isPressed ? 6 : 12, x: 0, y: isPressed ? 3 : 6)
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .bottomTrailing,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Modern Color Palette
extension Color {
    // 删除按钮 - 使用更柔和的红色
    static let modernDelete = Color(red: 0.91, green: 0.30, blue: 0.24) // 更柔和的红色
    
    // 保留按钮 - 使用指定的蓝色 #0BADD9
    static let modernKeep = Color(red: 11.0/255.0, green: 173.0/255.0, blue: 217.0/255.0) // #0BADD9
    
    // 恢复按钮 - 使用指定的蓝色 #0BADD9
    static let modernRestore = Color(red: 11.0/255.0, green: 173.0/255.0, blue: 217.0/255.0) // #0BADD9
    
    // 替代配色方案
    static let alternativeDelete = Color(red: 0.85, green: 0.25, blue: 0.45) // 玫瑰红
    static let alternativeKeep = Color(red: 0.15, green: 0.68, blue: 0.38) // 薄荷绿
    
    // 中性配色方案
    static let neutralDelete = Color(red: 0.60, green: 0.60, blue: 0.60) // 灰色
    static let neutralKeep = Color(red: 0.40, green: 0.40, blue: 0.40) // 深灰色
}

#Preview {
    VStack(spacing: 40) {
        Text("高级按钮设计 - 现代配色")
            .font(.headline)
            .padding(.top)
        
        HStack(spacing: 30) {
            ActionButton(
                icon: "trash.fill",
                title: "删除",
                color: .modernDelete
            ) {
                print("删除")
            }
            
            ActionButton(
                icon: "heart.fill",
                title: "保留",
                color: .modernKeep
            ) {
                print("保留")
            }
        }
        
        Text("高级按钮设计 - 交互版本")
            .font(.headline)
        
        HStack(spacing: 30) {
            ModernActionButton(
                icon: "trash.fill",
                title: "删除",
                color: .modernDelete
            ) {
                print("删除")
            }
            
            ModernActionButton(
                icon: "heart.fill",
                title: "保留",
                color: .modernKeep
            ) {
                print("保留")
            }
        }
        
        Text("恢复按钮")
            .font(.headline)
        
        HStack(spacing: 30) {
            ActionButton(
                icon: "arrow.counterclockwise",
                title: "恢复",
                color: .modernRestore
            ) {
                print("恢复")
            }
            
            ActionButton(
                icon: "trash",
                title: "删除",
                color: .modernDelete
            ) {
                print("删除")
            }
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
