//
//  HealthManager.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/2.
//

import Foundation
import HealthKit

@MainActor
class HealthManager: ObservableObject {
    // 核心对象
    let healthStore = HKHealthStore()
    
    // 发布给 UI 的数据
    @Published var currentDistance: Double = 0.0 // 单位：公里
    @Published var currentSteps: Int = 0         // 单位：步
    
    init() {
        // App 启动时尝试请求权限并读取数据
        requestAuthorization()
    }
    
    func requestAuthorization() {
        // 1. 检查设备是否支持
        guard HKHealthStore.isHealthDataAvailable() else {
            print("设备不支持 HealthKit")
            return
        }
        
        // 2. 我们要读的数据类型：步数 + 步行/跑步距离
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        let typesToRead: Set = [stepType, distanceType]
        
        // 3. 弹窗申请权限
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                // 授权成功后，立刻去拉取一次数据
                self.fetchTodayStats()
            } else {
                print("HealthKit 授权失败: \(String(describing: error))")
            }
        }
    }
    
    func fetchTodayStats() {
        // 获取“今天”的时间范围 (从零点到现在)
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        // --- 1. 查询步数 ---
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let stepQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.currentSteps = Int(sum.doubleValue(for: .count()))
            }
        }
        
        // --- 2. 查询距离 ---
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let distanceQuery = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                // 转换为公里 (km) -> healthKit 默认是米
                self.currentDistance = sum.doubleValue(for: .meter()) / 1000.0
            }
        }
        
        // 执行查询
        healthStore.execute(stepQuery)
        healthStore.execute(distanceQuery)
    }
}
