//
//  InventoryView.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/8.
//

// MARK: - ⚠️ DEPRECATED
// 此文件已弃用，保留代码以便后续参考或重新启用。
// 已被成就系统 (AchievementView.swift) 替代。
// 弃用日期: 2026/01/28

import SwiftUI

struct InventoryView: View {
    @ObservedObject var dataManager = DataManager.shared
    
    // 所有的物品列表 (用于渲染网格)
    let allItems = TreasureItem.allItems
    
    // 状态控制
    @State private var selectedItem: TreasureItem? // 查看详情
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // 计算进度
    var unlockedCount: Int {
        allItems.filter { (dataManager.userData.inventory[$0.id] ?? 0) > 0 }.count
    }
    var totalCount: Int { allItems.count }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - 自定义标题栏
                HStack {
                    Text("收藏柜")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.appBrown)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 15) // 添加与进度卡片的间距
                
                // MARK: - 进度区域
                progressHeaderView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 物品网格
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(allItems) { item in
                                let count = dataManager.userData.inventory[item.id] ?? 0
                                let isUnlocked = count > 0
                                
                                Button(action: {
                                    if isUnlocked {
                                        selectedItem = item
                                    }
                                }) {
                                    VStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(isUnlocked ? Color.white : Color.gray.opacity(0.1))
                                                .frame(width: 80, height: 80)
                                                .shadow(color: isUnlocked ? item.rarity.color.opacity(0.3) : .clear, radius: 8)
                                            
                                            // 判断是 Asset Image 还是 SF Symbol
                                            if !item.iconName.contains(".") {
                                                // Asset Image（自定义图片）
                                                Image(item.iconName)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(Circle())
                                                    .opacity(isUnlocked ? 1.0 : 0.3)
                                            } else {
                                                // SF Symbol
                                                Image(systemName: item.iconName)
                                                    .font(.system(size: 36))
                                                    .foregroundColor(isUnlocked ? item.rarity.color : .gray)
                                            }
                                        }
                                        
                                        Text(isUnlocked ? item.name : "???")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(isUnlocked ? .appBrown : .gray)
                                        
                                        if isUnlocked {
                                            Text("x\(count)")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .disabled(!isUnlocked)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item)
                .presentationDetents([.fraction(0.4)])
        }
    }
    
    // MARK: - 进度头部视图
    var progressHeaderView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("收藏进度")
                    .font(.headline)
                    .foregroundColor(.appBrown)
                Spacer()
                Text("\(unlockedCount)/\(totalCount)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: Double(unlockedCount), total: Double(totalCount))
                .tint(.appGreenMain)
                .scaleEffect(x: 1, y: 2, anchor: .center) // 变粗一点
                .clipShape(Capsule())
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
        .padding(.bottom)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - 物品详情弹窗
struct ItemDetailView: View {
    let item: TreasureItem
    @State private var isAnimating = false
    
    // 判断是否为 Asset Image（不包含 "." 的就是自定义图片）
    var isAssetImage: Bool {
        !item.iconName.contains(".")
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 所有物品都有呼吸动画
                if isAssetImage {
                    // Asset Image（自定义图片）
                    Image(item.iconName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .scaleEffect(isAnimating ? 1.05 : 0.95)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 160, height: 160)
                                .shadow(color: item.rarity.color.opacity(0.3), radius: 20)
                        )
                        .onAppear { isAnimating = true }
                } else {
                    // SF Symbol（也有呼吸动画）
                    Image(systemName: item.iconName)
                        .font(.system(size: 80))
                        .foregroundColor(item.rarity.color)
                        .scaleEffect(isAnimating ? 1.05 : 0.95)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: item.rarity.color.opacity(0.3), radius: 20)
                        )
                        .onAppear { isAnimating = true }
                }
                
                VStack(spacing: 5) {
                    Text(item.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.appBrown)
                    
                    Text(item.rarity.title)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(item.rarity.color.opacity(0.2))
                        .foregroundColor(item.rarity.color)
                        .cornerRadius(8)
                }
                
                Text(item.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
        }
    }
}

// MARK: - 抽奖结果弹窗 (共享组件)
struct DrawResultView: View {
    let item: TreasureItem
    let onDismiss: () -> Void
    @State private var isAnimating = false
    
    // 判断是否为 Asset Image
    var isAssetImage: Bool {
        !item.iconName.contains(".")
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("🎉 寻宝成功！")
                    .font(.headline)
                    .foregroundColor(.appBrown)
                    .padding(.top, 40)
                
                // 物品展示动画（所有物品都有呼吸效果）
                VStack(spacing: 15) {
                    if isAssetImage {
                        // Asset Image（自定义图片）
                        Image(item.iconName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 160)
                            .clipShape(Circle())
                            .scaleEffect(isAnimating ? 1.05 : 0.95)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 180, height: 180)
                                    .shadow(color: item.rarity.color.opacity(0.5), radius: 20)
                            )
                            .onAppear { isAnimating = true }
                    } else {
                        // SF Symbol（也有呼吸动画）
                        Image(systemName: item.iconName)
                            .font(.system(size: 100))
                            .foregroundColor(item.rarity.color)
                            .scaleEffect(isAnimating ? 1.05 : 0.95)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                            .shadow(color: item.rarity.color.opacity(0.5), radius: 20)
                            .padding()
                            .onAppear { isAnimating = true }
                    }
                    
                    Text(item.name)
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(.appBrown)
                    
                    Text(item.rarity.title)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(item.rarity.color.opacity(0.2))
                        .foregroundColor(item.rarity.color)
                        .cornerRadius(8)
                }
                
                Text(item.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Text("收下")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appGreenMain)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
    }
}
