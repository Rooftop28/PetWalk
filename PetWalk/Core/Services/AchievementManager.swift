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
    
    // 新增字段
    var maxDistanceFromStart: Double = 0  // 离起点最远距离（公里）
    var spinCount: Int = 0                // 原地转圈次数
    var isClosedLoop: Bool = false        // 是否形成闭环
    var returnSpeedRatio: Double = 0      // 返程速度与去程速度的比值
    
    // 社交相关
    var wasBroadcasting: Bool = false     // 是否进行了直播
    var likesReceived: Int = 0            // 收到的赞数
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
    /// - Parameters:
    ///   - userData: 用户数据（会被修改以记录解锁的成就）
    ///   - sessionData: 本次遛狗会话数据
    ///   - updateStats: 是否更新统计数据（totalWalks, totalDistance, streak），默认为 true
    ///                  注意：只应在最终保存时设为 true，预览时设为 false
    func checkAndUnlockAchievements(
        userData: inout UserData,
        sessionData: WalkSessionData,
        updateStats: Bool = true
    ) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        
        // 只有在需要时才更新统计数据（避免重复调用导致数据翻倍）
        if updateStats {
            userData.totalWalks += 1
            userData.totalDistance += sessionData.distance
            
            // 更新连续打卡
            updateStreak(userData: &userData)
        }
        
        // 检测各类成就
        newlyUnlocked.append(contentsOf: checkDistanceAchievements(userData: &userData))
        newlyUnlocked.append(contentsOf: checkFrequencyAchievements(userData: &userData))
        newlyUnlocked.append(contentsOf: checkStreakAchievements(userData: &userData))
        newlyUnlocked.append(contentsOf: checkLandmarkAchievements(userData: &userData))
        newlyUnlocked.append(contentsOf: checkPerformanceAchievements(userData: &userData, sessionData: sessionData))
        newlyUnlocked.append(contentsOf: checkEnvironmentAchievements(userData: &userData, sessionData: sessionData))
        newlyUnlocked.append(contentsOf: checkContextAchievements(userData: &userData, sessionData: sessionData))
        newlyUnlocked.append(contentsOf: checkSocialAchievements(userData: &userData, sessionData: sessionData))
        
        return newlyUnlocked
    }
    
    /// 简化版本（向后兼容）
    func checkAndUnlockAchievements(
        userData: inout UserData,
        walkDistance: Double,
        walkStartTime: Date,
        updateStats: Bool = true
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
        return checkAndUnlockAchievements(userData: &userData, sessionData: sessionData, updateStats: updateStats)
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
        let weekday = calendar.component(.weekday, from: sessionData.startTime) // 1=周日, 7=周六
        
        // 闻鸡起舞 (4:00 - 6:00)
        if hour >= 4 && hour < 6 {
            unlocked.append(contentsOf: tryUnlock("environment_rooster", userData: &userData))
        }
        
        // 暗夜骑士 (23:00 - 02:00)
        if hour >= 23 || hour < 2 {
            unlocked.append(contentsOf: tryUnlock("environment_dark_knight", userData: &userData))
        }
        
        // 早起的鸟儿 (6:00-7:00)
        if hour >= 6 && hour < 7 {
            unlocked.append(contentsOf: tryUnlock("environment_early_bird", userData: &userData))
        }
        
        // 夜行侠 (22点后)
        if hour >= 22 {
            unlocked.append(contentsOf: tryUnlock("environment_night_owl", userData: &userData))
        }
        
        // 周末狂欢检测 (周六或周日)
        if weekday == 1 || weekday == 7 {
            updateWeekendWalkCount()
            if getConsecutiveWeekendCount() >= 4 {
                unlocked.append(contentsOf: tryUnlock("environment_weekend_4", userData: &userData))
            }
        }
        
        // 天气相关成就
        if let weather = sessionData.weather {
            // 风雨无阻 (雨天遛狗超过15分钟)
            if weather.condition == "rainy" && sessionData.duration >= 900 {
                unlocked.append(contentsOf: tryUnlock("environment_rainy", userData: &userData))
            }
            
            // 冰雪奇缘 (气温低于-5度)
            if weather.temperature < -5 {
                unlocked.append(contentsOf: tryUnlock("environment_frozen", userData: &userData))
            }
            
            // 夏日战士 (气温超过35度 + 傍晚时段)
            if weather.temperature > 35 && hour >= 17 && hour <= 20 {
                unlocked.append(contentsOf: tryUnlock("environment_summer", userData: &userData))
            }
        }
        
        return unlocked
    }
    
    // MARK: - 周末遛狗计数
    
    private let weekendWalkKey = "weekendWalkData"
    
    private func updateWeekendWalkCount() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var data = getWeekendWalkData()
        
        // 检查是否是新的一周
        if let lastDate = data.lastWeekendDate {
            let weeksDiff = calendar.dateComponents([.weekOfYear], from: lastDate, to: today).weekOfYear ?? 0
            if weeksDiff > 1 {
                // 超过一周没遛，重置
                data.consecutiveWeekends = 1
            } else if weeksDiff == 1 || (weeksDiff == 0 && !calendar.isDate(lastDate, inSameDayAs: today)) {
                // 连续周末
                data.consecutiveWeekends += 1
            }
            // 同一天不增加计数
        } else {
            data.consecutiveWeekends = 1
        }
        
        data.lastWeekendDate = today
        saveWeekendWalkData(data)
    }
    
    private func getConsecutiveWeekendCount() -> Int {
        return getWeekendWalkData().consecutiveWeekends
    }
    
    private struct WeekendWalkData: Codable {
        var lastWeekendDate: Date?
        var consecutiveWeekends: Int = 0
    }
    
    private func getWeekendWalkData() -> WeekendWalkData {
        guard let data = UserDefaults.standard.data(forKey: weekendWalkKey),
              let decoded = try? JSONDecoder().decode(WeekendWalkData.self, from: data) else {
            return WeekendWalkData()
        }
        return decoded
    }
    
    private func saveWeekendWalkData(_ data: WeekendWalkData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: weekendWalkKey)
        }
    }
    
    // MARK: - 复杂上下文成就检测 (Level 4)
    
    private func checkContextAchievements(
        userData: inout UserData,
        sessionData: WalkSessionData
    ) -> [Achievement] {
        var unlocked: [Achievement] = []
        
        // 减肥特种兵 (路过3家餐厅未停留)
        if sessionData.passedRestaurantCount >= 3 {
            unlocked.append(contentsOf: tryUnlock("context_iron_will", userData: &userData))
        }
        
        // 美食诱惑大师 (路过10家餐厅未停留)
        if sessionData.passedRestaurantCount >= 10 {
            unlocked.append(contentsOf: tryUnlock("context_restaurant_10", userData: &userData))
        }
        
        // 三过家门而不入 (绕起点3圈)
        if sessionData.homeLoopCount >= 3 {
            unlocked.append(contentsOf: tryUnlock("context_wanderer", userData: &userData))
        }
        
        // 鬼打墙 (原地转圈超过5次)
        if sessionData.spinCount >= 5 {
            unlocked.append(contentsOf: tryUnlock("context_dizzy", userData: &userData))
        }
        
        // 完美的圆 (形成闭环)
        if sessionData.isClosedLoop {
            unlocked.append(contentsOf: tryUnlock("context_artist", userData: &userData))
        }
        
        // 我想回家 (返程速度是去程的2倍以上)
        if sessionData.returnSpeedRatio >= 2.0 {
            unlocked.append(contentsOf: tryUnlock("context_homing", userData: &userData))
        }
        
        // 拓荒者 (离家超过5公里)
        if sessionData.maxDistanceFromStart >= 5.0 {
            unlocked.append(contentsOf: tryUnlock("context_explorer", userData: &userData))
        }
        
        // 嗅探专家 (时长>30分钟，距离<500米)
        if sessionData.duration >= 1800 && sessionData.distance < 0.5 {
            unlocked.append(contentsOf: tryUnlock("context_sniffer", userData: &userData))
        }
        
        // 长情陪伴 (累计时长100小时)
        updateTotalWalkDuration(sessionData.duration)
        if getTotalWalkDurationHours() >= 100 {
            unlocked.append(contentsOf: tryUnlock("context_companion_100", userData: &userData))
        }
        
        // 地头蛇 (50条不同轨迹) - 需要轨迹管理器支持
        // 暂时跳过，需要单独的轨迹去重逻辑
        
        return unlocked
    }
    
    // MARK: - 社交成就检测 (Level 5)
    
    private func checkSocialAchievements(
        userData: inout UserData,
        sessionData: WalkSessionData
    ) -> [Achievement] {
        var unlocked: [Achievement] = []
        
        // 只有开启直播才算
        if sessionData.wasBroadcasting {
            userData.totalLiveBroadcasts += 1
            userData.totalLikesReceived += sessionData.likesReceived
        }
        
        // 金牌保姆 (直播10次)
        if userData.totalLiveBroadcasts >= 10 {
            unlocked.append(contentsOf: tryUnlock("social_nanny_10", userData: &userData))
        }
        
        // 使命必达 (收到5个赞)
        if userData.totalLikesReceived >= 5 {
            unlocked.append(contentsOf: tryUnlock("social_trustworthy", userData: &userData))
        }
        
        return unlocked
    }
    
    /// 观众端成就检测 (由于不在常规遛狗流程，需单独调用)
    func checkWatcherAchievements(userData: inout UserData) -> [Achievement] {
        var unlocked: [Achievement] = []
        
        // 云遛狗 (观看30分钟)
        if userData.totalLiveWatchingDuration >= 1800 {
            unlocked.append(contentsOf: tryUnlock("social_cloud_walker", userData: &userData))
        }
        
        return unlocked
    }
    
    // MARK: - 累计遛狗时长
    
    private let totalDurationKey = "totalWalkDuration"
    
    private func updateTotalWalkDuration(_ duration: TimeInterval) {
        let current = UserDefaults.standard.double(forKey: totalDurationKey)
        UserDefaults.standard.set(current + duration, forKey: totalDurationKey)
    }
    
    private func getTotalWalkDurationHours() -> Double {
        return UserDefaults.standard.double(forKey: totalDurationKey) / 3600.0
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
            
        case .social:
            switch achievement.id {
            case "social_nanny_10":
                return (userData.totalLiveBroadcasts, achievement.requirement)
            case "social_trustworthy":
                return (userData.totalLikesReceived, achievement.requirement)
            case "social_cloud_walker":
                return (Int(userData.totalLiveWatchingDuration), achievement.requirement)
            default:
                return (userData.isAchievementUnlocked(achievement.id) ? 1 : 0, 1)
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
