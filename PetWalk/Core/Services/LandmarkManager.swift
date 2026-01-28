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
    private let locationVisitCountKey = "locationVisitCounts"  // 位置访问次数
    
    // 位置访问计数（用于"家门口的守护者"成就）
    private var locationVisitCounts: [String: Int] = [:]
    
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
    /// - Parameter location: 当前位置
    /// - Returns: 如果进入新景点，返回该景点；否则返回 nil
    func checkLocation(_ location: CLLocation) -> Landmark? {
        for landmark in landmarks {
            let distance = location.distance(from: landmark.coordinate)
            
            // 在触发半径内
            if distance <= landmark.radius {
                // 检查本次遛狗是否已经访问过
                if !currentSessionVisits.contains(where: { $0.id == landmark.id }) {
                    // 记录本次访问
                    currentSessionVisits.append(landmark)
                    
                    // 如果是首次访问（历史上从未访问过）
                    if !visitedLandmarkIds.contains(landmark.id) {
                        visitedLandmarkIds.insert(landmark.id)
                        saveVisitedLandmarks()
                        print("LandmarkManager: 首次到访 - \(landmark.name)")
                    }
                    
                    return landmark
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
    }
    
    /// 结束遛狗会话
    func endSession() {
        // 会话结束时可以做一些统计
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
