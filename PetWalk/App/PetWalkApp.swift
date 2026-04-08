//
//  PetWalkApp.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//

import SwiftUI
import SwiftData
import UserNotifications

@main // 这个标记非常重要，它是 App 的入口
struct PetWalkApp: App {
    // 观察 ThemeManager，当主题变化时触发 UI 刷新
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // 启动初始化管理器
    @StateObject private var initializer = AppInitializer.shared
    
    // Game Center 管理器 (V2: enableGameCenter)
    @ObservedObject private var gameCenter = GameCenterManager.shared
    
    // 观察 DataManager 以检查 onboarding 状态
    @ObservedObject private var dataManager = DataManager.shared
    
    // Deep Link 路由器
    @ObservedObject private var deepLinkRouter = DeepLinkRouter.shared
    
    // 监听 App 生命周期
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if initializer.isReady {
                    // Force onboarding if pet profile is not set (e.g. migration for old users)
                    if dataManager.userData.hasCompletedOnboarding && !dataManager.userData.petProfile.breed.isEmpty {
                        MainTabView()
                            // 使用主题 ID 作为视图标识，主题变化时强制刷新
                            .id(themeManager.currentTheme.id)
                            // 将 ThemeManager 注入到环境中
                            .environment(\.themeManager, themeManager)
                            .transition(.opacity)
                            .onAppear {
                                // 初始化 Game Center (V2: enableGameCenter)
                                if FeatureFlags.enableGameCenter {
                                    gameCenter.authenticate()
                                }
                                
                                // 清理可能的僵尸活动
                                Task {
                                    await WalkSessionManager.shared.terminateAllActivities()
                                }
                            }
                    } else {
                        OnboardingView {
                            // 完成回调，状态更新会自动触发视图切换
                        }
                        .transition(.move(edge: .trailing))
                    }
                }
                
                // 启动画面（覆盖在上方）
                if !initializer.isReady {
                    SplashView(initializer: initializer)
                        .transition(.opacity)
                }
            }
            #if DEBUG
            .overlay(alignment: .topTrailing) {
                DebugFloatingBubble()
            }
            #endif
            .preferredColorScheme(.light)
            .animation(.easeInOut(duration: 0.5), value: initializer.isReady)
            .animation(.easeInOut(duration: 0.5), value: dataManager.userData.hasCompletedOnboarding)
            .onOpenURL { url in
                deepLinkRouter.handleURL(url)
            }
            // 监听场景状态，回到前台时清除角标
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // 清除 App 角标
                    UNUserNotificationCenter.current().setBadgeCount(0) { error in
                        if let error = error {
                            print("清除角标失败: \(error)")
                        }
                    }
                    // 兼容旧版本 iOS (虽然 setBadgeCount 是 iOS 16+)
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
            }
        }
    }
}
