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
                    Text("audio.title".localized)
                        .font(.seniorTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.seniorText)
                    
                    Text("audio.coming_soon".localized)
                        .font(.seniorBody)
                        .foregroundColor(.seniorSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .navigationTitle("audio.title".localized)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    AudioView()
} 