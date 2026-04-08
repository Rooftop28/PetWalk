//
//  LandmarkManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import CoreLocation

// MARK: - 景点数据模型
struct Landmark: Codable, Identifiable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Double      // 触发半径（米）
    let category: String    // park, landmark, beach, etc.
    let description: String?
    
    var coordinate: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

struct LandmarksData: Codable {
    let landmarks: [Landmark]
}

// MARK: - 景点管理器
@MainActor
class LandmarkManager: ObservableObject {
    static let shared = LandmarkManager()
    
    // MARK: - 发布的属性
    @Published var landmarks: [Landmark] = []
    @Published var visitedLandmarkIds: Set<String> = []
    @Published var currentSessionVisits: [Landmark] = []  // 本次遛狗访问的景点
    
    // MARK: - 私有属性
    private let visitedKey = "visitedLandmarkIds"
    private let locationVisitCountKey = "locationVisitCounts"
    
    private var locationVisitCounts: [String: Int] = [:]
    
    /// 当前正在停留的景点及进入时间（用于 Tier 3 停留时间门槛）
    private var dwellingLandmark: (landmark: Landmark, entryTime: Date)?
    
    // MARK: - 初始化
    private init() {
        loadLandmarks()
        loadVisitedLandmarks()
        loadLocationVisitCounts()
    }
    
    // MARK: - 加载景点数据
    
    private func loadLandmarks() {
        // 从 Bundle 加载 landmarks.json
        guard let url = Bundle.main.url(forResource: "landmarks", withExtension: "json") else {
            print("LandmarkManager: landmarks.json 未找到")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(LandmarksData.self, from: data)
            landmarks = decoded.landmarks
            print("LandmarkManager: 加载了 \(landmarks.count) 个景点")
        } catch {
            print("LandmarkManager: 解析 landmarks.json 失败 - \(error)")
        }
    }
    
    private func loadVisitedLandmarks() {
        if let savedIds = UserDefaults.standard.array(forKey: visitedKey) as? [String] {
            visitedLandmarkIds = Set(savedIds)
        }
    }
    
    private func saveVisitedLandmarks() {
        UserDefaults.standard.set(Array(visitedLandmarkIds), forKey: visitedKey)
    }
    
    private func loadLocationVisitCounts() {
        if let saved = UserDefaults.standard.dictionary(forKey: locationVisitCountKey) as? [String: Int] {
            locationVisitCounts = saved
        }
    }
    
    private func saveLocationVisitCounts() {
        UserDefaults.standard.set(locationVisitCounts, forKey: locationVisitCountKey)
    }
    
    // MARK: - 位置检测
    
    /// 检测当前位置是否在某个景点范围内
    /// 需要在 POI 范围内停留 ≥3 分钟才算有效打卡（Tier 3 成就挑战层门槛）
    /// - Parameter location: 当前位置
    /// - Returns: 如果达成有效打卡，返回该景点；否则返回 nil
    func checkLocation(_ location: CLLocation) -> Landmark? {
        // 检查是否仍在当前停留的景点范围内
        if let dwelling = dwellingLandmark {
            let dist = location.distance(from: dwelling.landmark.coordinate)
            if dist <= dwelling.landmark.radius {
                // 仍在范围内，检查停留时长是否达标
                let dwellTime = Date().timeIntervalSince(dwelling.entryTime)
                if WalkValidation.meetsLandmarkDwellThreshold(dwellSeconds: dwellTime) {
                    // 达到停留门槛，正式记录打卡
                    let lm = dwelling.landmark
                    dwellingLandmark = nil
                    
                    if !currentSessionVisits.contains(where: { $0.id == lm.id }) {
                        currentSessionVisits.append(lm)
                        
                        if !visitedLandmarkIds.contains(lm.id) {
                            visitedLandmarkIds.insert(lm.id)
                            saveVisitedLandmarks()
                            print("LandmarkManager: 有效打卡 - \(lm.name) (停留\(Int(dwellTime))秒)")
                        }
                        return lm
                    }
                }
                return nil
            } else {
                // 离开了当前停留的景点范围，取消追踪
                print("LandmarkManager: 离开景点范围 - \(dwelling.landmark.name)，未达停留门槛")
                dwellingLandmark = nil
            }
        }
        
        // 扫描是否进入新的景点范围
        for landmark in landmarks {
            let distance = location.distance(from: landmark.coordinate)
            
            if distance <= landmark.radius {
                if !currentSessionVisits.contains(where: { $0.id == landmark.id }) {
                    // 进入新景点范围，开始计时
                    dwellingLandmark = (landmark: landmark, entryTime: Date())
                    print("LandmarkManager: 进入景点范围 - \(landmark.name)，开始计时")
                    return nil
                }
            }
        }
        return nil
    }
    
    /// 记录起点位置的访问次数（用于"家门口的守护者"成就）
    /// - Parameter location: 起点位置
    func recordStartLocation(_ location: CLLocation) {
        // 使用简化的坐标作为 key（精确到小数点后 3 位，约 100 米精度）
        let key = String(format: "%.3f,%.3f", location.coordinate.latitude, location.coordinate.longitude)
        locationVisitCounts[key, default: 0] += 1
        saveLocationVisitCounts()
    }
    
    /// 获取某位置的访问次数
    func getVisitCount(for location: CLLocation) -> Int {
        let key = String(format: "%.3f,%.3f", location.coordinate.latitude, location.coordinate.longitude)
        return locationVisitCounts[key] ?? 0
    }
    
    /// 获取最常访问的位置的次数
    func getMaxLocationVisitCount() -> Int {
        return locationVisitCounts.values.max() ?? 0
    }
    
    // MARK: - 会话管理
    
    /// 开始新的遛狗会话（清除本次访问记录）
    func startNewSession() {
        currentSessionVisits.removeAll()
        dwellingLandmark = nil
    }
    
    /// 结束遛狗会话
    func endSession() {
        dwellingLandmark = nil
    }
    
    // MARK: - 统计数据
    
    /// 获取已访问的公园数量
    var visitedParksCount: Int {
        landmarks
            .filter { $0.category == "park" && visitedLandmarkIds.contains($0.id) }
            .count
    }
    
    /// 获取已访问的所有景点数量
    var totalVisitedCount: Int {
        visitedLandmarkIds.count
    }
    
    /// 按类别获取已访问景点数量
    func visitedCount(forCategory category: String) -> Int {
        landmarks
            .filter { $0.category == category && visitedLandmarkIds.contains($0.id) }
            .count
    }
}
