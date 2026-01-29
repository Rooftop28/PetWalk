//
//  PetStatusManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/8.
//

import SwiftUI

// MARK: - 核心状态枚举
enum PetMood: CaseIterable {
    case excited, happy, expecting, depressed
    
    // 通过 Provider 获取配置，实现解耦
    var anim: MoodAnimationConfig {
        PetAnimationProvider.getConfig(for: self)
    }
    
    @MainActor
    var dialogue: MoodDialogueConfig {
        PetDialogueProvider.getConfig(for: self)
    }
    
    var overlay: MoodOverlayConfig {
        PetOverlayProvider.getConfig(for: self)
    }
    
    var debugTitle: String {
        switch self {
        case .excited: return "兴奋 (现在)"
        case .happy: return "开心 (5h前)"
        case .expecting: return "期待 (25h前)"
        case .depressed: return "郁闷 (50h前)"
        }
    }
}

@MainActor
class PetStatusManager {
    static let shared = PetStatusManager()
    
    // 根据最后一次遛狗时间计算心情
    func calculateMood(lastWalkDate: Date?) -> PetMood {
        guard let lastDate = lastWalkDate else { return .happy }
        let hours = Date().timeIntervalSince(lastDate) / 3600
        
        if hours < 3 { return .excited }
        else if hours < 24 { return .happy }
        else if hours < 48 { return .expecting }
        else { return .depressed }
    }
    
    #if DEBUG
    // Debug 工具：强制更新时间来模拟心情
    func debugUpdateMood(_ mood: PetMood, dataManager: DataManager) {
        var newDate: Date
        switch mood {
        case .excited: newDate = Date()
        case .happy: newDate = Date().addingTimeInterval(-5 * 3600)
        case .expecting: newDate = Date().addingTimeInterval(-25 * 3600)
        case .depressed: newDate = Date().addingTimeInterval(-50 * 3600)
        }
        
        var userData = dataManager.userData
        userData.lastWalkDate = newDate
        dataManager.updateUserData(userData)
    }
    #endif
}
