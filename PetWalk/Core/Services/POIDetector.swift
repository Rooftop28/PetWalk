//
//  POIDetector.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import CoreLocation
import MapKit

// MARK: - POI 状态机
enum POIState {
    case walking              // 正常行走
    case nearPOI(MKMapItem)   // 靠近某个 POI
    case passed               // 已经路过（未停留）
    case stopped              // 已停留
}

// MARK: - POI 检测器
@MainActor
class POIDetector: ObservableObject {
    static let shared = POIDetector()
    
    // MARK: - 发布的属性
    @Published var passedRestaurantCount: Int = 0     // 路过餐厅计数
    @Published var homeLoopCount: Int = 0             // 绕起点圈数
    @Published var currentState: POIState = .walking
    @Published var nearbyRestaurants: [MKMapItem] = []
    
    // MARK: - 私有属性
    private var startLocation: CLLocation?
    private var lastSearchTime: Date?
    private var currentPOI: MKMapItem?
    private var nearPOIEntryTime: Date?
    private var passedPOIIds: Set<String> = []        // 已路过的 POI ID
    private var distanceFromStart: Double = 0
    private var maxDistanceFromStart: Double = 0
    private var loopDetectionQueue: [Double] = []     // 距离起点的历史记录
    
    // 配置
    private let searchInterval: TimeInterval = 30.0   // POI 搜索间隔（秒）
    private let poiRadius: Double = 50.0              // POI 触发半径（米）
    private let stopThreshold: TimeInterval = 30.0    // 停留判定时间（秒）
    private let minSpeedForMoving: Double = 0.3       // 最小移动速度（m/s）
    private let loopRadius: Double = 50.0             // 判定为"回到起点"的半径
    
    private init() {}
    
    // MARK: - 会话管理
    
    /// 开始新的遛狗会话
    func startSession(at location: CLLocation) {
        startLocation = location
        passedRestaurantCount = 0
        homeLoopCount = 0
        currentState = .walking
        nearbyRestaurants.removeAll()
        passedPOIIds.removeAll()
        currentPOI = nil
        nearPOIEntryTime = nil
        distanceFromStart = 0
        maxDistanceFromStart = 0
        loopDetectionQueue.removeAll()
        lastSearchTime = nil
        
        // 立即搜索附近餐厅
        Task {
            await searchNearbyRestaurants(at: location)
        }
    }
    
    /// 结束遛狗会话
    func endSession() -> (passedRestaurants: Int, homeLoops: Int) {
        let result = (passedRestaurantCount, homeLoopCount)
        // 清理状态
        startLocation = nil
        return result
    }
    
    // MARK: - 位置更新
    
    /// 更新当前位置和速度
    func updateLocation(_ location: CLLocation, speed: Double) {
        guard let start = startLocation else { return }
        
        // 计算与起点的距离
        distanceFromStart = location.distance(from: start)
        maxDistanceFromStart = max(maxDistanceFromStart, distanceFromStart)
        
        // 检测绕圈
        detectHomeLoop()
        
        // 定期搜索 POI
        if shouldSearchPOI() {
            Task {
                await searchNearbyRestaurants(at: location)
            }
        }
        
        // 状态机更新
        updateStateMachine(location: location, speed: speed)
    }
    
    // MARK: - POI 搜索
    
    private func shouldSearchPOI() -> Bool {
        guard let lastSearch = lastSearchTime else { return true }
        return Date().timeIntervalSince(lastSearch) >= searchInterval
    }
    
    private func searchNearbyRestaurants(at location: CLLocation) async {
        lastSearchTime = Date()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "餐厅"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            nearbyRestaurants = response.mapItems
            print("POIDetector: 发现 \(nearbyRestaurants.count) 家附近餐厅")
        } catch {
            print("POIDetector: 搜索餐厅失败 - \(error.localizedDescription)")
        }
    }
    
    // MARK: - 状态机
    
    private func updateStateMachine(location: CLLocation, speed: Double) {
        switch currentState {
        case .walking:
            // 检查是否进入某个 POI 范围
            if let poi = findNearbyPOI(location: location) {
                currentState = .nearPOI(poi)
                currentPOI = poi
                nearPOIEntryTime = Date()
                print("POIDetector: 进入 POI 范围 - \(poi.name ?? "未知")")
            }
            
        case .nearPOI(let poi):
            let distance = location.distance(from: CLLocation(
                latitude: poi.placemark.coordinate.latitude,
                longitude: poi.placemark.coordinate.longitude
            ))
            
            // 检查是否离开 POI 范围
            if distance > poiRadius {
                if speed > minSpeedForMoving {
                    // 离开且在移动 -> 路过未停留
                    handlePassed(poi: poi)
                } else {
                    // 离开但速度很慢 -> 可能刚离开停留点
                    currentState = .walking
                }
                currentPOI = nil
                nearPOIEntryTime = nil
            } else {
                // 还在 POI 范围内
                if let entryTime = nearPOIEntryTime,
                   Date().timeIntervalSince(entryTime) > stopThreshold,
                   speed < minSpeedForMoving {
                    // 停留超过阈值且速度很低 -> 判定为停留
                    currentState = .stopped
                    print("POIDetector: 在 \(poi.name ?? "未知") 停留")
                }
            }
            
        case .passed:
            // 短暂状态，立即回到 walking
            currentState = .walking
            
        case .stopped:
            // 如果开始移动，回到 walking
            if speed > minSpeedForMoving {
                currentState = .walking
                currentPOI = nil
            }
        }
    }
    
    private func findNearbyPOI(location: CLLocation) -> MKMapItem? {
        for poi in nearbyRestaurants {
            let poiLocation = CLLocation(
                latitude: poi.placemark.coordinate.latitude,
                longitude: poi.placemark.coordinate.longitude
            )
            let distance = location.distance(from: poiLocation)
            
            // 在范围内且未被记录过
            let poiId = "\(poi.placemark.coordinate.latitude),\(poi.placemark.coordinate.longitude)"
            if distance <= poiRadius && !passedPOIIds.contains(poiId) {
                return poi
            }
        }
        return nil
    }
    
    private func handlePassed(poi: MKMapItem) {
        let poiId = "\(poi.placemark.coordinate.latitude),\(poi.placemark.coordinate.longitude)"
        passedPOIIds.insert(poiId)
        passedRestaurantCount += 1
        currentState = .passed
        print("POIDetector: 路过 \(poi.name ?? "餐厅") 未停留 (总计: \(passedRestaurantCount))")
    }
    
    // MARK: - 绕圈检测
    
    private func detectHomeLoop() {
        // 记录距离历史
        loopDetectionQueue.append(distanceFromStart)
        
        // 只保留最近 60 个点（约 1 分钟）
        if loopDetectionQueue.count > 60 {
            loopDetectionQueue.removeFirst()
        }
        
        // 检测是否形成一个"回到起点"的模式
        // 条件：曾经走远（> 100米），现在回到起点附近（< 50米）
        if maxDistanceFromStart > 100 && distanceFromStart < loopRadius {
            // 检查是否是新的一圈（防止重复计数）
            let recentDistances = loopDetectionQueue.suffix(10)
            let wasAway = recentDistances.contains { $0 > loopRadius * 2 }
            
            if wasAway {
                homeLoopCount += 1
                maxDistanceFromStart = 0  // 重置，准备检测下一圈
                print("POIDetector: 检测到绕圈 (总计: \(homeLoopCount))")
            }
        }
    }
}
