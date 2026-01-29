//
//  WalkSessionManager.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//

import Foundation
import Combine
import CoreLocation

@MainActor
class WalkSessionManager: ObservableObject {
    // 状态：是否正在遛狗
    @Published var isWalking = false
    
    // 计时数据
    @Published var duration: TimeInterval = 0
    @Published var distance: Double = 0.0 // km
    
    // MARK: - 新增：成就系统集成
    @Published var currentWeather: WeatherData?
    @Published var visitedLandmarks: [Landmark] = []
    
    // 起始位置（用于成就检测）
    private var startLocation: CLLocation?
    
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
        
        // 新增：订阅位置更新，用于成就检测
        locationManager.$currentLocation
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                guard let self = self, self.isWalking else { return }
                self.onLocationUpdate(location)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 位置更新回调（成就检测）
    
    private func onLocationUpdate(_ location: CLLocation) {
        let speed = locationManager.currentSpeed
        
        // 直播模式：如果有正在进行的直播，广播坐标
        if LiveSessionManager.shared.isBroadcasting {
            LiveSessionManager.shared.broadcastLocation(location)
        }
        
        // 检测景点打卡
        if let landmark = LandmarkManager.shared.checkLocation(location) {
            visitedLandmarks.append(landmark)
            print("WalkSessionManager: 发现景点 - \(landmark.name)")
        }
        
        // 更新 POI 检测器（餐厅路过检测等）
        POIDetector.shared.updateLocation(location, speed: speed)
    }
    
    // 开始遛狗
    func startWalk() {
        isWalking = true
        startTime = Date()
        duration = 0
        distance = 0
        visitedLandmarks = []
        currentWeather = nil
        
        // 启动定位
        locationManager.requestPermission()
        locationManager.startRecording()
        
        // 启动各管理器
        LandmarkManager.shared.startNewSession()
        
        // 获取天气和初始化 POI 检测器（异步）
        Task {
            // 等待位置更新
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5秒
            
            if let location = locationManager.currentLocation {
                startLocation = location
                
                // 记录起点位置（用于"家门口的守护者"成就）
                LandmarkManager.shared.recordStartLocation(location)
                
                // 启动 POI 检测器
                POIDetector.shared.startSession(at: location)
                
                // 获取天气
                await WeatherManager.shared.fetchWeather(for: location)
                currentWeather = WeatherManager.shared.currentWeather
                
                if let weather = currentWeather {
                    print("WalkSessionManager: 当前天气 - \(weather.weatherText), \(Int(weather.temperature))°C")
                }
            }
        }
        
        // 启动计时器 (只更新时间)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateStats()
            }
        }
    }
    
    // 结束遛狗 - 返回 WalkSessionData 用于成就检测
    func stopWalk() -> WalkSessionData {
        isWalking = false
        timer?.invalidate()
        timer = nil
        locationManager.stopRecording()
        
        // 结束各管理器并获取数据
        let poiResult = POIDetector.shared.endSession()
        LandmarkManager.shared.endSession()
        
        // 自动停止直播 (如果有)
        if LiveSessionManager.shared.isBroadcasting {
            LiveSessionManager.shared.stopBroadcast()
        }
        
        // 构建会话数据
        let sessionData = WalkSessionData(
            distance: distance,
            duration: duration,
            startTime: startTime ?? Date(),
            averageSpeed: averageSpeed,
            startLocation: startLocation,
            weather: currentWeather?.asWeatherInfo,
            passedRestaurantCount: poiResult.passedRestaurants,
            homeLoopCount: poiResult.homeLoops
        )
        
        print("WalkSessionManager: 遛狗结束 - 距离: \(String(format: "%.2f", distance))km, 时长: \(formattedDuration), 配速: \(formattedAverageSpeed)")
        print("WalkSessionManager: 路过餐厅: \(poiResult.passedRestaurants), 绕圈: \(poiResult.homeLoops)")
        
        return sessionData
    }
    
    // 简单结束（向后兼容）
    func stopWalkSimple() {
        _ = stopWalk()
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
    
    // MARK: - 速度计算 (Level 3)
    
    /// 平均配速 (km/h)
    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        // distance 已经是 km，duration 是秒
        return (distance / duration) * 3600  // km/h
    }
    
    /// 格式化平均配速
    var formattedAverageSpeed: String {
        return String(format: "%.1f km/h", averageSpeed)
    }
    
    /// 当前瞬时速度 (km/h)
    var currentSpeed: Double {
        // 从 LocationManager 获取当前速度
        let speedMps = locationManager.currentSpeed  // m/s
        return max(0, speedMps * 3.6)  // 转换为 km/h
    }
    
    // MARK: - 获取遛狗开始时间
    
    var walkStartTime: Date {
        return startTime ?? Date()
    }
}
