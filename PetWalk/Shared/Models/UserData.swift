//
//  UserData.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/8.
//

import Foundation

struct UserData: Codable {
    // MARK: - 骨头币系统
    var totalBones: Int = 0          // 骨头币余额
    
    // MARK: - 遛狗统计
    var lastWalkDate: Date?          // 上次遛狗结束时间，用于计算宠物心情
    var totalWalks: Int = 0          // 总遛狗次数
    var totalDistance: Double = 0.0  // 总里程（公里）
    var currentStreak: Int = 0       // 当前连续打卡天数
    var maxStreak: Int = 0           // 历史最高连续打卡天数
    var lastStreakDate: Date?        // 上次打卡日期（用于计算连续打卡）
    
    // MARK: - 成就系统
    var unlockedAchievements: Set<String> = []  // 已解锁成就 ID 集合
    
    // MARK: - 奖励系统（称号 & 主题）
    var ownedTitleIds: Set<String> = ["title_default"]    // 已拥有的称号 ID
    var ownedThemeIds: Set<String> = ["theme_default"]    // 已拥有的主题 ID
    var equippedTitleId: String = "title_default"         // 当前装备的称号 ID
    var equippedThemeId: String = "theme_default"         // 当前装备的主题 ID
    
    // MARK: - 用户形象 (Ready Player Me)
    var avatarURL: String?           // Ready Player Me 头像 URL
    var avatarImageCachePath: String? // 本地缓存的头像图片路径
    
    // MARK: - DEPRECATED (保留以兼容旧数据)
    var inventory: [String: Int] = [:] // 旧物品清单，已弃用
    
    // MARK: - 初始化
    static let initial = UserData(
        totalBones: 0,
        lastWalkDate: nil,
        totalWalks: 0,
        totalDistance: 0.0,
        currentStreak: 0,
        maxStreak: 0,
        lastStreakDate: nil,
        unlockedAchievements: [],
        ownedTitleIds: ["title_default"],
        ownedThemeIds: ["theme_default"],
        equippedTitleId: "title_default",
        equippedThemeId: "theme_default",
        avatarURL: nil,
        avatarImageCachePath: nil,
        inventory: [:]
    )
    
    // MARK: - 辅助方法
    
    /// 获取当前装备的称号
    var equippedTitle: UserTitle {
        UserTitle.title(byId: equippedTitleId) ?? UserTitle.defaultTitle
    }
    
    /// 获取当前装备的主题
    var equippedTheme: AppTheme {
        AppTheme.theme(byId: equippedThemeId) ?? AppTheme.defaultTheme
    }
    
    /// 检查成就是否已解锁
    func isAchievementUnlocked(_ achievementId: String) -> Bool {
        unlockedAchievements.contains(achievementId)
    }
    
    /// 检查称号是否已拥有
    func isTitleOwned(_ titleId: String) -> Bool {
        ownedTitleIds.contains(titleId)
    }
    
    /// 检查主题是否已拥有
    func isThemeOwned(_ themeId: String) -> Bool {
        ownedThemeIds.contains(themeId)
    }
}

