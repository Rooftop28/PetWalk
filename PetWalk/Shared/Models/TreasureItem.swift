//
//  TreasureItem.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/8.
//

// MARK: - ⚠️ DEPRECATED
// 此文件已弃用，保留代码以便后续参考或重新启用。
// 已被成就系统 (Achievement.swift) 替代。
// 弃用日期: 2026/01/28

import Foundation
import SwiftUI

enum Rarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case legendary
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .legendary: return .yellow // 金色
        }
    }
    
    var title: String {
        switch self {
        case .common: return "垃圾"
        case .uncommon: return "普通"
        case .rare: return "稀有"
        case .legendary: return "传说"
        }
    }
}

struct TreasureItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String // 趣味文案
    let rarity: Rarity
    let iconName: String // 对应系统 SF Symbols 或者本地图片名
    let isMapExclusive: Bool // 是否仅地图掉落（传说级）
    
    // 为了方便测试，我们可以预设一些静态数据
    static let allItems: [TreasureItem] = [
        // Common
        TreasureItem(id: "c_stick", name: "枯树枝", description: "不知道为什么，狗狗就是喜欢咬这个。", rarity: .common, iconName: "dry_tree_branch", isMapExclusive: false),
        TreasureItem(id: "c_ball", name: "破网球", description: "已经被咬得面目全非了。", rarity: .common, iconName: "old_torn_tennis_ball", isMapExclusive: false),
        TreasureItem(id: "c_can", name: "易拉罐", description: "虽然是垃圾，但狗狗好像很感兴趣。", rarity: .common, iconName: "guanzi", isMapExclusive: false),
        
        // Uncommon
        TreasureItem(id: "u_stone", name: "鹅卵石", description: "一颗非常圆润的石头。", rarity: .uncommon, iconName: "circle.fill", isMapExclusive: false),
        TreasureItem(id: "u_coin", name: "丢失的硬币", description: "看来今天运气不错！", rarity: .uncommon, iconName: "bitcoinsign.circle.fill", isMapExclusive: false),
        TreasureItem(id: "u_feather", name: "鸟羽毛", description: "可能是鸽子留下的礼物。", rarity: .uncommon, iconName: "leaf.fill", isMapExclusive: false),
        
        // Rare
        TreasureItem(id: "r_glass", name: "发光玻璃珠", description: "在阳光下闪闪发光。", rarity: .rare, iconName: "sparkles", isMapExclusive: false),
        TreasureItem(id: "r_duck", name: "玩具鸭子", description: "捏一下会响的那种！", rarity: .rare, iconName: "figure.roll", isMapExclusive: false),
        
        // Legendary (仅掉落)
        TreasureItem(id: "l_alien", name: "外星人零件", description: "这是什么高科技？！", rarity: .legendary, iconName: "gearshape.2.fill", isMapExclusive: true),
        TreasureItem(id: "l_gold_bone", name: "金骨头", description: "传说中的宝物，所有狗狗的梦想。", rarity: .legendary, iconName: "crown.fill", isMapExclusive: true)
    ]
}

