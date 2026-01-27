//
//  ThemeManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import SwiftUI
import Combine

/// 主题管理器 - 负责全局主题切换和颜色管理
@MainActor
class ThemeManager: ObservableObject {
    // MARK: - 单例
    static let shared = ThemeManager()
    
    // MARK: - 发布的属性
    @Published var currentTheme: AppTheme
    
    // MARK: - 动态颜色属性
    var backgroundColor: Color {
        currentTheme.backgroundColor
    }
    
    var primaryColor: Color {
        currentTheme.primaryColor
    }
    
    var accentColor: Color {
        currentTheme.accentColor
    }
    
    // MARK: - 初始化
    private init() {
        // 从 UserData 加载已保存的主题
        let savedThemeId = DataManager.shared.userData.equippedThemeId
        self.currentTheme = AppTheme.theme(byId: savedThemeId) ?? AppTheme.defaultTheme
    }
    
    // MARK: - 主题切换
    
    /// 应用新主题
    /// - Parameter theme: 要应用的主题
    func applyTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
        
        // 同步保存到 UserData
        var userData = DataManager.shared.userData
        userData.equippedThemeId = theme.id
        DataManager.shared.updateUserData(userData)
    }
    
    /// 根据主题 ID 应用主题
    /// - Parameter themeId: 主题 ID
    func applyTheme(byId themeId: String) {
        guard let theme = AppTheme.theme(byId: themeId) else { return }
        applyTheme(theme)
    }
    
    /// 重新加载主题（从 UserData 同步）
    func reloadTheme() {
        let savedThemeId = DataManager.shared.userData.equippedThemeId
        if let theme = AppTheme.theme(byId: savedThemeId) {
            currentTheme = theme
        }
    }
    
    // MARK: - 特殊主题支持（预留接口）
    
    /// 检查当前主题是否有特殊效果
    var hasSpecialEffect: Bool {
        currentTheme.specialEffectType != nil
    }
    
    /// 获取特殊效果类型
    var specialEffectType: String? {
        currentTheme.specialEffectType
    }
    
    /// 获取特殊效果配置
    var specialEffectConfig: [String: String]? {
        currentTheme.specialEffectConfig
    }
}

// MARK: - 环境键扩展（用于在视图中注入 ThemeManager）
struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue: ThemeManager = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}
