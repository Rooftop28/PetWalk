//
//  AchievementView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI

struct AchievementView: View {
    @ObservedObject var dataManager = DataManager.shared
    
    // 选中的分类 Tab
    @State private var selectedCategory: AchievementCategory = .distance
    
    // 选中查看详情的成就
    @State private var selectedAchievement: Achievement?
    
    // 计算进度
    var unlockedCount: Int {
        dataManager.userData.unlockedAchievements.count
    }
    var totalCount: Int {
        Achievement.allAchievements.count
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - 自定义标题栏
                HStack {
                    Text("成就")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.appBrown)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 15)
                
                // MARK: - 进度区域
                progressHeaderView
                
                // MARK: - 分类 Tab
                categoryTabBar
                
                // MARK: - 成就列表
                ScrollView {
                    LazyVStack(spacing: 15) {
                        let achievements = Achievement.allAchievements.filter { $0.category == selectedCategory }
                        ForEach(achievements) { achievement in
                            AchievementCard(
                                achievement: achievement,
                                isUnlocked: dataManager.userData.isAchievementUnlocked(achievement.id),
                                progress: AchievementManager.shared.getProgress(for: achievement, userData: dataManager.userData)
                            )
                            .onTapGesture {
                                selectedAchievement = achievement
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 80) // 底部留白给 TabBar
                }
            }
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailView(
                achievement: achievement,
                isUnlocked: dataManager.userData.isAchievementUnlocked(achievement.id),
                progress: AchievementManager.shared.getProgress(for: achievement, userData: dataManager.userData)
            )
            .presentationDetents([.fraction(0.5)])
        }
    }
    
    // MARK: - 进度头部视图
    var progressHeaderView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("成就进度")
                    .font(.headline)
                    .foregroundColor(.appBrown)
                Spacer()
                Text("\(unlockedCount)/\(totalCount)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: Double(unlockedCount), total: Double(totalCount))
                .tint(.appGreenMain)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .clipShape(Capsule())
            
            // 统计数据展示
            HStack(spacing: 20) {
                StatItem(title: "总里程", value: String(format: "%.1f km", dataManager.userData.totalDistance))
                StatItem(title: "总次数", value: "\(dataManager.userData.totalWalks) 次")
                StatItem(title: "连续打卡", value: "\(dataManager.userData.currentStreak) 天")
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
        .padding(.bottom)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 分类 Tab Bar
    var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - 统计项组件
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.appBrown)
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - 分类 Tab 组件
struct CategoryTab: View {
    let category: AchievementCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.iconSymbol)
                    .font(.system(size: 14))
                Text(category.title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .appBrown)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? category.color : Color.white)
            .clipShape(Capsule())
            .shadow(color: isSelected ? category.color.opacity(0.3) : .black.opacity(0.05), radius: 5)
        }
    }
}

// MARK: - 成就卡片组件
struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: (current: Int, target: Int)
    
    var progressPercentage: Double {
        guard progress.target > 0 else { return 0 }
        return min(1.0, Double(progress.current) / Double(progress.target))
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // 图标
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.category.color.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.iconSymbol)
                    .font(.system(size: 26))
                    .foregroundColor(isUnlocked ? achievement.category.color : .gray)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(achievement.name)
                        .font(.headline)
                        .foregroundColor(isUnlocked ? .appBrown : .gray)
                    
                    if isUnlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.appGreenMain)
                    }
                }
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                // 进度条
                if !isUnlocked {
                    HStack {
                        ProgressView(value: progressPercentage)
                            .tint(achievement.category.color)
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        
                        Text("\(progress.current)/\(progress.target)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
            
            Spacer()
            
            // 奖励
            VStack {
                Text("🦴")
                    .font(.title3)
                Text("+\(achievement.rewardBones)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isUnlocked ? .appGreenMain : .gray)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
        .opacity(isUnlocked ? 1.0 : 0.8)
    }
}

// MARK: - 成就详情弹窗
struct AchievementDetailView: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: (current: Int, target: Int)
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 图标
                ZStack {
                    Circle()
                        .fill(isUnlocked ? achievement.category.color.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .shadow(color: isUnlocked ? achievement.category.color.opacity(0.3) : .clear, radius: 20)
                    
                    Image(systemName: achievement.iconSymbol)
                        .font(.system(size: 50))
                        .foregroundColor(isUnlocked ? achievement.category.color : .gray)
                        .scaleEffect(isAnimating ? 1.05 : 0.95)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                .onAppear { isAnimating = true }
                .padding(.top, 30)
                
                // 名称和状态
                VStack(spacing: 8) {
                    HStack {
                        Text(achievement.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.appBrown)
                        
                        if isUnlocked {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title2)
                                .foregroundColor(.appGreenMain)
                        }
                    }
                    
                    Text(achievement.category.title)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(achievement.category.color.opacity(0.2))
                        .foregroundColor(achievement.category.color)
                        .cornerRadius(8)
                }
                
                // 描述
                Text(achievement.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 30)
                
                // 进度或奖励
                if isUnlocked {
                    HStack(spacing: 5) {
                        Text("已获得奖励")
                            .foregroundColor(.gray)
                        Text("🦴 +\(achievement.rewardBones)")
                            .fontWeight(.bold)
                            .foregroundColor(.appGreenMain)
                    }
                    .font(.headline)
                } else {
                    VStack(spacing: 8) {
                        ProgressView(value: Double(progress.current), total: Double(progress.target))
                            .tint(achievement.category.color)
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .frame(width: 200)
                        
                        Text("进度: \(progress.current) / \(progress.target)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 5) {
                            Text("完成后获得")
                                .foregroundColor(.gray)
                            Text("🦴 +\(achievement.rewardBones)")
                                .fontWeight(.bold)
                                .foregroundColor(.appBrown)
                        }
                        .font(.subheadline)
                    }
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    AchievementView()
}
