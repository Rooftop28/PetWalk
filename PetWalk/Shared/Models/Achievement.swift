//
//  Achievement.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import SwiftUI

// MARK: - 成就类别
enum AchievementCategory: String, Codable, CaseIterable {
    case distance     // 里程类
    case frequency    // 频率类
    case streak       // 连续打卡类
    case landmark     // 景点打卡类 (Level 2)
    case performance  // 速度/强度类 (Level 3)
    case environment  // 环境/天气类 (Level 3)
    case context      // 复杂上下文类 (Level 4)
    
    var title: String {
        switch self {
        case .distance: return "里程达人"
        case .frequency: return "坚持不懈"
        case .streak: return "连续打卡"
        case .landmark: return "景点打卡"
        case .performance: return "速度挑战"
        case .environment: return "天气达人"
        case .context: return "特殊成就"
        }
    }
    
    var iconSymbol: String {
        switch self {
        case .distance: return "figure.walk"
        case .frequency: return "repeat"
        case .streak: return "flame.fill"
        case .landmark: return "mappin.and.ellipse"
        case .performance: return "speedometer"
        case .environment: return "cloud.sun.fill"
        case .context: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .distance: return .blue
        case .frequency: return .green
        case .streak: return .orange
        case .landmark: return .red
        case .performance: return .cyan
        case .environment: return .teal
        case .context: return .purple
        }
    }
}

// MARK: - 坐标模型（用于景点打卡）
struct LandmarkCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

// MARK: - 成就数据模型
struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let name: String           // 成就名称
    let description: String    // 描述文案
    let category: AchievementCategory
    let requirement: Int       // 达成条件数值
    let rewardBones: Int       // 奖励骨头币
    let iconSymbol: String     // SF Symbol 图标
    
    // MARK: - 扩展字段（可选）
    // Level 2: 景点打卡
    var targetCoordinate: LandmarkCoordinate? = nil  // 目标坐标
    var targetRadius: Double? = nil                   // 触发半径（米）
    var landmarkCategory: String? = nil               // 景点类别（park, landmark 等）
    
    // Level 3: 速度/强度
    var speedThreshold: Double? = nil                 // 速度阈值 km/h
    var minDuration: Double? = nil                    // 最小时长（秒）
    var maxDistance: Double? = nil                    // 最大距离（公里）
    
    // Level 3: 天气/环境
    var weatherCondition: String? = nil               // 天气条件（rainy, snowy 等）
    var temperatureMin: Double? = nil                 // 最低温度
    var temperatureMax: Double? = nil                 // 最高温度
    
    // MARK: - 静态成就列表
    static let allAchievements: [Achievement] = [
        // ============ 里程类 ============
        Achievement(
            id: "distance_1",
            name: "新手上路",
            description: "累计遛狗 1 公里，迈出第一步！",
            category: .distance,
            requirement: 1,
            rewardBones: 10,
            iconSymbol: "shoeprints.fill"
        ),
        Achievement(
            id: "distance_10",
            name: "小区巡逻员",
            description: "累计遛狗 10 公里，小区的每个角落都留下了你们的足迹。",
            category: .distance,
            requirement: 10,
            rewardBones: 30,
            iconSymbol: "building.2.fill"
        ),
        Achievement(
            id: "distance_50",
            name: "街道探险家",
            description: "累计遛狗 50 公里，附近的街道已经了如指掌。",
            category: .distance,
            requirement: 50,
            rewardBones: 80,
            iconSymbol: "map.fill"
        ),
        Achievement(
            id: "distance_100",
            name: "城市漫步者",
            description: "累计遛狗 100 公里，城市因你们而精彩！",
            category: .distance,
            requirement: 100,
            rewardBones: 150,
            iconSymbol: "building.columns.fill"
        ),
        Achievement(
            id: "distance_500",
            name: "马拉松冠军",
            description: "累计遛狗 500 公里，这已经超过了一场马拉松的距离！",
            category: .distance,
            requirement: 500,
            rewardBones: 500,
            iconSymbol: "trophy.fill"
        ),
        
        // ============ 频率类 ============
        Achievement(
            id: "frequency_1",
            name: "初次遛弯",
            description: "完成第 1 次遛狗，旅程开始了！",
            category: .frequency,
            requirement: 1,
            rewardBones: 5,
            iconSymbol: "1.circle.fill"
        ),
        Achievement(
            id: "frequency_10",
            name: "习惯养成",
            description: "完成第 10 次遛狗，遛狗已成为日常的一部分。",
            category: .frequency,
            requirement: 10,
            rewardBones: 25,
            iconSymbol: "10.circle.fill"
        ),
        Achievement(
            id: "frequency_50",
            name: "遛狗达人",
            description: "完成第 50 次遛狗，你已经是遛狗专家了！",
            category: .frequency,
            requirement: 50,
            rewardBones: 100,
            iconSymbol: "star.circle.fill"
        ),
        Achievement(
            id: "frequency_100",
            name: "百次纪念",
            description: "完成第 100 次遛狗，感谢你对毛孩子的陪伴！",
            category: .frequency,
            requirement: 100,
            rewardBones: 200,
            iconSymbol: "100.circle.fill"
        ),
        
        // ============ 连续打卡类 ============
        Achievement(
            id: "streak_3",
            name: "三日坚持",
            description: "连续 3 天遛狗打卡，保持住！",
            category: .streak,
            requirement: 3,
            rewardBones: 15,
            iconSymbol: "flame"
        ),
        Achievement(
            id: "streak_7",
            name: "一周坚持",
            description: "连续 7 天遛狗打卡，一周的坚持！",
            category: .streak,
            requirement: 7,
            rewardBones: 50,
            iconSymbol: "flame.fill"
        ),
        Achievement(
            id: "streak_30",
            name: "月度坚持",
            description: "连续 30 天遛狗打卡，了不起的毅力！",
            category: .streak,
            requirement: 30,
            rewardBones: 200,
            iconSymbol: "calendar.badge.checkmark"
        ),
        Achievement(
            id: "streak_100",
            name: "百日坚持",
            description: "连续 100 天遛狗打卡，你和毛孩子的羁绊无人能及！",
            category: .streak,
            requirement: 100,
            rewardBones: 500,
            iconSymbol: "medal.fill"
        ),
        
        // ============ 景点打卡类 (Level 2) ============
        Achievement(
            id: "landmark_park_1",
            name: "公园初探",
            description: "在遛狗时到访 1 个公园。",
            category: .landmark,
            requirement: 1,
            rewardBones: 20,
            iconSymbol: "leaf.fill",
            landmarkCategory: "park"
        ),
        Achievement(
            id: "landmark_park_5",
            name: "公园巡逻员",
            description: "累计到访 5 个不同的公园。",
            category: .landmark,
            requirement: 5,
            rewardBones: 80,
            iconSymbol: "tree.fill",
            landmarkCategory: "park"
        ),
        Achievement(
            id: "landmark_all_10",
            name: "地标猎人",
            description: "累计打卡 10 个不同景点。",
            category: .landmark,
            requirement: 10,
            rewardBones: 150,
            iconSymbol: "mappin.circle.fill"
        ),
        Achievement(
            id: "landmark_home_30",
            name: "家门口的守护者",
            description: "在同一地点遛狗 30 次。",
            category: .landmark,
            requirement: 30,
            rewardBones: 100,
            iconSymbol: "house.fill"
        ),
        
        // ============ 速度/强度类 (Level 3) ============
        Achievement(
            id: "performance_speed_fast",
            name: "闪电狗",
            description: "单次遛狗平均配速超过 8 km/h。",
            category: .performance,
            requirement: 8,
            rewardBones: 50,
            iconSymbol: "hare.fill",
            speedThreshold: 8.0
        ),
        Achievement(
            id: "performance_speed_slow",
            name: "养生步伐",
            description: "遛狗时长超过 30 分钟，但移动距离不足 500 米。",
            category: .performance,
            requirement: 1,
            rewardBones: 30,
            iconSymbol: "tortoise.fill",
            minDuration: 1800,  // 30分钟
            maxDistance: 0.5
        ),
        Achievement(
            id: "performance_steady_5",
            name: "稳定输出",
            description: "连续 5 次遛狗配速保持在 4-6 km/h。",
            category: .performance,
            requirement: 5,
            rewardBones: 80,
            iconSymbol: "gauge.medium"
        ),
        Achievement(
            id: "performance_long_walk",
            name: "长途跋涉",
            description: "单次遛狗超过 5 公里。",
            category: .performance,
            requirement: 5,
            rewardBones: 50,
            iconSymbol: "road.lanes"
        ),
        
        // ============ 环境/天气类 (Level 3) ============
        Achievement(
            id: "environment_early_bird",
            name: "早起的鸟儿",
            description: "在早上 6 点前完成一次遛狗。",
            category: .environment,
            requirement: 1,
            rewardBones: 30,
            iconSymbol: "sunrise.fill"
        ),
        Achievement(
            id: "environment_night_owl",
            name: "夜行侠",
            description: "在晚上 10 点后完成一次遛狗。",
            category: .environment,
            requirement: 1,
            rewardBones: 30,
            iconSymbol: "moon.stars.fill"
        ),
        Achievement(
            id: "environment_rainy",
            name: "雨中曲",
            description: "在雨天遛狗超过 10 分钟。",
            category: .environment,
            requirement: 1,
            rewardBones: 50,
            iconSymbol: "cloud.rain.fill",
            minDuration: 600,
            weatherCondition: "rainy"
        ),
        Achievement(
            id: "environment_cold",
            name: "冰雪奇缘",
            description: "在气温低于 0°C 时遛狗。",
            category: .environment,
            requirement: 1,
            rewardBones: 50,
            iconSymbol: "snowflake",
            temperatureMax: 0.0
        ),
        Achievement(
            id: "environment_hot",
            name: "烈日当空",
            description: "在气温超过 35°C 时遛狗。",
            category: .environment,
            requirement: 1,
            rewardBones: 50,
            iconSymbol: "sun.max.fill",
            temperatureMin: 35.0
        ),
        
        // ============ 复杂上下文类 (Level 4) ============
        Achievement(
            id: "context_restaurant_3",
            name: "钢铁意志",
            description: "路过 3 家餐厅而没有停留。",
            category: .context,
            requirement: 3,
            rewardBones: 60,
            iconSymbol: "fork.knife"
        ),
        Achievement(
            id: "context_restaurant_10",
            name: "美食诱惑大师",
            description: "路过 10 家餐厅而没有停留。",
            category: .context,
            requirement: 10,
            rewardBones: 150,
            iconSymbol: "fork.knife.circle.fill"
        ),
        Achievement(
            id: "context_loop_3",
            name: "三过家门而不入",
            description: "绕着起点走了 3 圈但没有结束遛狗。",
            category: .context,
            requirement: 3,
            rewardBones: 80,
            iconSymbol: "arrow.triangle.2.circlepath"
        )
    ]
    
    // MARK: - 辅助方法
    
    /// 按类别分组的成就
    static var achievementsByCategory: [AchievementCategory: [Achievement]] {
        Dictionary(grouping: allAchievements, by: { $0.category })
    }
    
    /// 获取指定 ID 的成就
    static func achievement(byId id: String) -> Achievement? {
        allAchievements.first { $0.id == id }
    }
}
