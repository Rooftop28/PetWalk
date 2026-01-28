//
//  AchievementManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import CoreLocation

// MARK: - 遛狗会话数据（用于成就检测）
struct WalkSessionData {
    let distance: Double           // 公里
    let duration: TimeInterval     // 秒
    let startTime: Date
    let averageSpeed: Double       // km/h
    let startLocation: CLLocation?
    let weather: WeatherInfo?      // 天气信息（可选）
    let passedRestaurantCount: Int // 路过餐厅数量（Level 4）
    let homeLoopCount: Int         // 绕起点圈数（Level 4）
}

// MARK: - 天气信息
struct WeatherInfo {
    let condition: String          // sunny, cloudy, rainy, snowy, foggy
    let temperature: Double        // 摄氏度
}

@MainActor
class AchievementManager {
    static let shared = AchievementManager()
    
    // 稳定配速计数器
    private let steadySpeedKey = "steadySpeedCount"
    
    private init() {}
    
    // MARK: - 成就检测（遛狗结束后调用）
    
    /// 检测并解锁成就，返回新解锁的成就列表（扩展版）
    func checkAndUnlockAchievements(
        userData: inout UserData,
        sessionData: WalkSessionData
    ) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        
        // 更新统计数据
        userData.totalWalks += 1
        userData.totalDistance += sessionData.distance
        
        // 更新连续打卡
        updateStreak(userData: &userData)
        
        // 检测各类成就
        newlyUnlocked.append(contentsOf: checkDistanceAchievements(userData: &userData))
        newlyUnlocked.append(contentsOf: checkFrequencyAchievements(userData: &userData))
        newlyUnlocked.append(contentsOf: checkStreakAchievements(userData: &userData))
        newlyUnlocked.append(contentsOf: checkLandmarkAchievements(userData: &userData))
        newlyUnlocked.append(contentsOf: checkPerformanceAchievements(userData: &userData, sessionData: sessionData))
        newlyUnlocked.append(contentsOf: checkEnvironmentAchievements(userData: &userData, sessionData: sessionData))
        newlyUnlocked.append(contentsOf: checkContextAchievements(userData: &userData, sessionData: sessionData))
        
        return newlyUnlocked
    }
    
    /// 简化版本（向后兼容）
    func checkAndUnlockAchievements(
        userData: inout UserData,
        walkDistance: Double,
        walkStartTime: Date
    ) -> [Achievement] {
        let sessionData = WalkSessionData(
            distance: walkDistance,
            duration: 0,
            startTime: walkStartTime,
            averageSpeed: 0,
            startLocation: nil,
            weather: nil,
            passedRestaurantCount: 0,
            homeLoopCount: 0
        )
        return checkAndUnlockAchievements(userData: &userData, sessionData: sessionData)
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
    
    // MARK: - 景点打卡成就检测 (Level 2)
    
    private func checkLandmarkAchievements(userData: inout UserData) -> [Achievement] {
        var unlocked: [Achievement] = []
        
        let landmarkManager = LandmarkManager.shared
        
        // 公园初探 (1个公园)
        if landmarkManager.visitedParksCount >= 1 {
            unlocked.append(contentsOf: tryUnlock("landmark_park_1", userData: &userData))
        }
        
        // 公园巡逻员 (5个公园)
        if landmarkManager.visitedParksCount >= 5 {
            unlocked.append(contentsOf: tryUnlock("landmark_park_5", userData: &userData))
        }
        
        // 地标猎人 (10个景点)
        if landmarkManager.totalVisitedCount >= 10 {
            unlocked.append(contentsOf: tryUnlock("landmark_all_10", userData: &userData))
        }
        
        // 家门口的守护者 (同一地点30次)
        if landmarkManager.getMaxLocationVisitCount() >= 30 {
            unlocked.append(contentsOf: tryUnlock("landmark_home_30", userData: &userData))
        }
        
        return unlocked
    }
    
    // MARK: - 速度/强度成就检测 (Level 3)
    
    private func checkPerformanceAchievements(
        userData: inout UserData,
        sessionData: WalkSessionData
    ) -> [Achievement] {
        var unlocked: [Achievement] = []
        
        // 闪电狗 (配速超过 8km/h)
        if sessionData.averageSpeed >= 8.0 {
            unlocked.append(contentsOf: tryUnlock("performance_speed_fast", userData: &userData))
        }
        
        // 养生步伐 (时长 > 30分钟，距离 < 500米)
        if sessionData.duration >= 1800 && sessionData.distance < 0.5 {
            unlocked.append(contentsOf: tryUnlock("performance_speed_slow", userData: &userData))
        }
        
        // 长途跋涉 (单次超过 5km)
        if sessionData.distance >= 5.0 {
            unlocked.append(contentsOf: tryUnlock("performance_long_walk", userData: &userData))
        }
        
        // 稳定输出 (连续5次配速在 4-6 km/h)
        updateSteadySpeedCount(sessionData.averageSpeed)
        if getSteadySpeedCount() >= 5 {
            unlocked.append(contentsOf: tryUnlock("performance_steady_5", userData: &userData))
        }
        
        return unlocked
    }
    
    // MARK: - 环境/天气成就检测 (Level 3)
    
    private func checkEnvironmentAchievements(
        userData: inout UserData,
        sessionData: WalkSessionData
    ) -> [Achievement] {
        var unlocked: [Achievement] = []
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: sessionData.startTime)
        
        // 早起的鸟儿 (6点前)
        if hour < 6 {
            unlocked.append(contentsOf: tryUnlock("environment_early_bird", userData: &userData))
        }
        
        // 夜行侠 (22点后)
        if hour >= 22 {
            unlocked.append(contentsOf: tryUnlock("environment_night_owl", userData: &userData))
        }
        
        // 天气相关成就
        if let weather = sessionData.weather {
            // 雨中曲 (雨天遛狗超过10分钟)
            if weather.condition == "rainy" && sessionData.duration >= 600 {
                unlocked.append(contentsOf: tryUnlock("environment_rainy", userData: &userData))
            }
            
            // 冰雪奇缘 (气温低于0度)
            if weather.temperature < 0 {
                unlocked.append(contentsOf: tryUnlock("environment_cold", userData: &userData))
            }
            
            // 烈日当空 (气温超过35度)
            if weather.temperature > 35 {
                unlocked.append(contentsOf: tryUnlock("environment_hot", userData: &userData))
            }
        }
        
        return unlocked
    }
    
    // MARK: - 复杂上下文成就检测 (Level 4)
    
    private func checkContextAchievements(
        userData: inout UserData,
        sessionData: WalkSessionData
    ) -> [Achievement] {
        var unlocked: [Achievement] = []
        
        // 钢铁意志 (路过3家餐厅未停留)
        if sessionData.passedRestaurantCount >= 3 {
            unlocked.append(contentsOf: tryUnlock("context_restaurant_3", userData: &userData))
        }
        
        // 美食诱惑大师 (路过10家餐厅未停留)
        if sessionData.passedRestaurantCount >= 10 {
            unlocked.append(contentsOf: tryUnlock("context_restaurant_10", userData: &userData))
        }
        
        // 三过家门而不入 (绕起点3圈)
        if sessionData.homeLoopCount >= 3 {
            unlocked.append(contentsOf: tryUnlock("context_loop_3", userData: &userData))
        }
        
        return unlocked
    }
    
    // MARK: - 辅助方法：尝试解锁成就
    
    private func tryUnlock(_ achievementId: String, userData: inout UserData) -> [Achievement] {
        guard !userData.isAchievementUnlocked(achievementId),
              let achievement = Achievement.achievement(byId: achievementId) else {
            return []
        }
        
        userData.unlockedAchievements.insert(achievementId)
        userData.totalBones += achievement.rewardBones
        return [achievement]
    }
    
    // MARK: - 稳定配速计数
    
    private func updateSteadySpeedCount(_ speed: Double) {
        var count = getSteadySpeedCount()
        
        if speed >= 4.0 && speed <= 6.0 {
            count += 1
        } else {
            count = 0  // 速度不在范围内，重置计数
        }
        
        UserDefaults.standard.set(count, forKey: steadySpeedKey)
    }
    
    private func getSteadySpeedCount() -> Int {
        return UserDefaults.standard.integer(forKey: steadySpeedKey)
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
            
        case .landmark:
            // 景点打卡成就
            let landmarkManager = LandmarkManager.shared
            switch achievement.id {
            case "landmark_park_1", "landmark_park_5":
                return (landmarkManager.visitedParksCount, achievement.requirement)
            case "landmark_all_10":
                return (landmarkManager.totalVisitedCount, achievement.requirement)
            case "landmark_home_30":
                return (landmarkManager.getMaxLocationVisitCount(), achievement.requirement)
            default:
                return (userData.isAchievementUnlocked(achievement.id) ? 1 : 0, 1)
            }
            
        case .performance:
            // 速度/强度成就（大多是一次性的）
            switch achievement.id {
            case "performance_steady_5":
                return (getSteadySpeedCount(), achievement.requirement)
            default:
                return (userData.isAchievementUnlocked(achievement.id) ? 1 : 0, 1)
            }
            
        case .environment:
            // 环境/天气成就（一次性）
            return (userData.isAchievementUnlocked(achievement.id) ? 1 : 0, 1)
            
        case .context:
            // 复杂上下文成就（一次性）
            return (userData.isAchievementUnlocked(achievement.id) ? 1 : 0, 1)
        }
    }
    
    /// 获取成就完成百分比
    func getProgressPercentage(for achievement: Achievement, userData: UserData) -> Double {
        let (current, target) = getProgress(for: achievement, userData: userData)
        guard target > 0 else { return 0 }
        return min(1.0, Double(current) / Double(target))
    }
}
