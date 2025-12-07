//
//  LocationManager.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // 发布当前位置
    @Published var currentLocation: CLLocation?
    // 发布轨迹 (用于画线)
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    // 权限状态
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // 是否正在记录
    var isRecording = false
    
    // 累计距离 (米)
    @Published var totalDistance: Double = 0
    private var lastLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // 每移动 5 米更新一次
        // 允许后台定位 (需要在 Capabilities 开启 Background Modes -> Location updates)
        locationManager.allowsBackgroundLocationUpdates = true 
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startRecording() {
        isRecording = true
        routeCoordinates.removeAll()
        totalDistance = 0
        lastLocation = nil
        locationManager.startUpdatingLocation()
    }
    
    func stopRecording() {
        isRecording = false
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Delegate Methods
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 过滤精度太差的点 (比如误差超过 50 米)
        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > 50 { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            
            if self.isRecording {
                // 计算距离增量
                if let last = self.lastLocation {
                    let delta = location.distance(from: last)
                    self.totalDistance += delta
                }
                self.lastLocation = location
                
                self.routeCoordinates.append(location.coordinate)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失败: \(error.localizedDescription)")
    }
    
    // MARK: - Debug Simulation
    #if DEBUG
    func simulateMove(to coordinate: CLLocationCoordinate2D) {
        let newLocation = CLLocation(
            coordinate: coordinate,
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            timestamp: Date()
        )
        
        // 手动触发更新逻辑
        DispatchQueue.main.async {
            self.currentLocation = newLocation
            
            if self.isRecording {
                if let last = self.lastLocation {
                    let delta = newLocation.distance(from: last)
                    self.totalDistance += delta
                }
                self.lastLocation = newLocation
                self.routeCoordinates.append(newLocation.coordinate)
            }
        }
    }
    #endif
}

