//
//  AchievementManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation

class AchievementManager {
    static let shared = AchievementManager()
    
    private init() {}
    
    // MARK: - 成就检测（遛狗结束后调用）
    
    /// 检测并解锁成就，返回新解锁的成就列表
    /// - Parameters:
    ///   - userData: 当前用户数据
    ///   - walkDistance: 本次遛狗距离（公里）
    ///   - walkStartTime: 本次遛狗开始时间
    /// - Returns: 新解锁的成就数组
    func checkAndUnlockAchievements(
        userData: inout UserData,
        walkDistance: Double,
        walkStartTime: Date
    ) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        
        // 更新统计数据
        userData.totalWalks += 1
        userData.totalDistance += walkDistance
        
        // 更新连续打卡
        updateStreak(userData: &userData)
        
        // 检测各类成就
        newlyUnlocked.append(contentsOf: checkDistanceAchievements(userData: &userData))
        newlyUnlocked.append(contentsOf: checkFrequencyAchievements(userData: &userData))
        newlyUnlocked.append(contentsOf: checkStreakAchievements(userData: &userData))
        newlyUnlocked.append(contentsOf: checkSpecialAchievements(userData: &userData, walkDistance: walkDistance, walkStartTime: walkStartTime))
        
        return newlyUnlocked
    }
    
    // MARK: - 里程类成就检测
    
    private func checkDistanceAchievements(userData: inout UserData) -> [Achievement] {
        var unlocked: [Achievement] = []
        let totalKm = Int(userData.totalDistance)
        
        let distanceAchievements = Achievement.allAchievements.filter { $0.category == .distance }
        
        for achievement in distanceAchievements {
            if !userData.isAchievementUnlocked(achievement.id) && totalKm >= achievement.requirement {
                userData.unlockedAchievements.insert(achievement.id)
                userData.totalBones += achievement.rewardBones
                unlocked.append(achievement)
            }
        }
        
        return unlocked
    }
    
    // MARK: - 频率类成就检测
    
    private func checkFrequencyAchievements(userData: inout UserData) -> [Achievement] {
        var unlocked: [Achievement] = []
        let totalWalks = userData.totalWalks
        
        let frequencyAchievements = Achievement.allAchievements.filter { $0.category == .frequency }
        
        for achievement in frequencyAchievements {
            if !userData.isAchievementUnlocked(achievement.id) && totalWalks >= achievement.requirement {
                userData.unlockedAchievements.insert(achievement.id)
                userData.totalBones += achievement.rewardBones
                unlocked.append(achievement)
            }
        }
        
        return unlocked
    }
    
    // MARK: - 连续打卡类成就检测
    
    private func checkStreakAchievements(userData: inout UserData) -> [Achievement] {
        var unlocked: [Achievement] = []
        let currentStreak = userData.currentStreak
        
        let streakAchievements = Achievement.allAchievements.filter { $0.category == .streak }
        
        for achievement in streakAchievements {
            if !userData.isAchievementUnlocked(achievement.id) && currentStreak >= achievement.requirement {
                userData.unlockedAchievements.insert(achievement.id)
                userData.totalBones += achievement.rewardBones
                unlocked.append(achievement)
            }
        }
        
        return unlocked
    }
    
    // MARK: - 特殊成就检测
    
    private func checkSpecialAchievements(
        userData: inout UserData,
        walkDistance: Double,
        walkStartTime: Date
    ) -> [Achievement] {
        var unlocked: [Achievement] = []
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: walkStartTime)
        
        // 早起的鸟儿 (6点前)
        if hour < 6 {
            let achievementId = "special_early_bird"
            if !userData.isAchievementUnlocked(achievementId),
               let achievement = Achievement.achievement(byId: achievementId) {
                userData.unlockedAchievements.insert(achievementId)
                userData.totalBones += achievement.rewardBones
                unlocked.append(achievement)
            }
        }
        
        // 夜行侠 (22点后)
        if hour >= 22 {
            let achievementId = "special_night_owl"
            if !userData.isAchievementUnlocked(achievementId),
               let achievement = Achievement.achievement(byId: achievementId) {
                userData.unlockedAchievements.insert(achievementId)
                userData.totalBones += achievement.rewardBones
                unlocked.append(achievement)
            }
        }
        
        // 长途跋涉 (单次超过 5 公里)
        if walkDistance >= 5.0 {
            let achievementId = "special_long_walk"
            if !userData.isAchievementUnlocked(achievementId),
               let achievement = Achievement.achievement(byId: achievementId) {
                userData.unlockedAchievements.insert(achievementId)
                userData.totalBones += achievement.rewardBones
                unlocked.append(achievement)
            }
        }
        
        // POI 检测成就（预留接口）
        // special_restaurant_10 - 暂不实现，需要后续接入 POI 服务
        
        return unlocked
    }
    
    // MARK: - 连续打卡逻辑
    
    private func updateStreak(userData: inout UserData) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastStreakDate = userData.lastStreakDate {
            let lastDay = calendar.startOfDay(for: lastStreakDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff == 0 {
                // 今天已经打过卡了，不增加连续天数
                return
            } else if daysDiff == 1 {
                // 连续打卡
                userData.currentStreak += 1
            } else {
                // 断签，重新开始
                userData.currentStreak = 1
            }
        } else {
            // 首次打卡
            userData.currentStreak = 1
        }
        
        // 更新最高记录
        if userData.currentStreak > userData.maxStreak {
            userData.maxStreak = userData.currentStreak
        }
        
        // 记录今天的打卡
        userData.lastStreakDate = today
    }
    
    // MARK: - 进度计算（用于 UI 显示）
    
    /// 获取成就当前进度
    func getProgress(for achievement: Achievement, userData: UserData) -> (current: Int, target: Int) {
        switch achievement.category {
        case .distance:
            return (Int(userData.totalDistance), achievement.requirement)
        case .frequency:
            return (userData.totalWalks, achievement.requirement)
        case .streak:
            return (userData.currentStreak, achievement.requirement)
        case .special:
            // 特殊成就的进度根据具体成就类型判断
            switch achievement.id {
            case "special_early_bird", "special_night_owl", "special_long_walk":
                return (userData.isAchievementUnlocked(achievement.id) ? 1 : 0, 1)
            default:
                return (0, achievement.requirement)
            }
        }
    }
    
    /// 获取成就完成百分比
    func getProgressPercentage(for achievement: Achievement, userData: UserData) -> Double {
        let (current, target) = getProgress(for: achievement, userData: userData)
        guard target > 0 else { return 0 }
        return min(1.0, Double(current) / Double(target))
    }
}
