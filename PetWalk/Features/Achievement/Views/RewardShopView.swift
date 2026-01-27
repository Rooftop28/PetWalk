//
//  RewardShopView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI

struct RewardShopView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    
    // 选中的 Tab
    @State private var selectedTab: ShopTab = .titles
    
    // 购买/装备反馈
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    @State private var feedbackIsSuccess = true
    
    enum ShopTab: String, CaseIterable {
        case titles = "称号"
        case themes = "主题"
        
        var iconSymbol: String {
            switch self {
            case .titles: return "person.text.rectangle.fill"
            case .themes: return "paintpalette.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - 余额显示
                    balanceHeader
                    
                    // MARK: - Tab 切换
                    shopTabBar
                    
                    // MARK: - 商品列表
                    ScrollView {
                        VStack(spacing: 15) {
                            if selectedTab == .titles {
                                ForEach(UserTitle.allTitles) { title in
                                    TitleCard(
                                        title: title,
                                        isOwned: dataManager.userData.isTitleOwned(title.id),
                                        isEquipped: dataManager.userData.equippedTitleId == title.id,
                                        canAfford: dataManager.userData.totalBones >= title.price,
                                        onBuy: { buyTitle(title) },
                                        onEquip: { equipTitle(title) }
                                    )
                                }
                            } else {
                                ForEach(AppTheme.allThemes) { theme in
                                    ThemeCard(
                                        theme: theme,
                                        isOwned: dataManager.userData.isThemeOwned(theme.id),
                                        isEquipped: dataManager.userData.equippedThemeId == theme.id,
                                        canAfford: dataManager.userData.totalBones >= theme.price,
                                        onBuy: { buyTheme(theme) },
                                        onEquip: { equipTheme(theme) }
                                    )
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
                
                // 反馈弹窗
                if showFeedback {
                    feedbackOverlay
                }
            }
            .navigationTitle("奖励商店")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(.appBrown)
                }
            }
        }
    }
    
    // MARK: - 余额头部
    var balanceHeader: some View {
        VStack(spacing: 10) {
            Text("当前拥有")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack(spacing: 8) {
                Text("🦴")
                    .font(.system(size: 36))
                Text("\(dataManager.userData.totalBones)")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundColor(.appBrown)
                    .contentTransition(.numericText(value: Double(dataManager.userData.totalBones)))
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
    }
    
    // MARK: - Tab Bar
    var shopTabBar: some View {
        HStack(spacing: 0) {
            ForEach(ShopTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.iconSymbol)
                        Text(tab.rawValue)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedTab == tab ? .white : .appBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.appGreenMain : Color.clear)
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
    
    // MARK: - 反馈弹窗
    var feedbackOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 10) {
                Image(systemName: feedbackIsSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(feedbackIsSuccess ? .green : .red)
                Text(feedbackMessage)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.8))
            .clipShape(Capsule())
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showFeedback = false
                }
            }
        }
    }
    
    // MARK: - 购买/装备逻辑
    
    private func buyTitle(_ title: UserTitle) {
        guard dataManager.userData.totalBones >= title.price else {
            showFeedbackMessage("骨头币不足", success: false)
            return
        }
        
        var userData = dataManager.userData
        userData.totalBones -= title.price
        userData.ownedTitleIds.insert(title.id)
        dataManager.updateUserData(userData)
        
        showFeedbackMessage("购买成功：\(title.name)", success: true)
    }
    
    private func equipTitle(_ title: UserTitle) {
        var userData = dataManager.userData
        userData.equippedTitleId = title.id
        dataManager.updateUserData(userData)
        
        showFeedbackMessage("已装备：\(title.name)", success: true)
    }
    
    private func buyTheme(_ theme: AppTheme) {
        guard dataManager.userData.totalBones >= theme.price else {
            showFeedbackMessage("骨头币不足", success: false)
            return
        }
        
        var userData = dataManager.userData
        userData.totalBones -= theme.price
        userData.ownedThemeIds.insert(theme.id)
        dataManager.updateUserData(userData)
        
        showFeedbackMessage("购买成功：\(theme.name)", success: true)
    }
    
    private func equipTheme(_ theme: AppTheme) {
        // 使用 ThemeManager 应用主题（会自动保存到 UserData）
        ThemeManager.shared.applyTheme(theme)
        
        showFeedbackMessage("已装备：\(theme.name)", success: true)
    }
    
    private func showFeedbackMessage(_ message: String, success: Bool) {
        feedbackMessage = message
        feedbackIsSuccess = success
        withAnimation {
            showFeedback = true
        }
    }
}

// MARK: - 称号卡片
struct TitleCard: View {
    let title: UserTitle
    let isOwned: Bool
    let isEquipped: Bool
    let canAfford: Bool
    let onBuy: () -> Void
    let onEquip: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // 图标
            ZStack {
                Circle()
                    .fill(isOwned ? Color.appGreenMain.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: title.iconSymbol)
                    .font(.system(size: 26))
                    .foregroundColor(isOwned ? .appGreenMain : .gray)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title.name)
                        .font(.headline)
                        .foregroundColor(.appBrown)
                    
                    if isEquipped {
                        Text("装备中")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appGreenMain)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Text(title.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 操作按钮
            if isOwned {
                if isEquipped {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.appGreenMain)
                } else {
                    Button(action: onEquip) {
                        Text("装备")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.appGreenMain)
                            .clipShape(Capsule())
                    }
                }
            } else {
                if title.price == 0 {
                    Text("免费")
                        .font(.subheadline)
                        .foregroundColor(.appGreenMain)
                } else {
                    Button(action: onBuy) {
                        HStack(spacing: 4) {
                            Text("🦴")
                            Text("\(title.price)")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(canAfford ? Color.appGreenMain : Color.gray)
                        .clipShape(Capsule())
                    }
                    .disabled(!canAfford)
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - 主题卡片
struct ThemeCard: View {
    let theme: AppTheme
    let isOwned: Bool
    let isEquipped: Bool
    let canAfford: Bool
    let onBuy: () -> Void
    let onEquip: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 主题预览
            HStack(spacing: 0) {
                Rectangle()
                    .fill(theme.backgroundColor)
                Rectangle()
                    .fill(theme.primaryColor)
                Rectangle()
                    .fill(theme.accentColor)
            }
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 15)
            .padding(.top, 15)
            
            HStack(spacing: 15) {
                // 图标
                ZStack {
                    Circle()
                        .fill(isOwned ? theme.primaryColor.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: theme.iconSymbol)
                        .font(.system(size: 22))
                        .foregroundColor(isOwned ? theme.primaryColor : .gray)
                }
                
                // 内容
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(theme.name)
                            .font(.headline)
                            .foregroundColor(.appBrown)
                        
                        if isEquipped {
                            Text("使用中")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 操作按钮
                if isOwned {
                    if isEquipped {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.primaryColor)
                    } else {
                        Button(action: onEquip) {
                            Text("使用")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(theme.primaryColor)
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    if theme.price == 0 {
                        Text("免费")
                            .font(.subheadline)
                            .foregroundColor(.appGreenMain)
                    } else {
                        Button(action: onBuy) {
                            HStack(spacing: 4) {
                                Text("🦴")
                                Text("\(theme.price)")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(canAfford ? Color.appGreenMain : Color.gray)
                            .clipShape(Capsule())
                        }
                        .disabled(!canAfford)
                    }
                }
            }
            .padding(15)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

#Preview {
    RewardShopView()
}
