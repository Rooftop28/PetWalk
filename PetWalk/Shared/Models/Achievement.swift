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
    case distance   // 里程类
    case frequency  // 频率类
    case streak     // 连续打卡类
    case special    // 特殊成就（预留 POI 检测等）
    
    var title: String {
        switch self {
        case .distance: return "里程达人"
        case .frequency: return "坚持不懈"
        case .streak: return "连续打卡"
        case .special: return "特殊成就"
        }
    }
    
    var iconSymbol: String {
        switch self {
        case .distance: return "figure.walk"
        case .frequency: return "repeat"
        case .streak: return "flame.fill"
        case .special: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .distance: return .blue
        case .frequency: return .green
        case .streak: return .orange
        case .special: return .purple
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
        
        // ============ 特殊成就（预留接口）============
        Achievement(
            id: "special_early_bird",
            name: "早起的鸟儿",
            description: "在早上 6 点前完成一次遛狗。",
            category: .special,
            requirement: 1,
            rewardBones: 30,
            iconSymbol: "sunrise.fill"
        ),
        Achievement(
            id: "special_night_owl",
            name: "夜行侠",
            description: "在晚上 10 点后完成一次遛狗。",
            category: .special,
            requirement: 1,
            rewardBones: 30,
            iconSymbol: "moon.stars.fill"
        ),
        Achievement(
            id: "special_long_walk",
            name: "长途跋涉",
            description: "单次遛狗超过 5 公里。",
            category: .special,
            requirement: 5,
            rewardBones: 50,
            iconSymbol: "road.lanes"
        ),
        Achievement(
            id: "special_restaurant_10",
            name: "美食诱惑",
            description: "路过 10 家餐厅而没有停留（即将推出）。",
            category: .special,
            requirement: 10,
            rewardBones: 100,
            iconSymbol: "fork.knife"
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
