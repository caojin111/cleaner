//
//  VideosView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI

struct VideosView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "video")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.seniorSecondary)
                
                VStack(spacing: 16) {
                    Text("视频清理")
                        .font(.seniorTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.seniorText)
                    
                    Text("即将推出\n敬请期待...")
                        .font(.seniorBody)
                        .foregroundColor(.seniorSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .navigationTitle("视频清理")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    VideosView()
} 