//
//  AudioView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI

struct AudioView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "music.note")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.seniorSecondary)
                
                VStack(spacing: 16) {
                    Text("音频清理")
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
            .navigationTitle("音频清理")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    AudioView()
} 