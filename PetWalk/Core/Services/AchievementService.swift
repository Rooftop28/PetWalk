//
//  AchievementService.swift
//  PetWalk
//
//  AI Agent API 层 — 成就系统查询接口
//

import Foundation

// MARK: - API 响应模型

/// 成就总览响应
struct AchievementOverviewResponse: Codable {
    let totalCount: Int
    let unlockedCount: Int
    let progressPercent: Double
    let totalBones: Int
    let currentStreak: Int
    let categories: [CategoryProgress]
    let aiSummary: String
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case unlockedCount = "unlocked_count"
        case progressPercent = "progress_percent"
        case totalBones = "total_bones"
        case currentStreak = "current_streak"
        case categories
        case aiSummary = "ai_summary"
        case deepLinkURL = "deep_link_url"
    }
}

/// 分类进度
struct CategoryProgress: Codable {
    let category: String
    let unlocked: Int
    let total: Int
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case category, unlocked, total
        case deepLinkURL = "deep_link_url"
    }
}

/// 最近解锁成就响应
struct RecentAchievementsResponse: Codable {
    let achievements: [AchievementDetailResponse]
    let aiSummary: String
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case achievements
        case aiSummary = "ai_summary"
        case deepLinkURL = "deep_link_url"
    }
}

/// 成就详细信息（含进度）
struct AchievementDetailResponse: Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let rarity: String
    let rewardBones: Int
    let isUnlocked: Bool
    let isSecret: Bool
    let isHintRevealed: Bool
    let progressCurrent: Int
    let progressTarget: Int
    let progressPercent: Double
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, rarity
        case rewardBones = "reward_bones"
        case isUnlocked = "is_unlocked"
        case isSecret = "is_secret"
        case isHintRevealed = "is_hint_revealed"
        case progressCurrent = "progress_current"
        case progressTarget = "progress_target"
        case progressPercent = "progress_percent"
        case deepLinkURL = "deep_link_url"
    }
}

/// 可能完成的成就建议响应
struct AchievementSuggestionsResponse: Codable {
    let suggestions: [AchievementSuggestion]
    let aiSummary: String
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case suggestions
        case aiSummary = "ai_summary"
        case deepLinkURL = "deep_link_url"
    }
}

/// 成就建议
struct AchievementSuggestion: Codable {
    let achievement: AchievementDetailResponse
    let reason: String
    let difficulty: String
    
    enum CodingKeys: String, CodingKey {
        case achievement, reason, difficulty
    }
}

/// 天气相关成就建议请求
struct WeatherSuggestionRequest: Codable {
    let condition: String?
    let temperature: Double?
    
    enum CodingKeys: String, CodingKey {
        case condition, temperature
    }
}

// MARK: - AchievementService

@MainActor
class AchievementService {
    static let shared = AchievementService()
    
    private let dataManager = DataManager.shared
    private let achievementManager = AchievementManager.shared
    
    private init() {}
    
    // MARK: - 成就总览
    
    /// 获取成就系统整体进度
    /// - Returns: `AchievementOverviewResponse` 含各类别进度和 AI 总结
    func getOverview() -> AchievementOverviewResponse {
        let userData = dataManager.userData
        let all = Achievement.allAchievements
        let unlocked = userData.unlockedAchievements
        let pct = all.isEmpty ? 0 : (Double(unlocked.count) / Double(all.count)) * 100
        
        let catProgress = AchievementCategory.allCases.map { cat in
            let catAll = all.filter { $0.category == cat }
            let catUnlocked = catAll.filter { unlocked.contains($0.id) }
            return CategoryProgress(
                category: cat.title,
                unlocked: catUnlocked.count,
                total: catAll.count,
                deepLinkURL: "petwalk://achievement"
            )
        }
        
        let petName = dataManager.userData.petName
        let pctStr = String(format: "%.0f", pct)
        let summary: String
        if unlocked.isEmpty {
            summary = "\(petName)还没有解锁任何成就，出门遛弯就能获得第一个！"
        } else if pct >= 80 {
            summary = "太厉害了！\(petName)已经解锁了\(unlocked.count)/\(all.count)个成就（\(pctStr)%），即将全部达成！"
        } else {
            summary = "\(petName)目前解锁了\(unlocked.count)/\(all.count)个成就（\(pctStr)%），继续加油！"
        }
        
        return AchievementOverviewResponse(
            totalCount: all.count,
            unlockedCount: unlocked.count,
            progressPercent: pct,
            totalBones: userData.totalBones,
            currentStreak: userData.currentStreak,
            categories: catProgress,
            aiSummary: summary,
            deepLinkURL: "petwalk://achievement"
        )
    }
    
    // MARK: - 最近完成的成就
    
    /// 获取最近解锁的成就列表
    /// - Parameter limit: 最多返回的条数（默认 5）
    /// - Returns: `RecentAchievementsResponse`
    func getRecentlyUnlocked(limit: Int = 5) -> RecentAchievementsResponse {
        let userData = dataManager.userData
        let unlocked = userData.unlockedAchievements
        
        let unlockedAchievements = Achievement.allAchievements
            .filter { unlocked.contains($0.id) }
            .prefix(limit)
            .map { makeDetailResponse(for: $0, userData: userData) }
        
        let petName = dataManager.userData.petName
        let summary: String
        if unlockedAchievements.isEmpty {
            summary = "\(petName)还没有解锁任何成就。"
        } else {
            let names = unlockedAchievements.prefix(3).map { "「\($0.name)」" }.joined(separator: "、")
            summary = "\(petName)最近完成了\(names)等\(unlockedAchievements.count)个成就。"
        }
        
        return RecentAchievementsResponse(
            achievements: Array(unlockedAchievements),
            aiSummary: summary,
            deepLinkURL: "petwalk://achievement"
        )
    }
    
    // MARK: - 查看单个成就
    
    /// 获取指定成就的详情
    /// - Parameter achievementId: 成就 ID
    /// - Returns: `AchievementDetailResponse?`
    func getAchievement(id achievementId: String) -> AchievementDetailResponse? {
        guard let achievement = Achievement.allAchievements.first(where: { $0.id == achievementId }) else {
            return nil
        }
        return makeDetailResponse(for: achievement, userData: dataManager.userData)
    }
    
    // MARK: - 今天可能完成的成就（含天气建议）
    
    /// 根据当前环境（天气、时间、用户进度）推荐最可能完成的成就
    /// - Parameter weatherRequest: 可选的天气信息（不传则忽略天气维度）
    /// - Returns: `AchievementSuggestionsResponse`
    func getSuggestions(weather: WeatherSuggestionRequest? = nil) -> AchievementSuggestionsResponse {
        let userData = dataManager.userData
        let unlocked = userData.unlockedAchievements
        let petName = userData.petName
        
        // 过滤出未解锁的成就
        let remaining = Achievement.allAchievements.filter { !unlocked.contains($0.id) }
        
        var suggestions: [AchievementSuggestion] = []
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        
        // 1. 接近完成的成就（进度 > 70%）
        for a in remaining {
            let progress = achievementManager.getProgress(for: a, userData: userData)
            let pct = progress.target > 0 ? Double(progress.current) / Double(progress.target) : 0
            if pct >= 0.7 && pct < 1.0 {
                let detail = makeDetailResponse(for: a, userData: userData)
                let remaining = progress.target - progress.current
                suggestions.append(AchievementSuggestion(
                    achievement: detail,
                    reason: "再需要\(remaining)\(a.category == .distance ? "公里" : "次")即可达成！",
                    difficulty: "容易"
                ))
            }
        }
        
        // 2. 天气匹配的成就
        if let w = weather {
            for a in remaining where a.weatherCondition != nil {
                if let cond = w.condition, a.weatherCondition == cond {
                    let detail = makeDetailResponse(for: a, userData: userData)
                    suggestions.append(AchievementSuggestion(
                        achievement: detail,
                        reason: "当前天气是\(cond)，正好可以挑战这个成就！",
                        difficulty: "中等"
                    ))
                }
                if let temp = w.temperature {
                    if let min = a.temperatureMin, temp <= min {
                        let detail = makeDetailResponse(for: a, userData: userData)
                        suggestions.append(AchievementSuggestion(
                            achievement: detail,
                            reason: "当前气温\(Int(temp))°C，符合低温条件！",
                            difficulty: "中等"
                        ))
                    }
                    if let max = a.temperatureMax, temp >= max {
                        let detail = makeDetailResponse(for: a, userData: userData)
                        suggestions.append(AchievementSuggestion(
                            achievement: detail,
                            reason: "当前气温\(Int(temp))°C，符合高温条件！",
                            difficulty: "中等"
                        ))
                    }
                }
            }
        }
        
        // 3. 时间匹配的成就
        for a in remaining {
            if let start = a.timeRangeStart, let end = a.timeRangeEnd {
                let inRange = start < end ? (hour >= start && hour < end) : (hour >= start || hour < end)
                if inRange {
                    let detail = makeDetailResponse(for: a, userData: userData)
                    suggestions.append(AchievementSuggestion(
                        achievement: detail,
                        reason: "现在是\(hour)点，正好在\(start):00-\(end):00之间！",
                        difficulty: "中等"
                    ))
                }
            }
        }
        
        // 4. 一次性简单成就（requirement = 1 且未完成的）
        for a in remaining where a.requirement == 1 && a.category == .performance {
            if suggestions.count >= 8 { break }
            let detail = makeDetailResponse(for: a, userData: userData)
            suggestions.append(AchievementSuggestion(
                achievement: detail,
                reason: "这是一个单次遛狗就能完成的挑战！",
                difficulty: "看运气"
            ))
        }
        
        // 去重
        var seenIds = Set<String>()
        suggestions = suggestions.filter { s in
            let id = s.achievement.id
            guard !seenIds.contains(id) else { return false }
            seenIds.insert(id)
            return true
        }
        
        // 限制数量
        suggestions = Array(suggestions.prefix(8))
        
        let summary: String
        if suggestions.isEmpty {
            summary = "\(petName)目前没有特别接近完成的成就，继续坚持遛弯吧！"
        } else {
            let topNames = suggestions.prefix(3).map { "「\($0.achievement.name)」" }.joined(separator: "、")
            summary = "\(petName)今天有机会完成\(topNames)等\(suggestions.count)个成就，出门试试吧！"
        }
        
        return AchievementSuggestionsResponse(
            suggestions: suggestions,
            aiSummary: summary,
            deepLinkURL: "petwalk://achievement"
        )
    }
    
    // MARK: - 辅助方法
    
    private func makeDetailResponse(for achievement: Achievement, userData: UserData) -> AchievementDetailResponse {
        let progress = achievementManager.getProgress(for: achievement, userData: userData)
        let pct = progress.target > 0 ? Double(progress.current) / Double(progress.target) * 100 : 0
        
        return AchievementDetailResponse(
            id: achievement.id,
            name: achievement.name,
            description: achievement.description,
            category: achievement.category.title,
            rarity: achievement.rarity.displayName,
            rewardBones: achievement.rewardBones,
            isUnlocked: userData.isAchievementUnlocked(achievement.id),
            isSecret: achievement.isSecret,
            isHintRevealed: userData.isAchievementHintRevealed(achievement.id),
            progressCurrent: progress.current,
            progressTarget: progress.target,
            progressPercent: min(100, pct),
            deepLinkURL: "petwalk://achievement/\(achievement.id)"
        )
    }
}
