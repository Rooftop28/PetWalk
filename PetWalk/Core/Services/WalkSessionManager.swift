//
//  WalkSessionManager.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//

import Foundation
import Combine

@MainActor
class WalkSessionManager: ObservableObject {
    // 状态：是否正在遛狗
    @Published var isWalking = false
    
    // 计时数据
    @Published var duration: TimeInterval = 0
    @Published var distance: Double = 0.0 // km
    
    // 计时器
    private var timer: Timer?
    private var startTime: Date?
    
    // 定位服务
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // 暴露给 View 使用
    var locationService: LocationManager { locationManager }
    
    init() {
        setupLocationUpdates()
    }
    
    // 监听位置更新计算距离
    private func setupLocationUpdates() {
        // 订阅 LocationManager 的 totalDistance
        locationManager.$totalDistance
            .receive(on: RunLoop.main)
            .sink { [weak self] totalMeters in
                guard let self = self, self.isWalking else { return }
                self.distance = totalMeters / 1000.0 // 转换为 km
            }
            .store(in: &cancellables)
    }
    
    // 开始遛狗
    func startWalk() {
        isWalking = true
        startTime = Date()
        duration = 0
        distance = 0
        
        // 启动定位
        locationManager.requestPermission()
        locationManager.startRecording()
        
        // 启动计时器 (只更新时间)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateStats()
            }
        }
    }
    
    // 结束遛狗
    func stopWalk() {
        isWalking = false
        timer?.invalidate()
        timer = nil
        locationManager.stopRecording()
    }
    
    // 每秒更新逻辑
    private func updateStats() {
        guard let start = startTime else { return }
        // 更新时间
        duration = Date().timeIntervalSince(start)
        // 距离由 Combine 自动更新，这里不需要做
    }
    
    // 格式化时间显示 (00:00)
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

