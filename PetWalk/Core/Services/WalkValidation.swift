//
//  WalkValidation.swift
//  PetWalk
//
//  遛狗分级验证系统
//  Tier 1 基础记录层：≥5分钟 + ≥200米 → 计入日历和历史列表
//  Tier 2 有效运动层：≥10分钟 + ≥500米 → 发放骨头币 + 计算成就进度
//  Tier 3 成就挑战层：特殊成就有额外门槛（恶劣天气≥15分钟、POI停留≥3分钟等）
//

import Foundation

enum WalkTier: Int, Comparable {
    case invalid = 0
    case basicRecord = 1     // 基础记录层
    case activeExercise = 2  // 有效运动层
    
    static func < (lhs: WalkTier, rhs: WalkTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct WalkValidation {
    
    // MARK: - Tier 1 基础记录层门槛
    static let basicMinDurationSeconds: TimeInterval = 5 * 60   // 5 分钟
    static let basicMinDistanceKm: Double = 0.2                 // 200 米
    
    // MARK: - Tier 2 有效运动层门槛
    static let activeMinDurationSeconds: TimeInterval = 10 * 60 // 10 分钟
    static let activeMinDistanceKm: Double = 0.5                // 500 米
    
    // MARK: - Tier 3 成就挑战层门槛
    static let weatherAchievementMinDuration: TimeInterval = 15 * 60 // 恶劣天气成就：15 分钟
    static let poiDwellMinDuration: TimeInterval = 3 * 60            // 景点打卡停留：3 分钟
    
    /// 判定本次遛狗的最高达标层级
    static func evaluateTier(for session: WalkSessionData) -> WalkTier {
        let dur = session.duration
        let dist = session.distance
        
        if dur >= activeMinDurationSeconds && dist >= activeMinDistanceKm {
            return .activeExercise
        }
        if dur >= basicMinDurationSeconds && dist >= basicMinDistanceKm {
            return .basicRecord
        }
        return .invalid
    }
    
    /// 是否达到基础记录层（可以保存到历史和日历）
    static func meetsBasicRecord(_ session: WalkSessionData) -> Bool {
        evaluateTier(for: session) >= .basicRecord
    }
    
    /// 是否达到有效运动层（可以获得骨头币和累积成就进度）
    static func meetsActiveExercise(_ session: WalkSessionData) -> Bool {
        evaluateTier(for: session) >= .activeExercise
    }
    
    // MARK: - Tier 3 特殊成就门槛
    
    /// 恶劣天气成就是否满足门槛（雨/雪/极端温度 + ≥15分钟）
    static func meetsWeatherAchievementThreshold(_ session: WalkSessionData) -> Bool {
        session.duration >= weatherAchievementMinDuration
    }
    
    /// 景点打卡是否满足停留时长门槛（≥3分钟）
    static func meetsLandmarkDwellThreshold(dwellSeconds: TimeInterval) -> Bool {
        dwellSeconds >= poiDwellMinDuration
    }
    
    // MARK: - 用户提示文案
    
    static func shortfallMessage(for session: WalkSessionData) -> String {
        let durMin = Int(session.duration / 60)
        let distM = Int(session.distance * 1000)
        
        let tier = evaluateTier(for: session)
        
        if tier == .invalid {
            var needs: [String] = []
            if session.duration < basicMinDurationSeconds {
                needs.append("至少遛 \(Int(basicMinDurationSeconds / 60)) 分钟")
            }
            if session.distance < basicMinDistanceKm {
                needs.append("走满 \(Int(basicMinDistanceKm * 1000)) 米")
            }
            return "本次遛狗（\(durMin)分钟/\(distM)米）不满足记录条件，需要\(needs.joined(separator: "且"))才会保存记录。"
        }
        
        if tier == .basicRecord {
            var needs: [String] = []
            if session.duration < activeMinDurationSeconds {
                needs.append("遛满 \(Int(activeMinDurationSeconds / 60)) 分钟")
            }
            if session.distance < activeMinDistanceKm {
                needs.append("走满 \(Int(activeMinDistanceKm * 1000)) 米")
            }
            return "本次遛狗已记录，但未达到有效运动标准（\(needs.joined(separator: "且"))），不发放骨头币和成就进度。"
        }
        
        return ""
    }
}
