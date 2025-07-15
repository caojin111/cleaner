//
//  RecycleBinView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import OSLog
import Photos // Added for PHImageManager

struct RecycleBinView: View {
    @StateObject private var recycleBinManager = RecycleBinManager.shared
    @State private var showingBatchDeleteAlert = false // 批量删除alert
    @State private var showingSingleDeleteAlert = false // 单个删除alert
    @State private var selectedItem: MediaItem?
    @State private var isDeleting = false // 添加删除状态
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.seniorBackground.ignoresSafeArea()
                
                if recycleBinManager.isEmpty {
                    emptyStateView
                } else {
                    itemListView
                }
                
                // 删除进度指示器
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text(selectedItem != nil ? "正在删除图片..." : "正在批量删除...")
                                .font(.seniorBody)
                                .foregroundColor(.white)
                        }
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.8))
                        )
                    }
                }
            }
            .navigationTitle("回收站")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !recycleBinManager.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("清空") {
                            showingBatchDeleteAlert = true
                            Logger.ui.debug("用户点击清空回收站按钮")
                        }
                        .foregroundColor(.seniorDanger)
                        .disabled(isDeleting) // 删除期间禁用按钮
                    }
                }
            }
            .alert("确认批量删除", isPresented: $showingBatchDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) {
                    performBatchDelete()
                }
            } message: {
                Text("将批量永久删除回收站中的 \(recycleBinManager.itemCount) 个文件，此操作不可恢复")
            }
            .alert("确认删除图片", isPresented: $showingSingleDeleteAlert) {
                Button("取消", role: .cancel) { 
                    selectedItem = nil
                }
                Button("删除", role: .destructive) {
                    if let item = selectedItem {
                        performSingleDelete(item: item)
                    }
                }
            } message: {
                if let item = selectedItem {
                    Text("将永久删除图片「\(item.fileName)」，此操作不可恢复")
                } else {
                    Text("将永久删除该图片，此操作不可恢复")
                }
            }
        }
        .disabled(isDeleting) // 删除期间禁用整个界面交互
    }
    
    // MARK: - Delete Functions
    
    private func performBatchDelete() {
        isDeleting = true
        selectedItem = nil // 清空选择项，表示批量删除
        Logger.ui.info("开始执行批量删除回收站操作")
        
        Task {
            await recycleBinManager.permanentlyDeleteAll()
            
            await MainActor.run {
                isDeleting = false
                Logger.ui.info("批量删除回收站操作完成")
            }
        }
    }
    
    private func performSingleDelete(item: MediaItem) {
        isDeleting = true
        Logger.ui.info("开始执行单个删除操作: \(item.fileName)")
        
        Task {
            await recycleBinManager.permanentlyDelete(item)
            
            await MainActor.run {
                isDeleting = false
                selectedItem = nil
                Logger.ui.info("单个删除操作完成: \(item.fileName)")
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "trash")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.seniorSecondary)
            
            VStack(spacing: 16) {
                Text("回收站为空")
                    .font(.seniorTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("删除的文件会暂时保存在这里\n您可以随时恢复或永久删除")
                    .font(.seniorBody)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Item List View
    
    private var itemListView: some View {
        VStack(spacing: 0) {
            // 统计信息
            statsHeader
            
            // 图片网格
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(recycleBinManager.items) { item in
                        RecycleBinItemRow(
                            item: item,
                            onRestore: {
                                recycleBinManager.restore(item)
                                Logger.ui.debug("用户恢复图片: \(item.fileName)")
                            },
                            onPermanentDelete: {
                                selectedItem = item
                                showingSingleDeleteAlert = true
                                Logger.ui.debug("用户选择删除图片: \(item.fileName)")
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        VStack(spacing: 12) {
            HStack {
                StatCard(
                    title: "文件数量",
                    value: "\(recycleBinManager.itemCount)",
                    icon: "doc.badge.gearshape",
                    color: .blue
                )
                
                StatCard(
                    title: "占用空间",
                    value: recycleBinManager.formattedTotalSize,
                    icon: "externaldrive.badge.xmark",
                    color: .red
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Recycle Bin Item Row

struct RecycleBinItemRow: View {
    let item: MediaItem
    let onRestore: () -> Void
    let onPermanentDelete: () -> Void
    @State private var photoImage: UIImage?
    
    var body: some View {
        VStack(spacing: 0) {
            // 图片预览区域
            ZStack {
                if let image = photoImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 160, height: 160)
                        .overlay(
                            VStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(0.8)
                                
                                Text("加载中")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        )
                }
                
                // 操作按钮覆盖层
                VStack {
                    HStack {
                        Spacer()
                        
                        // 删除时间标识
                        if let deletedDate = item.deletedDate {
                            Text(formatDeletedDate(deletedDate))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.black.opacity(0.6))
                                )
                        }
                    }
                    .padding(8)
                    
                    Spacer()
                    
                    // 底部操作按钮
                    HStack(spacing: 12) {
                        // 恢复按钮
                        Button(action: onRestore) {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title3)
                                
                                Text("恢复")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.seniorSuccess.opacity(0.9))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 永久删除按钮
                        Button(action: onPermanentDelete) {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.title3)
                                
                                Text("删除")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.seniorDanger.opacity(0.9))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 6, x: 0, y: 3)
        )
        .onAppear {
            loadPhotoImage()
        }
    }
    
    private func loadPhotoImage() {
        guard let asset = item.asset else { return }
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.resizeMode = .exact
        requestOptions.isNetworkAccessAllowed = true
        
        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 160, height: 160),
            contentMode: .aspectFill,
            options: requestOptions
        ) { image, info in
            DispatchQueue.main.async {
                if let image = image {
                    self.photoImage = image
                    Logger.ui.debug("成功加载回收站图片: \(self.item.fileName)")
                } else if let error = info?[PHImageErrorKey] as? Error {
                    Logger.logError(error, context: "加载回收站图片失败: \(self.item.fileName)")
                }
            }
        }
    }
    
    private func formatDeletedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

#Preview {
    RecycleBinView()
} 