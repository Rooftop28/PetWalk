//
//  WalkingService.swift
//  PetWalk
//
//  AI Agent API 层 — 将遛狗记录、日记生成等逻辑抽离为可序列化接口
//

import Foundation
import CoreLocation

// MARK: - API 请求 / 响应模型 (JSON Codable)

/// 开始遛狗的响应
struct StartWalkResponse: Codable {
    let success: Bool
    let walkId: String
    let startTime: String
    let aiSummary: String
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case walkId = "walk_id"
        case startTime = "start_time"
        case aiSummary = "ai_summary"
        case deepLinkURL = "deep_link_url"
    }
}

/// 结束遛狗的请求参数
struct StopWalkRequest: Codable {
    let mood: String?
    
    init(mood: String? = nil) {
        self.mood = mood
    }
}

/// 结束遛狗的响应
struct StopWalkResponse: Codable {
    let success: Bool
    let walkId: String
    let distance: Double
    let durationSeconds: Double
    let averageSpeed: Double
    let bonesEarned: Int
    let newAchievements: [AchievementResponse]
    let aiSummary: String
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case walkId = "walk_id"
        case distance
        case durationSeconds = "duration_seconds"
        case averageSpeed = "average_speed"
        case bonesEarned = "bones_earned"
        case newAchievements = "new_achievements"
        case aiSummary = "ai_summary"
        case deepLinkURL = "deep_link_url"
    }
}

/// 成就返回模型
struct AchievementResponse: Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let rarity: String
    let rewardBones: Int
    let isUnlocked: Bool
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, rarity
        case rewardBones = "reward_bones"
        case isUnlocked = "is_unlocked"
        case deepLinkURL = "deep_link_url"
    }
}

/// 遛狗状态查询响应
struct WalkStatusResponse: Codable {
    let isWalking: Bool
    let distance: Double?
    let durationSeconds: Double?
    let currentSpeed: Double?
    let aiSummary: String
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case isWalking = "is_walking"
        case distance
        case durationSeconds = "duration_seconds"
        case currentSpeed = "current_speed"
        case aiSummary = "ai_summary"
        case deepLinkURL = "deep_link_url"
    }
}

/// 遛狗历史记录响应
struct WalkHistoryResponse: Codable {
    let records: [WalkRecordResponse]
    let totalCount: Int
    let aiSummary: String
    
    enum CodingKeys: String, CodingKey {
        case records
        case totalCount = "total_count"
        case aiSummary = "ai_summary"
    }
}

/// 单条遛狗记录响应
struct WalkRecordResponse: Codable {
    let id: String
    let date: String
    let time: String
    let distance: Double
    let durationMinutes: Int
    let mood: String
    let bonesEarned: Int?
    let hasPhoto: Bool
    let hasDiary: Bool
    let diaryContent: String?
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case id, date, time, distance, mood
        case durationMinutes = "duration_minutes"
        case bonesEarned = "bones_earned"
        case hasPhoto = "has_photo"
        case hasDiary = "has_diary"
        case diaryContent = "diary_content"
        case deepLinkURL = "deep_link_url"
    }
}

/// 今日统计响应
struct TodayStatsResponse: Codable {
    let totalDistance: Double
    let walkCount: Int
    let totalDurationMinutes: Int
    let dailyGoalKm: Double
    let goalProgress: Double
    let aiSummary: String
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case totalDistance = "total_distance"
        case walkCount = "walk_count"
        case totalDurationMinutes = "total_duration_minutes"
        case dailyGoalKm = "daily_goal_km"
        case goalProgress = "goal_progress"
        case aiSummary = "ai_summary"
        case deepLinkURL = "deep_link_url"
    }
}

// MARK: - WalkingService

@MainActor
class WalkingService {
    static let shared = WalkingService()
    
    private let walkManager = WalkSessionManager.shared
    private let dataManager = DataManager.shared
    private let gameSystem = GameSystem.shared
    private let achievementManager = AchievementManager.shared
    
    private var currentWalkId: String?
    
    private init() {}
    
    // MARK: - 开始遛狗
    
    /// 开始一次遛狗会话
    /// - Returns: `StartWalkResponse` 包含 walk_id 和 AI 总结
    func startWalk() -> StartWalkResponse {
        let walkId = UUID().uuidString
        currentWalkId = walkId
        
        walkManager.startWalk()
        
        let formatter = ISO8601DateFormatter()
        let petName = dataManager.userData.petName
        
        return StartWalkResponse(
            success: true,
            walkId: walkId,
            startTime: formatter.string(from: Date()),
            aiSummary: "已开始带\(petName)遛弯，GPS 追踪已启动，祝你们散步愉快！",
            deepLinkURL: "petwalk://walk/active"
        )
    }
    
    // MARK: - 结束遛狗
    
    /// 结束当前遛狗会话，计算奖励并保存记录
    /// - Parameter request: 可选的心情参数
    /// - Returns: `StopWalkResponse` 包含完整遛狗数据和奖励
    func stopWalk(request: StopWalkRequest = StopWalkRequest()) -> StopWalkResponse {
        let sessionData = walkManager.stopWalk()
        let walkId = currentWalkId ?? UUID().uuidString
        currentWalkId = nil
        
        let mood = request.mood ?? "happy"
        let bones = gameSystem.calculateBones(distanceKm: sessionData.distance)
        
        // 检测成就
        var userData = dataManager.userData
        let newAchievements = achievementManager.checkAndUnlockAchievements(
            userData: &userData,
            sessionData: sessionData,
            updateStats: true
        )
        
        // 发放奖励
        let totalBones = bones + newAchievements.reduce(0) { $0 + $1.rewardBones }
        userData.totalBones += totalBones
        userData.lastWalkDate = Date()
        dataManager.updateUserData(userData)
        
        // 保存遛狗记录
        let now = Date()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let record = WalkRecord(
            day: calendar.component(.day, from: now),
            date: dateFormatter.string(from: now),
            time: timeFormatter.string(from: now),
            distance: sessionData.distance,
            duration: Int(sessionData.duration / 60),
            mood: mood,
            imageName: nil,
            timestamp: now,
            route: walkManager.locationService.routeCoordinates.map {
                RoutePoint(lat: $0.latitude, lon: $0.longitude)
            },
            itemsFound: nil,
            bonesEarned: totalBones,
            isCloudWalk: false,
            aiDiary: nil,
            aiDiaryGeneratedAt: nil
        )
        dataManager.addRecord(record)
        
        // 构建成就响应
        let achievementResponses = newAchievements.map { a in
            AchievementResponse(
                id: a.id,
                name: a.name,
                description: a.description,
                category: a.category.title,
                rarity: a.rarity.displayName,
                rewardBones: a.rewardBones,
                isUnlocked: true,
                deepLinkURL: "petwalk://achievement/\(a.id)"
            )
        }
        
        let petName = dataManager.userData.petName
        let distStr = String(format: "%.2f", sessionData.distance)
        let durMin = Int(sessionData.duration / 60)
        var summary = "和\(petName)完成了\(distStr)公里、\(durMin)分钟的遛弯"
        if !newAchievements.isEmpty {
            let names = newAchievements.map { "「\($0.name)」" }.joined(separator: "、")
            summary += "，还解锁了\(names)成就！"
        } else {
            summary += "，获得了\(totalBones)个骨头币。"
        }
        
        return StopWalkResponse(
            success: true,
            walkId: walkId,
            distance: sessionData.distance,
            durationSeconds: sessionData.duration,
            averageSpeed: sessionData.averageSpeed,
            bonesEarned: totalBones,
            newAchievements: achievementResponses,
            aiSummary: summary,
            deepLinkURL: "petwalk://walk/summary/\(record.id.uuidString)"
        )
    }
    
    // MARK: - 查询遛狗状态
    
    /// 获取当前遛狗状态
    /// - Returns: `WalkStatusResponse`
    func getWalkStatus() -> WalkStatusResponse {
        let petName = dataManager.userData.petName
        
        if walkManager.isWalking {
            let distStr = String(format: "%.2f", walkManager.distance)
            let durMin = Int(walkManager.duration / 60)
            return WalkStatusResponse(
                isWalking: true,
                distance: walkManager.distance,
                durationSeconds: walkManager.duration,
                currentSpeed: walkManager.currentSpeed,
                aiSummary: "\(petName)正在散步中，已走\(distStr)公里、\(durMin)分钟。",
                deepLinkURL: "petwalk://walk/active"
            )
        } else {
            return WalkStatusResponse(
                isWalking: false,
                distance: nil,
                durationSeconds: nil,
                currentSpeed: nil,
                aiSummary: "\(petName)当前没有在遛弯，随时可以出发！",
                deepLinkURL: "petwalk://home"
            )
        }
    }
    
    // MARK: - 今日统计
    
    /// 获取今日遛狗统计
    /// - Returns: `TodayStatsResponse`
    func getTodayStats() -> TodayStatsResponse {
        let calendar = Calendar.current
        let today = Date()
        let todayDay = calendar.component(.day, from: today)
        let dailyGoal = 3.0
        
        let todayRecords = dataManager.records.filter { $0.day == todayDay }
        let totalDistance = todayRecords.reduce(0.0) { $0 + $1.distance }
        let totalDuration = todayRecords.reduce(0) { $0 + $1.duration }
        let progress = min(1.0, totalDistance / dailyGoal)
        
        let petName = dataManager.userData.petName
        let distStr = String(format: "%.1f", totalDistance)
        let pctStr = String(format: "%.0f", progress * 100)
        
        var summary: String
        if todayRecords.isEmpty {
            summary = "今天还没有带\(petName)出门，快出发吧！"
        } else if progress >= 1.0 {
            summary = "太棒了！今天带\(petName)走了\(distStr)公里，已经完成每日目标！"
        } else {
            summary = "今天带\(petName)走了\(distStr)公里，完成目标的\(pctStr)%。"
        }
        
        return TodayStatsResponse(
            totalDistance: totalDistance,
            walkCount: todayRecords.count,
            totalDurationMinutes: totalDuration,
            dailyGoalKm: dailyGoal,
            goalProgress: progress,
            aiSummary: summary,
            deepLinkURL: "petwalk://history/today"
        )
    }
    
    // MARK: - 遛狗历史
    
    /// 获取遛狗历史记录
    /// - Parameter limit: 返回条数（默认 20）
    /// - Returns: `WalkHistoryResponse`
    func getWalkHistory(limit: Int = 20) -> WalkHistoryResponse {
        let records = Array(dataManager.records.prefix(limit))
        let petName = dataManager.userData.petName
        let total = dataManager.records.count
        let totalDist = String(format: "%.1f", dataManager.userData.totalDistance)
        
        let responses = records.map { r in
            WalkRecordResponse(
                id: r.id.uuidString,
                date: r.date,
                time: r.time,
                distance: r.distance,
                durationMinutes: r.duration,
                mood: r.mood,
                bonesEarned: r.bonesEarned,
                hasPhoto: r.imageName != nil,
                hasDiary: r.aiDiary != nil,
                diaryContent: r.aiDiary,
                deepLinkURL: "petwalk://history/\(r.id.uuidString)"
            )
        }
        
        return WalkHistoryResponse(
            records: responses,
            totalCount: total,
            aiSummary: "\(petName)一共有\(total)条遛弯记录，累计走了\(totalDist)公里。"
        )
    }
    
    // MARK: - JSON 序列化辅助
    
    /// 将任意 Codable 对象编码为 JSON 字符串
    static func toJSON<T: Codable>(_ value: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// 从 JSON 字符串解码
    static func fromJSON<T: Codable>(_ jsonString: String, as type: T.Type) -> T? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
