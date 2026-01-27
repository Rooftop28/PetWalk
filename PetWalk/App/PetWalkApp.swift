//
//  PetWalkApp.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//

import SwiftUI
import SwiftData

@main // 这个标记非常重要，它是 App 的入口
struct PetWalkApp: App {
    // 观察 ThemeManager，当主题变化时触发 UI 刷新
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // 启动初始化管理器
    @StateObject private var initializer = AppInitializer.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // 主界面（在启动画面下方预先加载）
                if initializer.isReady {
                    MainTabView()
                        // 使用主题 ID 作为视图标识，主题变化时强制刷新
                        .id(themeManager.currentTheme.id)
                        // 将 ThemeManager 注入到环境中
                        .environment(\.themeManager, themeManager)
                        .transition(.opacity)
                }
                
                // 启动画面（覆盖在上方）
                if !initializer.isReady {
                    SplashView(initializer: initializer)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: initializer.isReady)
        }
    }
}
