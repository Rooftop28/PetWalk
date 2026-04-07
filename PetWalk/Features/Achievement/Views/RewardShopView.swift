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
    
    // 选中的 Tab（默认选中可见 Tab 列表中的第一个）
    @State private var selectedTab: ShopTab = ShopTab.visibleTabs.first ?? .themes
    
    // 购买/装备反馈
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    @State private var feedbackIsSuccess = true
    
    enum ShopTab: String, CaseIterable {
        case titles = "称号"
        case themes = "主题"
        case hints = "线索"
        
        var iconSymbol: String {
            switch self {
            case .titles: return "person.text.rectangle.fill"
            case .themes: return "paintpalette.fill"
            case .hints: return "lightbulb.fill"
            }
        }
        
        /// V1 可见的 Tab
        static var visibleTabs: [ShopTab] {
            var tabs: [ShopTab] = []
            if FeatureFlags.enableTitleSystem { tabs.append(.titles) }
            tabs.append(.themes)
            tabs.append(.hints)
            return tabs
        }
    }
    
    // 线索抽取状态
    @State private var isDrawingHint = false
    @State private var drawnAchievement: Achievement?
    @State private var showHintResult = false
    
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
                            } else if selectedTab == .themes {
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
                            } else {
                                // 线索商店
                                hintsShopContent
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
            ForEach(ShopTab.visibleTabs, id: \.self) { tab in
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
    
    // MARK: - 线索商店内容
    var hintsShopContent: some View {
        VStack(spacing: 20) {
            // 说明卡片
            VStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                
                Text("成就线索")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.appBrown)
                
                Text("揭示隐藏成就的详细信息，帮助你定向挑战！\n解锁线索后，成就会显示具体内容，但仍需完成条件才能获得奖励。")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.yellow.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            
            // 统计信息
            let secretAchievements = Achievement.allAchievements.filter { $0.isSecret }
            let revealedCount = dataManager.userData.revealedAchievementHints.count
            let unlockedSecretCount = secretAchievements.filter { dataManager.userData.isAchievementUnlocked($0.id) }.count
            let remainingSecret = secretAchievements.count - revealedCount - unlockedSecretCount
            
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("\(secretAchievements.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("隐藏成就")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 4) {
                    Text("\(revealedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    Text("已揭示")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 4) {
                    Text("\(remainingSecret)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("待探索")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: .black.opacity(0.05), radius: 5)
            
            // 随机抽取卡片
            HintDrawCard(
                title: "随机线索",
                description: "随机揭示一个隐藏成就的详细信息",
                price: 30,
                iconSymbol: "dice.fill",
                canAfford: dataManager.userData.totalBones >= 30,
                isAvailable: remainingSecret > 0,
                onDraw: { drawRandomHint() }
            )
            
            // 按类别抽取
            VStack(spacing: 12) {
                Text("指定类别线索")
                    .font(.headline)
                    .foregroundColor(.appBrown)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    let categorySecrets = secretAchievements.filter { $0.category == category }
                    let categoryRemaining = categorySecrets.filter { 
                        !dataManager.userData.isAchievementUnlocked($0.id) &&
                        !dataManager.userData.isAchievementHintRevealed($0.id)
                    }.count
                    
                    if categorySecrets.count > 0 {
                        HintCategoryCard(
                            category: category,
                            remainingCount: categoryRemaining,
                            price: 50,
                            canAfford: dataManager.userData.totalBones >= 50,
                            onDraw: { drawCategoryHint(category) }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showHintResult) {
            if let achievement = drawnAchievement {
                HintRevealView(achievement: achievement)
            }
        }
    }
    
    // MARK: - 抽取线索逻辑
    
    private func drawRandomHint() {
        let secretAchievements = Achievement.allAchievements.filter { achievement in
            achievement.isSecret &&
            !dataManager.userData.isAchievementUnlocked(achievement.id) &&
            !dataManager.userData.isAchievementHintRevealed(achievement.id)
        }
        
        guard !secretAchievements.isEmpty else {
            showFeedbackMessage("没有可揭示的隐藏成就了", success: false)
            return
        }
        
        guard dataManager.userData.totalBones >= 30 else {
            showFeedbackMessage("骨头币不足", success: false)
            return
        }
        
        // 扣费
        var userData = dataManager.userData
        userData.totalBones -= 30
        
        // 随机选择一个
        if let selected = secretAchievements.randomElement() {
            userData.revealedAchievementHints.insert(selected.id)
            drawnAchievement = selected
            showHintResult = true
        }
        
        dataManager.updateUserData(userData)
    }
    
    private func drawCategoryHint(_ category: AchievementCategory) {
        let categorySecrets = Achievement.allAchievements.filter { achievement in
            achievement.isSecret &&
            achievement.category == category &&
            !dataManager.userData.isAchievementUnlocked(achievement.id) &&
            !dataManager.userData.isAchievementHintRevealed(achievement.id)
        }
        
        guard !categorySecrets.isEmpty else {
            showFeedbackMessage("该类别没有可揭示的隐藏成就了", success: false)
            return
        }
        
        guard dataManager.userData.totalBones >= 50 else {
            showFeedbackMessage("骨头币不足", success: false)
            return
        }
        
        // 扣费
        var userData = dataManager.userData
        userData.totalBones -= 50
        
        // 随机选择一个
        if let selected = categorySecrets.randomElement() {
            userData.revealedAchievementHints.insert(selected.id)
            drawnAchievement = selected
            showHintResult = true
        }
        
        dataManager.updateUserData(userData)
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

// MARK: - 线索抽取卡片
struct HintDrawCard: View {
    let title: String
    let description: String
    let price: Int
    let iconSymbol: String
    let canAfford: Bool
    let isAvailable: Bool
    let onDraw: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: iconSymbol)
                    .font(.system(size: 26))
                    .foregroundColor(.yellow)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.appBrown)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 抽取按钮
            Button(action: onDraw) {
                HStack(spacing: 4) {
                    Text("🦴")
                    Text("\(price)")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(canAfford && isAvailable ? Color.yellow : Color.gray)
                .clipShape(Capsule())
            }
            .disabled(!canAfford || !isAvailable)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - 类别线索卡片
struct HintCategoryCard: View {
    let category: AchievementCategory
    let remainingCount: Int
    let price: Int
    let canAfford: Bool
    let onDraw: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: category.iconSymbol)
                .font(.system(size: 20))
                .foregroundColor(category.color)
                .frame(width: 36, height: 36)
                .background(category.color.opacity(0.15))
                .clipShape(Circle())
            
            // 内容
            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appBrown)
                
                Text("剩余 \(remainingCount) 个隐藏成就")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 按钮
            if remainingCount > 0 {
                Button(action: onDraw) {
                    HStack(spacing: 4) {
                        Text("🦴")
                        Text("\(price)")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(canAfford ? category.color : Color.gray)
                    .clipShape(Capsule())
                }
                .disabled(!canAfford)
            } else {
                Text("已揭示全部")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 3)
    }
}

// MARK: - 线索揭示弹窗
struct HintRevealView: View {
    let achievement: Achievement
    @Environment(\.dismiss) var dismiss
    
    @State private var isRevealing = true
    @State private var cardRotation: Double = 0
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 30) {
                if isRevealing {
                    // 翻转动画
                    revealingCard
                } else {
                    // 揭示的内容
                    revealedContent
                }
            }
            .padding()
        }
        .onAppear {
            // 翻转动画
            withAnimation(.easeInOut(duration: 0.6).delay(0.5)) {
                cardRotation = 180
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation {
                    isRevealing = false
                    showContent = true
                }
            }
        }
    }
    
    private var revealingCard: some View {
        ZStack {
            // 背面（问号）
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.purple, Color.purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 250, height: 350)
                .overlay(
                    VStack(spacing: 20) {
                        Image(systemName: "questionmark")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("隐藏成就")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                )
                .rotation3DEffect(
                    .degrees(cardRotation > 90 ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(cardRotation < 90 ? 1 : 0)
            
            // 正面（成就信息）
            achievementCard
                .rotation3DEffect(
                    .degrees(cardRotation - 180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(cardRotation > 90 ? 1 : 0)
        }
        .rotation3DEffect(
            .degrees(cardRotation),
            axis: (x: 0, y: 1, z: 0)
        )
    }
    
    private var achievementCard: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .frame(width: 250, height: 350)
            .overlay(
                VStack(spacing: 15) {
                    // 图标
                    ZStack {
                        Circle()
                            .fill(achievement.category.color.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: achievement.iconSymbol)
                            .font(.system(size: 36))
                            .foregroundColor(achievement.category.color)
                    }
                    
                    // 稀有度
                    Text(achievement.rarity.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(achievement.rarity.color.opacity(0.2))
                        .foregroundColor(achievement.rarity.color)
                        .clipShape(Capsule())
                    
                    // 名称
                    Text(achievement.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.appBrown)
                        .multilineTextAlignment(.center)
                    
                    // 描述
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // 奖励
                    HStack(spacing: 4) {
                        Text("🦴")
                        Text("+\(achievement.rewardBones)")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.appGreenMain)
                }
                .padding()
            )
            .shadow(color: .black.opacity(0.1), radius: 10)
    }
    
    private var revealedContent: some View {
        VStack(spacing: 20) {
            // 成就卡片
            achievementCard
            
            // 提示
            Text("成就线索已揭示！")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("完成条件后即可解锁获得奖励")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            // 关闭按钮
            Button(action: { dismiss() }) {
                Text("知道了")
                    .font(.headline)
                    .foregroundColor(.appBrown)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    RewardShopView()
}
