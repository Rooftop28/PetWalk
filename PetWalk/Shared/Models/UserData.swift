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
    var revealedAchievementHints: Set<String> = []  // 已揭示线索的成就 ID
    
    // MARK: - 每日提醒设置
    var dailyReminderEnabled: Bool = false      // 是否启用每日提醒
    var dailyReminderTime: Date = {             // 旧单次提醒时间（兼容旧数据，默认 18:00）
        var components = DateComponents()
        components.hour = 18
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    /// 多个提醒时间（每天可设置多个，如早/中/晚）
    var dailyReminderTimes: [Date] = []
    var lastNudgedFriends: [String: Date] = [:] // 上次催促好友的时间（friendID: Date）
    
    // MARK: - 奖励系统（称号 & 主题）
    var ownedTitleIds: Set<String> = ["title_default"]    // 已拥有的称号 ID
    var ownedThemeIds: Set<String> = ["theme_default"]    // 已拥有的主题 ID
    var equippedTitleId: String = "title_default"         // 当前装备的称号 ID
    var equippedThemeId: String = "theme_default"         // 当前装备的主题 ID
    
    // MARK: - 用户形象 (Ready Player Me)
    var avatarURL: String?           // Ready Player Me 头像 URL
    var avatarImageCachePath: String? // 本地缓存的头像图片路径
    
    // MARK: - 个性化称呼 (Onboarding)
    var petName: String = "狗狗"
    var ownerNickname: String = "主人"
    var hasCompletedOnboarding: Bool = false
    
    // MARK: - DEPRECATED (保留以兼容旧数据)
    var inventory: [String: Int] = [:] // 旧物品清单，已弃用
    
    // MARK: - 初始化
    #if DEBUG
    // 测试模式：初始 1000 骨头币，方便测试购买功能
    static let initial = UserData()
    #else
    static let initial = UserData()
    #endif
    
    init(
        totalBones: Int = {
            #if DEBUG
            return 1000
            #else
            return 0
            #endif
        }(),
        lastWalkDate: Date? = nil,
        totalWalks: Int = 0,
        totalDistance: Double = 0.0,
        currentStreak: Int = 0,
        maxStreak: Int = 0,
        lastStreakDate: Date? = nil,
        unlockedAchievements: Set<String> = [],
        revealedAchievementHints: Set<String> = [],
        dailyReminderEnabled: Bool = false,
        dailyReminderTime: Date = {
            var components = DateComponents()
            components.hour = 18
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }(),
        dailyReminderTimes: [Date] = [],
        lastNudgedFriends: [String: Date] = [:],
        ownedTitleIds: Set<String> = ["title_default"],
        ownedThemeIds: Set<String> = ["theme_default"],
        equippedTitleId: String = "title_default",
        equippedThemeId: String = "theme_default",
        avatarURL: String? = nil,
        avatarImageCachePath: String? = nil,
        petName: String = "狗狗",
        ownerNickname: String = "主人",
        hasCompletedOnboarding: Bool = false,
        inventory: [String: Int] = [:]
    ) {
        self.totalBones = totalBones
        self.lastWalkDate = lastWalkDate
        self.totalWalks = totalWalks
        self.totalDistance = totalDistance
        self.currentStreak = currentStreak
        self.maxStreak = maxStreak
        self.lastStreakDate = lastStreakDate
        self.unlockedAchievements = unlockedAchievements
        self.revealedAchievementHints = revealedAchievementHints
        self.dailyReminderEnabled = dailyReminderEnabled
        self.dailyReminderTime = dailyReminderTime
        self.dailyReminderTimes = dailyReminderTimes
        self.lastNudgedFriends = lastNudgedFriends
        self.ownedTitleIds = ownedTitleIds
        self.ownedThemeIds = ownedThemeIds
        self.equippedTitleId = equippedTitleId
        self.equippedThemeId = equippedThemeId
        self.avatarURL = avatarURL
        self.avatarImageCachePath = avatarImageCachePath
        self.petName = petName
        self.ownerNickname = ownerNickname
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.inventory = inventory
    }
    
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
    
    /// 检查成就线索是否已揭示
    func isAchievementHintRevealed(_ achievementId: String) -> Bool {
        revealedAchievementHints.contains(achievementId)
    }
    
    /// 检查称号是否已拥有
    func isTitleOwned(_ titleId: String) -> Bool {
        ownedTitleIds.contains(titleId)
    }
    
    /// 检查主题是否已拥有
    func isThemeOwned(_ themeId: String) -> Bool {
        ownedThemeIds.contains(themeId)
    }
    
    /// 检查今天是否可以催促该好友
    func canNudgeFriend(_ friendId: String) -> Bool {
        guard let lastNudged = lastNudgedFriends[friendId] else { return true }
        return !Calendar.current.isDateInToday(lastNudged)
    }
}

