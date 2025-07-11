//
//  PhotosView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import Photos
import Foundation
import UIKit

struct PhotosView: View {
    @StateObject private var photoAnalyzer = PhotoAnalyzer.shared
    @StateObject private var recycleBinManager = RecycleBinManager.shared
    @State private var currentItemIndex = 0
    @State private var showingAnalysis = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.seniorBackground.ignoresSafeArea()
                
                if photoAnalyzer.isAnalyzing {
                    analysisView
                } else if photoAnalyzer.foundDuplicates.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("照片清理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.seniorPrimary)
                    }
                }
            }
            .onAppear {
                startAnalysisIfNeeded()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    // MARK: - Analysis View
    
    private var analysisView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 分析动画
            VStack(spacing: 20) {
                ProgressView(value: photoAnalyzer.analysisProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
                    .accentColor(.seniorPrimary)
                
                Text("正在分析照片...")
                    .font(.seniorTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.seniorText)
                
                Text("已处理 \(Int(photoAnalyzer.analysisProgress * 100))%")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
            }
            
            Spacer()
        }
        .onAppear {
            showingAnalysis = true
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 空状态图标
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.seniorSecondary)
            
            VStack(spacing: 16) {
                Text("没有发现重复照片")
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("您的照片库看起来很整洁！\n继续保持良好的管理习惯。")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("重新分析") {
                Task {
                    await photoAnalyzer.startAnalysis()
                }
            }
            .font(.seniorBody)
            .fontWeight(.semibold)
            .foregroundColor(.seniorPrimary)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(Color.seniorPrimary, lineWidth: 2)
            )
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // 顶部统计
            statsHeader
            
            // 卡片区域
            cardStackView
            
            // 底部操作按钮
            actionButtons
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        VStack(spacing: 12) {
            HStack {
                StatCard(
                    title: "重复照片",
                    value: "\(photoAnalyzer.foundDuplicates.count)",
                    icon: "photo.stack",
                    color: .orange
                )
                
                StatCard(
                    title: "可节省",
                    value: ByteCountFormatter.string(fromByteCount: photoAnalyzer.estimatedSpaceSavings(), countStyle: .file),
                    icon: "externaldrive.badge.minus",
                    color: .green
                )
            }
            
            // 进度条
            ProgressView(value: Double(currentItemIndex), total: Double(photoAnalyzer.foundDuplicates.count))
                .progressViewStyle(LinearProgressViewStyle())
                .accentColor(.seniorPrimary)
                .padding(.horizontal, 20)
        }
        .padding(20)
        .background(Color.white)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Card Stack View
    
    private var cardStackView: some View {
        ZStack {
            if currentItemIndex < photoAnalyzer.foundDuplicates.count {
                // 背景卡片（下一张）
                if currentItemIndex + 1 < photoAnalyzer.foundDuplicates.count {
                    SwipeablePhotoCard(
                        item: photoAnalyzer.foundDuplicates[currentItemIndex + 1],
                        onSwipeLeft: { _ in },
                        onSwipeRight: { _ in }
                    )
                    .scaleEffect(0.95)
                    .opacity(0.6)
                    .offset(y: 10)
                }
                
                // 当前卡片
                SwipeablePhotoCard(
                    item: photoAnalyzer.foundDuplicates[currentItemIndex],
                    onSwipeLeft: { item in
                        handleDelete(item)
                    },
                    onSwipeRight: { item in
                        handleKeep(item)
                    }
                )
            } else {
                // 完成状态
                completionView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 30) {
            // 保留按钮
            ActionButton(
                icon: "heart.fill",
                title: "保留",
                color: .seniorSuccess,
                action: {
                    if currentItemIndex < photoAnalyzer.foundDuplicates.count {
                        handleKeep(photoAnalyzer.foundDuplicates[currentItemIndex])
                    }
                }
            )
            
            // 删除按钮
            ActionButton(
                icon: "trash.fill",
                title: "删除",
                color: .seniorDanger,
                action: {
                    if currentItemIndex < photoAnalyzer.foundDuplicates.count {
                        handleDelete(photoAnalyzer.foundDuplicates[currentItemIndex])
                    }
                }
            )
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(Color.white)
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 30) {
            // 完成图标
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.seniorSuccess)
            
            VStack(spacing: 16) {
                Text("清理完成！")
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("您已成功清理了所有重复照片\n手机空间得到了优化")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("查看回收站") {
                // TODO: 切换到回收站Tab
            }
            .font(.seniorBody)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .fill(Color.seniorPrimary)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func startAnalysisIfNeeded() {
        if photoAnalyzer.foundDuplicates.isEmpty && !photoAnalyzer.isAnalyzing {
            Task {
                await photoAnalyzer.startAnalysis()
            }
        }
    }
    
    private func handleDelete(_ item: MediaItem) {
        recycleBinManager.moveToRecycleBin(item)
        nextItem()
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func handleKeep(_ item: MediaItem) {
        photoAnalyzer.markItemForKeeping(item)
        nextItem()
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func nextItem() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentItemIndex += 1
        }
    }
}

// MARK: - Swipeable Photo Card

struct SwipeablePhotoCard: View {
    let item: MediaItem
    let onSwipeLeft: (MediaItem) -> Void
    let onSwipeRight: (MediaItem) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // 照片预览
            AsyncImage(url: nil) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 300, height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // 照片信息
            VStack(spacing: 8) {
                Text(item.fileName)
                    .font(.seniorBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.seniorText)
                
                HStack(spacing: 20) {
                    Label(item.formattedSize, systemImage: "externaldrive")
                    Label(item.formattedDate, systemImage: "calendar")
                }
                .font(.seniorCaption)
                .foregroundColor(.seniorSecondary)
                
                if item.isDuplicate {
                    Text("相似度: \(Int(item.similarityScore * 100))%")
                        .font(.seniorCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation
                    rotation = Double(value.translation.width / 10)
                }
                .onEnded { value in
                    handleSwipeEnd(value)
                }
        )
        .overlay(
            // 滑动指示器
            swipeIndicators
        )
    }
    
    private var swipeIndicators: some View {
        ZStack {
            // 左滑删除指示器
            if offset.width < -Constants.swipeHintThreshold {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.seniorDanger, lineWidth: 3)
                    .overlay(
                        VStack {
                            Image(systemName: "trash.fill")
                                .font(.largeTitle)
                                .foregroundColor(.seniorDanger)
                            Text("删除")
                                .font(.seniorBody)
                                .fontWeight(.bold)
                                .foregroundColor(.seniorDanger)
                        }
                    )
                    .opacity(min(abs(offset.width) / Constants.swipeThreshold, 1.0))
            }
            
            // 右滑保留指示器
            if offset.width > Constants.swipeHintThreshold {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.seniorSuccess, lineWidth: 3)
                    .overlay(
                        VStack {
                            Image(systemName: "heart.fill")
                                .font(.largeTitle)
                                .foregroundColor(.seniorSuccess)
                            Text("保留")
                                .font(.seniorBody)
                                .fontWeight(.bold)
                                .foregroundColor(.seniorSuccess)
                        }
                    )
                    .opacity(min(offset.width / Constants.swipeThreshold, 1.0))
            }
        }
    }
    
    private func handleSwipeEnd(_ value: DragGesture.Value) {
        if value.translation.width < -Constants.swipeThreshold {
            // 左滑删除
            withAnimation(.easeOut(duration: 0.5)) {
                offset = CGSize(width: -1000, height: 0)
                rotation = -30
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onSwipeLeft(item)
            }
        } else if value.translation.width > Constants.swipeThreshold {
            // 右滑保留
            withAnimation(.easeOut(duration: 0.5)) {
                offset = CGSize(width: 1000, height: 0)
                rotation = 30
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onSwipeRight(item)
            }
        } else {
            // 回弹
            withAnimation(.spring()) {
                offset = .zero
                rotation = 0
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.seniorTitle)
                .fontWeight(.bold)
                .foregroundColor(.seniorText)
            
            Text(title)
                .font(.seniorCaption)
                .foregroundColor(.seniorSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(color.opacity(0.1))
        )
    }
}

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
                
                Text(title)
                    .font(.seniorCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
            .background(
                Circle()
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Settings View (Placeholder)

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("设置页面")
                    .font(.seniorTitle)
                Text("敬请期待...")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PhotosView()
} 