//
//  FilesView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI

struct FilesView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "doc")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.seniorSecondary)
                
                VStack(spacing: 16) {
                    Text("files.title".localized)
                        .font(.seniorTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.seniorText)
                    
                    Text("files.coming_soon".localized)
                        .font(.seniorBody)
                        .foregroundColor(.seniorSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .navigationTitle("files.title".localized)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    FilesView()
} 