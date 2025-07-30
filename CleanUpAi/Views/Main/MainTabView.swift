//
//  MainTabView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Foundation
import OSLog

struct MainTabView: View {
    @StateObject private var photoAnalyzer = PhotoAnalyzer.shared
    @StateObject private var recycleBinManager = RecycleBinManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.seniorBackground.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // 照片清理
                PhotosView(selectedTab: $selectedTab)
                    .tabItem {
                        VStack {
                            Image(systemName: selectedTab == 0 ? "photo.fill" : "photo")
                                .font(.title3)
                            Text("navigation.photos".localized)
                                .font(.seniorCaption)
                        }
                    }
                    .tag(0)
                
                // 视频清理
                VideosView()
                    .tabItem {
                        VStack {
                            Image(systemName: selectedTab == 1 ? "video.fill" : "video")
                                .font(.title3)
                            Text("navigation.videos".localized)
                                .font(.seniorCaption)
                        }
                    }
                    .tag(1)
                
                // 回收站
                RecycleBinView()
                    .tabItem {
                        VStack {
                            ZStack {
                                Image(systemName: selectedTab == 2 ? "trash.fill" : "trash")
                                    .font(.title3)
                                
                                // 回收站徽章
                                if recycleBinManager.itemCount > 0 {
                                    Text("\(recycleBinManager.itemCount)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(minWidth: 16, minHeight: 16)
                                        .background(
                                            Circle()
                                                .fill(Color.red)
                                        )
                                        .offset(x: 8, y: -8)
                                }
                            }
                            Text("navigation.recycle_bin".localized)
                                .font(.seniorCaption)
                        }
                    }
                    .tag(2)
                
                // 更多
                MoreView()
                    .tabItem {
                        VStack {
                            Image(systemName: selectedTab == 3 ? "ellipsis.circle.fill" : "ellipsis.circle")
                                .font(.title3)
                            Text("navigation.more".localized)
                                .font(.seniorCaption)
                        }
                    }
                    .tag(3)
            }
            .accentColor(.seniorPrimary)
            .onAppear {
                setupTabBarAppearance()
                Logger.logPageNavigation(from: "Paywall", to: "MainApp")
                Logger.ui.debug("主界面已加载，当前Tab结构：照片、视频、回收站、更多")
            }
        }
    }
    
    private func setupTabBarAppearance() {
        // 配置TabBar外观，适合老年人使用
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        
        // 选中状态
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.seniorPrimary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.seniorPrimary),
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ]
        
        // 未选中状态
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.seniorSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.seniorSecondary),
            .font: UIFont.systemFont(ofSize: 14, weight: .regular)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
} 