//
//  UserReward.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import SwiftUI

// MARK: - 用户称号
struct UserTitle: Identifiable, Codable, Hashable {
    let id: String
    let name: String           // 称号名称
    let description: String    // 描述文案
    let price: Int             // 骨头币价格 (0 = 免费)
    let iconSymbol: String     // SF Symbol 图标
    
    // MARK: - 静态称号列表
    static let allTitles: [UserTitle] = [
        UserTitle(
            id: "title_default",
            name: "遛狗新手",
            description: "每个人都是从这里开始的。",
            price: 0,
            iconSymbol: "person.fill"
        ),
        UserTitle(
            id: "title_walker",
            name: "散步达人",
            description: "每天的散步是最好的放松。",
            price: 50,
            iconSymbol: "figure.walk"
        ),
        UserTitle(
            id: "title_park",
            name: "公园常客",
            description: "公园里的常客，狗狗们的好朋友。",
            price: 100,
            iconSymbol: "leaf.fill"
        ),
        UserTitle(
            id: "title_marathon",
            name: "马拉松狗爸/狗妈",
            description: "和毛孩子一起跑遍世界！",
            price: 200,
            iconSymbol: "medal.fill"
        ),
        UserTitle(
            id: "title_explorer",
            name: "城市探险家",
            description: "带着毛孩子探索城市的每一个角落。",
            price: 300,
            iconSymbol: "map.fill"
        ),
        UserTitle(
            id: "title_legend",
            name: "传奇遛狗人",
            description: "遛狗界的传奇，人人敬仰。",
            price: 500,
            iconSymbol: "crown.fill"
        )
    ]
    
    /// 获取指定 ID 的称号
    static func title(byId id: String) -> UserTitle? {
        allTitles.first { $0.id == id }
    }
    
    /// 默认称号
    static var defaultTitle: UserTitle {
        allTitles.first { $0.id == "title_default" }!
    }
}

// MARK: - App 主题配色
struct AppTheme: Identifiable, Codable, Hashable {
    let id: String
    let name: String           // 主题名称
    let description: String    // 描述文案
    let price: Int             // 骨头币价格 (0 = 免费)
    let iconSymbol: String     // SF Symbol 图标
    
    // 颜色配置 (使用 Hex 存储)
    let backgroundHex: String
    let primaryHex: String
    let accentHex: String
    
    // MARK: - 特殊主题扩展（预留接口）
    var specialEffectType: String?       // 特效类型: "particles", "gradient", "animated" 等
    var specialEffectConfig: [String: String]?  // 特效配置参数
    
    // MARK: - 计算属性：转换为 Color
    var backgroundColor: Color {
        Color(hex: backgroundHex)
    }
    
    var primaryColor: Color {
        Color(hex: primaryHex)
    }
    
    var accentColor: Color {
        Color(hex: accentHex)
    }
    
    // MARK: - 静态主题列表
    static let allThemes: [AppTheme] = [
        AppTheme(
            id: "theme_default",
            name: "默认奶油色",
            description: "温暖舒适的默认配色。",
            price: 0,
            iconSymbol: "paintpalette.fill",
            backgroundHex: "FFF9F0",
            primaryHex: "8BC34A",
            accentHex: "4A3021",
            specialEffectType: nil,
            specialEffectConfig: nil
        ),
        AppTheme(
            id: "theme_forest",
            name: "森林绿主题",
            description: "置身于大自然中的清新感。",
            price: 100,
            iconSymbol: "tree.fill",
            backgroundHex: "E8F5E9",
            primaryHex: "4CAF50",
            accentHex: "1B5E20",
            specialEffectType: nil,
            specialEffectConfig: nil
        ),
        AppTheme(
            id: "theme_sunset",
            name: "夕阳橙主题",
            description: "黄昏时分的温暖色调。",
            price: 150,
            iconSymbol: "sunset.fill",
            backgroundHex: "FFF3E0",
            primaryHex: "FF9800",
            accentHex: "E65100",
            specialEffectType: nil,
            specialEffectConfig: nil
        ),
        AppTheme(
            id: "theme_ocean",
            name: "海洋蓝主题",
            description: "海边散步的清凉感觉。",
            price: 150,
            iconSymbol: "water.waves",
            backgroundHex: "E3F2FD",
            primaryHex: "2196F3",
            accentHex: "0D47A1",
            specialEffectType: nil,
            specialEffectConfig: nil
        ),
        AppTheme(
            id: "theme_dark",
            name: "深夜模式",
            description: "保护眼睛的深色主题。",
            price: 200,
            iconSymbol: "moon.fill",
            backgroundHex: "1A1A2E",
            primaryHex: "8BC34A",
            accentHex: "FFFFFF",
            specialEffectType: nil,
            specialEffectConfig: nil
        ),
        AppTheme(
            id: "theme_sakura",
            name: "樱花粉主题",
            description: "春日樱花盛开的浪漫气息。",
            price: 200,
            iconSymbol: "leaf.fill",
            backgroundHex: "FCE4EC",
            primaryHex: "E91E63",
            accentHex: "880E4F",
            specialEffectType: nil,
            specialEffectConfig: nil
        )
    ]
    
    /// 获取指定 ID 的主题
    static func theme(byId id: String) -> AppTheme? {
        allThemes.first { $0.id == id }
    }
    
    /// 默认主题
    static var defaultTheme: AppTheme {
        allThemes.first { $0.id == "theme_default" }!
    }
}
