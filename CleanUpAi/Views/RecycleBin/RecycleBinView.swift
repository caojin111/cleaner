//
//  RecycleBinView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI

struct RecycleBinView: View {
    @StateObject private var recycleBinManager = RecycleBinManager.shared
    @State private var showingDeleteAlert = false
    @State private var selectedItem: MediaItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.seniorBackground.ignoresSafeArea()
                
                if recycleBinManager.isEmpty {
                    emptyStateView
                } else {
                    itemListView
                }
            }
            .navigationTitle("回收站")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !recycleBinManager.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("清空") {
                            showingDeleteAlert = true
                        }
                        .foregroundColor(.seniorDanger)
                    }
                }
            }
            .alert("确认清空", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) {
                    Task {
                        await recycleBinManager.permanentlyDeleteAll()
                    }
                }
            } message: {
                Text("清空回收站将永久删除所有文件，此操作不可恢复")
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
            
            // 文件列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recycleBinManager.items) { item in
                        RecycleBinItemRow(
                            item: item,
                            onRestore: {
                                recycleBinManager.restore(item)
                            },
                            onPermanentDelete: {
                                selectedItem = item
                                showingDeleteAlert = true
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
    
    var body: some View {
        HStack(spacing: 16) {
            // 文件类型图标
            Image(systemName: item.mediaType.systemImageName)
                .font(.title2)
                .foregroundColor(.seniorPrimary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.seniorPrimary.opacity(0.1))
                )
            
            // 文件信息
            VStack(alignment: .leading, spacing: 4) {
                Text(item.fileName)
                    .font(.seniorBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.seniorText)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Text(item.formattedSize)
                        .font(.seniorCaption)
                        .foregroundColor(.seniorSecondary)
                    
                    if let deletedDate = item.deletedDate {
                        Text("删除于 \(formatDeletedDate(deletedDate))")
                            .font(.seniorCaption)
                            .foregroundColor(.seniorSecondary)
                    }
                }
            }
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 12) {
                // 恢复按钮
                Button(action: onRestore) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .foregroundColor(.seniorSuccess)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 永久删除按钮
                Button(action: onPermanentDelete) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.seniorDanger)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private func formatDeletedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

#Preview {
    RecycleBinView()
} 