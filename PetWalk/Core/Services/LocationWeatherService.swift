//
//  LocationWeatherService.swift
//  PetWalk
//
//  环境感知中枢 — 将原始地理/天气数据语义化
//  为 AI Agent 提供人类可读的环境描述和遛狗建议
//

import Foundation
import CoreLocation

@MainActor
class LocationWeatherService: ObservableObject {
    static let shared = LocationWeatherService()
    
    private let weatherManager = WeatherManager.shared
    private let landmarkManager = LandmarkManager.shared
    private let locationManager = WalkSessionManager.shared.locationService
    
    // MARK: - Codable Response Models
    
    struct EnvironmentContextResponse: Codable {
        let weather: WeatherSnapshot?
        let location: LocationSnapshot?
        let nearbyLandmarks: [LandmarkInfo]
        let environmentTags: [String]
        let walkAdvice: WalkAdvice
        let aiSummary: String
        let deepLinkURL: String
    }
    
    struct WeatherSnapshot: Codable {
        let condition: String
        let conditionDisplay: String
        let temperature: Double
        let humidity: Double
        let windSpeed: Double
        let feelDescription: String
        let iconSymbol: String
    }
    
    struct LocationSnapshot: Codable {
        let latitude: Double
        let longitude: Double
        let semanticDescription: String?
    }
    
    struct LandmarkInfo: Codable {
        let id: String
        let name: String
        let category: String
        let distanceMeters: Double?
        let visited: Bool
    }
    
    struct WalkAdvice: Codable {
        let isGoodTime: Bool
        let recommendation: String
        let bestTimeWindow: String?
        let achievementHint: String?
    }
    
    struct WalkAdvisoryResponse: Codable {
        let advice: WalkAdvice
        let weather: WeatherSnapshot?
        let aiSummary: String
        let deepLinkURL: String
    }
    
    // MARK: - 获取完整环境上下文
    
    func getEnvironmentContext() -> EnvironmentContextResponse {
        let weatherSnap = buildWeatherSnapshot()
        let locationSnap = buildLocationSnapshot()
        let landmarks = buildNearbyLandmarks()
        let tags = buildEnvironmentTags(weather: weatherSnap)
        let advice = buildWalkAdvice(weather: weatherSnap)
        
        var summaryParts: [String] = []
        if let w = weatherSnap {
            summaryParts.append("当前天气\(w.conditionDisplay)，\(Int(w.temperature))°C，\(w.feelDescription)")
        }
        if !landmarks.isEmpty {
            let names = landmarks.prefix(3).map { $0.name }
            summaryParts.append("附近有\(names.joined(separator: "、"))")
        }
        summaryParts.append(advice.recommendation)
        
        return EnvironmentContextResponse(
            weather: weatherSnap,
            location: locationSnap,
            nearbyLandmarks: landmarks,
            environmentTags: tags,
            walkAdvice: advice,
            aiSummary: summaryParts.joined(separator: "。") + "。",
            deepLinkURL: "petwalk://home"
        )
    }
    
    // MARK: - 遛狗建议（独立接口）
    
    func getWalkAdvisory() -> WalkAdvisoryResponse {
        let weatherSnap = buildWeatherSnapshot()
        let advice = buildWalkAdvice(weather: weatherSnap)
        
        var summary = advice.recommendation
        if let hint = advice.achievementHint {
            summary += " " + hint
        }
        
        return WalkAdvisoryResponse(
            advice: advice,
            weather: weatherSnap,
            aiSummary: summary,
            deepLinkURL: "petwalk://walk"
        )
    }
    
    // MARK: - 刷新天气数据
    
    func refreshWeather() async {
        if let location = locationManager.currentLocation {
            await weatherManager.fetchWeather(for: location)
        }
    }
    
    // MARK: - Private Builders
    
    private func buildWeatherSnapshot() -> WeatherSnapshot? {
        guard let weather = weatherManager.currentWeather else { return nil }
        return WeatherSnapshot(
            condition: weather.condition.rawValue,
            conditionDisplay: weather.condition.displayName,
            temperature: weather.temperature,
            humidity: weather.humidity,
            windSpeed: weather.windSpeed,
            feelDescription: temperatureFeeling(weather.temperature),
            iconSymbol: weather.condition.iconSymbol
        )
    }
    
    private func buildLocationSnapshot() -> LocationSnapshot? {
        guard let location = locationManager.currentLocation else { return nil }
        
        return LocationSnapshot(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            semanticDescription: nil
        )
    }
    
    private func buildNearbyLandmarks() -> [LandmarkInfo] {
        guard let location = locationManager.currentLocation else { return [] }
        
        return landmarkManager.landmarks
            .map { landmark in
                let dist = landmark.coordinate.distance(from: location)
                return LandmarkInfo(
                    id: landmark.id,
                    name: landmark.name,
                    category: landmark.category,
                    distanceMeters: dist,
                    visited: landmarkManager.visitedLandmarkIds.contains(landmark.id)
                )
            }
            .filter { ($0.distanceMeters ?? Double.infinity) < 5000 }
            .sorted { ($0.distanceMeters ?? 0) < ($1.distanceMeters ?? 0) }
    }
    
    private func buildEnvironmentTags(weather: WeatherSnapshot?) -> [String] {
        var tags: [String] = []
        
        if let w = weather {
            tags.append("#\(w.conditionDisplay)")
            tags.append("#\(temperatureFeeling(w.temperature))")
            
            if w.temperature < 0 { tags.append("#严寒") }
            if w.temperature > 35 { tags.append("#酷暑") }
        }
        
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<6: tags.append("#凌晨")
        case 6..<9: tags.append("#清晨")
        case 9..<12: tags.append("#上午")
        case 12..<14: tags.append("#正午")
        case 14..<17: tags.append("#下午")
        case 17..<20: tags.append("#傍晚")
        case 20..<23: tags.append("#夜晚")
        default: tags.append("#深夜")
        }
        
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 { tags.append("#周末") }
        
        return tags
    }
    
    private func buildWalkAdvice(weather: WeatherSnapshot?) -> WalkAdvice {
        guard let w = weather else {
            return WalkAdvice(
                isGoodTime: true,
                recommendation: "天气数据暂未加载，随时可以出发遛狗",
                bestTimeWindow: nil,
                achievementHint: nil
            )
        }
        
        var isGood = true
        var recommendation = ""
        var bestTime: String? = nil
        var achievementHint: String? = nil
        
        switch w.condition {
        case "rainy":
            isGood = false
            recommendation = "外面正在下雨，建议等雨停后再出门"
            bestTime = "预计1-2小时后天气好转"
            achievementHint = "不过如果冒雨遛狗超过15分钟，可以解锁「风雨无阻」成就哦！"
        case "snowy":
            isGood = false
            recommendation = "外面正在下雪，注意路面结冰"
            achievementHint = "在雪天遛狗可以解锁「冰雪奇缘」成就！"
        default:
            break
        }
        
        if w.temperature > 35 {
            isGood = false
            recommendation = "当前气温\(Int(w.temperature))°C，太热了，建议傍晚凉快后再出门"
            bestTime = "建议17:00后出门"
            achievementHint = nil
        } else if w.temperature < -5 {
            isGood = false
            recommendation = "当前气温\(Int(w.temperature))°C，注意给狗狗保暖"
            achievementHint = "在严寒天气遛狗可以解锁「冰雪奇缘」成就！"
        }
        
        if isGood && recommendation.isEmpty {
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 4 && hour < 6 {
                recommendation = "天气不错，适合遛狗"
                achievementHint = "凌晨遛狗可以解锁「闻鸡起舞」成就！"
            } else if hour >= 23 || hour < 2 {
                recommendation = "夜深了，注意安全"
                achievementHint = "深夜遛狗可以解锁「暗夜骑士」成就！"
            } else {
                recommendation = "天气\(w.conditionDisplay)，\(Int(w.temperature))°C，\(temperatureFeeling(w.temperature))，很适合出门遛狗"
            }
        }
        
        return WalkAdvice(
            isGoodTime: isGood,
            recommendation: recommendation,
            bestTimeWindow: bestTime,
            achievementHint: achievementHint
        )
    }
    
    private func temperatureFeeling(_ temp: Double) -> String {
        switch temp {
        case ..<(-10): return "极寒"
        case -10..<0: return "严寒"
        case 0..<10: return "寒冷"
        case 10..<18: return "微凉"
        case 18..<25: return "舒适"
        case 25..<30: return "温暖"
        case 30..<35: return "炎热"
        default: return "酷暑"
        }
    }
    
    // MARK: - JSON Serialization
    
    static func toJSON<T: Codable>(_ value: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
