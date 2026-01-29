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
    case social       // 社交互动类 (Level 5)
    
    var title: String {
        switch self {
        case .distance: return "里程达人"
        case .frequency: return "坚持不懈"
        case .streak: return "连续打卡"
        case .landmark: return "景点打卡"
        case .performance: return "速度挑战"
        case .environment: return "天气达人"
        case .context: return "特殊成就"
        case .social: return "社交达人"
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
        case .social: return "person.2.fill"
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
        case .social: return .pink
        }
    }
}

// MARK: - 坐标模型（用于景点打卡）
struct LandmarkCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

// MARK: - 成就稀有度
enum AchievementRarity: String, Codable {
    case common     // 普通 (>50%)
    case rare       // 稀有 (10-50%)
    case epic       // 史诗 (1-10%)
    case legendary  // 传说 (<1%)
    
    var displayName: String {
        switch self {
        case .common: return "普通"
        case .rare: return "稀有"
        case .epic: return "史诗"
        case .legendary: return "传说"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .yellow
        }
    }
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
    
    // MARK: - 新增字段
    var isSecret: Bool = false                        // 是否为隐藏成就
    var rarity: AchievementRarity = .common           // 稀有度（可动态计算）
    var gameCenterID: String? = nil                   // Game Center 成就 ID
    
    // MARK: - 扩展字段（可选）
    // Level 2: 景点打卡
    var targetCoordinate: LandmarkCoordinate? = nil  // 目标坐标
    var targetRadius: Double? = nil                   // 触发半径（米）
    var landmarkCategory: String? = nil               // 景点类别（park, landmark 等）
    
    // Level 3: 速度/强度
    var speedThreshold: Double? = nil                 // 速度阈值 km/h
    var minDuration: Double? = nil                    // 最小时长（秒）
    var maxDistance: Double? = nil                    // 最大距离（公里）
    var minDistance: Double? = nil                    // 最小距离（公里）
    
    // Level 3: 天气/环境
    var weatherCondition: String? = nil               // 天气条件（rainy, snowy 等）
    var temperatureMin: Double? = nil                 // 最低温度
    var temperatureMax: Double? = nil                 // 最高温度
    var timeRangeStart: Int? = nil                    // 时间范围开始（小时）
    var timeRangeEnd: Int? = nil                      // 时间范围结束（小时）
    
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
            id: "distance_42",
            name: "全马选手",
            description: "累计遛狗 42.195 公里，不知不觉，你和狗狗跑完了一场马拉松！",
            category: .distance,
            requirement: 42,
            rewardBones: 150,
            iconSymbol: "figure.run"
        ),
        Achievement(
            id: "distance_500",
            name: "日行千里",
            description: "累计遛狗 500 公里，距离回家还有二万四千五百里。",
            category: .distance,
            requirement: 500,
            rewardBones: 500,
            iconSymbol: "trophy.fill"
        ),
        Achievement(
            id: "distance_1000",
            name: "万里长征",
            description: "累计遛狗 1000 公里，这是一段史诗级的旅程！",
            category: .distance,
            requirement: 1000,
            rewardBones: 1000,
            iconSymbol: "crown.fill",
            isSecret: true,
            rarity: .legendary,
            gameCenterID: "petwalk.achievement.distance_1000"
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
            iconSymbol: "medal.fill",
            isSecret: true,
            rarity: .epic
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
            description: "单次遛狗平均配速超过 8 km/h。只要我跑得够快，寂寞就追不上我。",
            category: .performance,
            requirement: 8,
            rewardBones: 50,
            iconSymbol: "hare.fill",
            isSecret: true,
            rarity: .rare,
            speedThreshold: 8.0
        ),
        Achievement(
            id: "performance_speed_slow",
            name: "养生步伐",
            description: "遛狗时长超过 30 分钟，但移动距离不足 500 米。每一根电线杆都值得仔细品味。",
            category: .performance,
            requirement: 1,
            rewardBones: 30,
            iconSymbol: "tortoise.fill",
            isSecret: true,
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
            id: "environment_rooster",
            name: "闻鸡起舞",
            description: "在凌晨 4:00 - 6:00 之间完成一次遛狗。你看过凌晨四点的城市吗？你的狗看过。",
            category: .environment,
            requirement: 1,
            rewardBones: 50,
            iconSymbol: "sunrise.fill",
            isSecret: true,
            rarity: .rare,
            timeRangeStart: 4,
            timeRangeEnd: 6
        ),
        Achievement(
            id: "environment_dark_knight",
            name: "暗夜骑士",
            description: "在深夜 23:00 - 02:00 之间遛狗。他是守护这座城市的沉默卫士。",
            category: .environment,
            requirement: 1,
            rewardBones: 50,
            iconSymbol: "moon.stars.fill",
            isSecret: true,
            rarity: .rare,
            timeRangeStart: 23,
            timeRangeEnd: 2
        ),
        Achievement(
            id: "environment_early_bird",
            name: "早起的鸟儿",
            description: "在早上 6 点前完成一次遛狗。",
            category: .environment,
            requirement: 1,
            rewardBones: 30,
            iconSymbol: "sun.horizon.fill"
        ),
        Achievement(
            id: "environment_night_owl",
            name: "夜行侠",
            description: "在晚上 10 点后完成一次遛狗。",
            category: .environment,
            requirement: 1,
            rewardBones: 30,
            iconSymbol: "moon.fill"
        ),
        Achievement(
            id: "environment_rainy",
            name: "风雨无阻",
            description: "在雨天遛狗超过 15 分钟。落汤鸡，落汤狗，但心情是湿润的。",
            category: .environment,
            requirement: 1,
            rewardBones: 60,
            iconSymbol: "cloud.rain.fill",
            isSecret: true,
            rarity: .rare,
            minDuration: 900,
            weatherCondition: "rainy"
        ),
        Achievement(
            id: "environment_frozen",
            name: "冰雪奇缘",
            description: "在气温低于 -5°C 时遛狗。寒冷困不住一颗想出去撒野的心。",
            category: .environment,
            requirement: 1,
            rewardBones: 80,
            iconSymbol: "snowflake",
            isSecret: true,
            rarity: .epic,
            temperatureMax: -5.0
        ),
        Achievement(
            id: "environment_summer",
            name: "夏日战士",
            description: "在气温超过 35°C 的傍晚出门遛狗。",
            category: .environment,
            requirement: 1,
            rewardBones: 60,
            iconSymbol: "sun.max.fill",
            isSecret: true,
            rarity: .rare,
            temperatureMin: 35.0,
            timeRangeStart: 17,
            timeRangeEnd: 20
        ),
        Achievement(
            id: "environment_weekend_4",
            name: "周末狂欢",
            description: "连续 4 个周六和周日都出门遛狗。",
            category: .environment,
            requirement: 4,
            rewardBones: 100,
            iconSymbol: "calendar.badge.clock",
            rarity: .rare
        ),
        
        // ============ 复杂上下文类 (Level 4) - 趣味彩蛋 ============
        Achievement(
            id: "context_iron_will",
            name: "减肥特种兵",
            description: "路过 3 家评分 4.0 以上的饭店但未停留。面对诱惑，心如止水。",
            category: .context,
            requirement: 3,
            rewardBones: 60,
            iconSymbol: "fork.knife",
            isSecret: true,
            rarity: .rare
        ),
        Achievement(
            id: "context_restaurant_10",
            name: "美食诱惑大师",
            description: "路过 10 家餐厅而没有停留。铁石心肠，意志如钢。",
            category: .context,
            requirement: 10,
            rewardBones: 150,
            iconSymbol: "fork.knife.circle.fill",
            isSecret: true,
            rarity: .epic
        ),
        Achievement(
            id: "context_wanderer",
            name: "三过家门而不入",
            description: "遛狗过程中 3 次经过家附近但没有结束遛狗。还不想回家，再玩五块钱的！",
            category: .context,
            requirement: 3,
            rewardBones: 80,
            iconSymbol: "arrow.triangle.2.circlepath",
            isSecret: true
        ),
        Achievement(
            id: "context_dizzy",
            name: "鬼打墙",
            description: "遛狗轨迹在一个小范围内转圈超过 5 圈。转得我头都晕了……",
            category: .context,
            requirement: 5,
            rewardBones: 50,
            iconSymbol: "arrow.triangle.capsulepath",
            isSecret: true
        ),
        Achievement(
            id: "context_artist",
            name: "完美的圆",
            description: "遛狗轨迹形成一个闭环，起点终点几乎重合。你用脚画出了一个完美的圆。",
            category: .context,
            requirement: 1,
            rewardBones: 80,
            iconSymbol: "circle",
            isSecret: true,
            rarity: .rare
        ),
        Achievement(
            id: "context_homing",
            name: "我想回家",
            description: "返程速度是去程的 2 倍以上。无论走多远，饭盆永远最有吸引力。",
            category: .context,
            requirement: 1,
            rewardBones: 60,
            iconSymbol: "house.and.flag.fill",
            isSecret: true
        ),
        Achievement(
            id: "context_companion_100",
            name: "长情陪伴",
            description: "累计遛狗时长达到 100 小时。陪伴是最长情的告白。",
            category: .context,
            requirement: 100,
            rewardBones: 500,
            iconSymbol: "heart.fill",
            isSecret: true,
            rarity: .legendary,
            gameCenterID: "petwalk.achievement.companion_100"
        ),
        Achievement(
            id: "context_explorer",
            name: "拓荒者",
            description: "去往一个离家直线距离超过 5km 的地方遛狗。发现了新大陆！",
            category: .context,
            requirement: 5,
            rewardBones: 80,
            iconSymbol: "safari.fill",
            isSecret: true,
            rarity: .rare,
            minDistance: 5.0
        ),
        Achievement(
            id: "context_local_lord",
            name: "地头蛇",
            description: "在以家为中心 1km 半径内，累计探索 50 条不同的轨迹。这片地盘，狗子都熟。",
            category: .context,
            requirement: 50,
            rewardBones: 200,
            iconSymbol: "map.fill",
            isSecret: true,
            rarity: .epic
        ),
        Achievement(
            id: "context_sniffer",
            name: "嗅探专家",
            description: "单次遛狗时长超过 30 分钟，但里程不足 500 米。每一根电线杆都有它的故事。",
            category: .context,
            requirement: 1,
            rewardBones: 30,
            iconSymbol: "nose.fill",
            isSecret: true,
            minDuration: 1800,
            maxDistance: 0.5
        ),
        
        // ============ 社交互动类 (Level 5) ============
        Achievement(
            id: "social_nanny_10",
            name: "金牌保姆",
            description: "使用代遛/直播模式累计遛狗 10 次。你是主人最信赖的伙伴！",
            category: .social,
            requirement: 10,
            rewardBones: 100,
            iconSymbol: "video.fill",
            rarity: .rare
        ),
        Achievement(
            id: "social_trustworthy",
            name: "使命必达",
            description: "在直播遛狗过程中累计收到 5 个赞。专业的服务，五星的好评！",
            category: .social,
            requirement: 5,
            rewardBones: 80,
            iconSymbol: "hand.thumbsup.fill",
            rarity: .rare
        ),
        Achievement(
            id: "social_cloud_walker",
            name: "云遛狗",
            description: "通过云遛狗累计观看达到 30 分钟。即使相隔千里，心也在一起。",
            category: .social,
            requirement: 1800, // 30分钟
            rewardBones: 60,
            iconSymbol: "cloud.fill"
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
