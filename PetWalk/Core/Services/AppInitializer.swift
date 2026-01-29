//
//  AppInitializer.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import SwiftUI
import Combine

/// App 启动任务管理器 - 协调所有初始化任务
@MainActor
class AppInitializer: ObservableObject {
    // MARK: - 单例
    static let shared = AppInitializer()
    
    // MARK: - 发布的状态
    @Published var isReady = false           // 是否完成所有必要加载
    @Published var progress: Double = 0      // 加载进度 (0-1)
    @Published var statusText = "正在启动..."  // 当前状态文字
    
    // MARK: - 私有属性
    private var hasInitialized = false
    private var startTime: Date?
    
    // 各任务完成状态
    private var userDataLoaded = false
    private var themeInitialized = false
    private var healthDataRequested = false
    
    // MARK: - 配置
    private let minimumDisplayTime: TimeInterval = 1.5  // 启动画面最少显示 1.5 秒
    
    // MARK: - 初始化任务权重（用于计算进度）
    private let taskWeights: [String: Double] = [
        "userData": 0.4,
        "theme": 0.3,
        "health": 0.3
    ]
    
    private init() {}
    
    // MARK: - 启动初始化
    
    /// 执行所有初始化任务
    func initialize() async {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        // 记录开始时间
        startTime = Date()
        
        // 1. 加载用户数据
        await loadUserData()
        
        // 2. 初始化主题
        await initializeTheme()
        
        // 3. 请求 HealthKit 数据
        await requestHealthData()
        
        // 完成所有必要任务
        await completeInitialization()
    }
    
    // MARK: - 任务 1: 加载用户数据
    
    private func loadUserData() async {
        updateStatus("正在加载用户数据...")
        
        // DataManager 在 init 时已经加载了数据
        // 这里确保它已经完成
        _ = DataManager.shared.userData
        
        userDataLoaded = true
        updateProgress(for: "userData")
        
        // 模拟最小加载时间，让用户能看到状态变化
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
    }
    
    // MARK: - 任务 2: 初始化主题
    
    private func initializeTheme() async {
        updateStatus("正在应用主题...")
        
        // ThemeManager 在 init 时已经加载了主题
        // 确保它已经初始化
        _ = ThemeManager.shared.currentTheme
        
        themeInitialized = true
        updateProgress(for: "theme")
        
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
    }
    
    // MARK: - 任务 3: 请求 HealthKit 数据
    
    private func requestHealthData() async {
        updateStatus("正在获取健康数据...")
        
        // 创建 HealthManager 实例会自动请求权限
        // 这里我们等待一小段时间让权限请求完成
        let healthManager = HealthManager()
        
        // 等待数据获取（带超时）
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        healthDataRequested = true
        updateProgress(for: "health")
    }
    

    
    // MARK: - 完成初始化
    
    private func completeInitialization() async {
        updateStatus("准备就绪")
        
        // 计算已经过去的时间
        let elapsedTime = Date().timeIntervalSince(startTime ?? Date())
        let remainingTime = minimumDisplayTime - elapsedTime
        
        // 如果还没到最小显示时间，继续等待
        if remainingTime > 0 {
            let nanoseconds = UInt64(remainingTime * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
        
        withAnimation(.easeOut(duration: 0.3)) {
            isReady = true
        }
    }
    
    // MARK: - 辅助方法
    
    private func updateStatus(_ text: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            statusText = text
        }
    }
    
    private func updateProgress(for task: String) {
        guard let weight = taskWeights[task] else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            progress = min(1.0, progress + weight)
        }
    }
    
    /// 重置初始化状态（用于测试或重新启动）
    func reset() {
        hasInitialized = false
        startTime = nil
        isReady = false
        progress = 0
        statusText = "正在启动..."
        userDataLoaded = false
        themeInitialized = false
        healthDataRequested = false
    }
}
