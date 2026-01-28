//
//  WeatherManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import CoreLocation
import WeatherKit

// MARK: - 天气条件枚举
enum WeatherCondition: String, Codable {
    case sunny = "sunny"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case snowy = "snowy"
    case foggy = "foggy"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .sunny: return "晴天"
        case .cloudy: return "多云"
        case .rainy: return "雨天"
        case .snowy: return "雪天"
        case .foggy: return "雾天"
        case .unknown: return "未知"
        }
    }
    
    var iconSymbol: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "snowflake"
        case .foggy: return "cloud.fog.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - 天气数据
struct WeatherData {
    let condition: WeatherCondition
    let temperature: Double         // 摄氏度
    let humidity: Double            // 湿度百分比 0-100
    let windSpeed: Double           // 风速 m/s
    let location: CLLocation?
    let fetchTime: Date
    
    /// 转换为 WeatherInfo（用于成就检测）
    var asWeatherInfo: WeatherInfo {
        WeatherInfo(condition: condition.rawValue, temperature: temperature)
    }
}

// MARK: - 天气管理器
@MainActor
class WeatherManager: ObservableObject {
    static let shared = WeatherManager()
    
    // MARK: - 发布的属性
    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - 私有属性
    private let weatherService = WeatherService.shared
    
    private init() {}
    
    // MARK: - 获取当前天气
    
    /// 根据位置获取天气
    /// - Parameter location: 当前位置
    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let weather = try await weatherService.weather(for: location)
            
            // 解析天气条件
            let condition = mapCondition(weather.currentWeather.condition)
            let temperature = weather.currentWeather.temperature.value  // 默认摄氏度
            let humidity = weather.currentWeather.humidity * 100
            let windSpeed = weather.currentWeather.wind.speed.value
            
            currentWeather = WeatherData(
                condition: condition,
                temperature: temperature,
                humidity: humidity,
                windSpeed: windSpeed,
                location: location,
                fetchTime: Date()
            )
            
            print("WeatherManager: 获取天气成功 - \(condition.displayName), \(Int(temperature))°C")
            
        } catch {
            errorMessage = "获取天气失败: \(error.localizedDescription)"
            print("WeatherManager: \(errorMessage ?? "")")
            
            // 使用模拟数据（开发/测试用）
            #if DEBUG
            currentWeather = mockWeatherData(for: location)
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - 映射天气条件
    
    private func mapCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
        case .clear, .mostlyClear, .hot:
            return .sunny
        case .cloudy, .mostlyCloudy, .partlyCloudy:
            return .cloudy
        case .rain, .heavyRain, .drizzle, .sunShowers, .thunderstorms, .tropicalStorm, .hurricane:
            return .rainy
        case .snow, .heavySnow, .flurries, .sleet, .freezingRain, .freezingDrizzle, .blizzard, .blowingSnow, .wintryMix:
            return .snowy
        case .foggy, .haze, .smoky:
            return .foggy
        default:
            return .unknown
        }
    }
    
    // MARK: - 模拟数据（开发用）
    
    #if DEBUG
    private func mockWeatherData(for location: CLLocation) -> WeatherData {
        // 根据当前时间模拟不同天气
        let hour = Calendar.current.component(.hour, from: Date())
        let condition: WeatherCondition
        let temperature: Double
        
        switch hour {
        case 6..<10:
            condition = .cloudy
            temperature = 18.0
        case 10..<16:
            condition = .sunny
            temperature = 25.0
        case 16..<20:
            condition = .cloudy
            temperature = 22.0
        default:
            condition = .cloudy
            temperature = 15.0
        }
        
        return WeatherData(
            condition: condition,
            temperature: temperature,
            humidity: 65.0,
            windSpeed: 3.5,
            location: location,
            fetchTime: Date()
        )
    }
    
    /// 手动设置天气（测试用）
    func setMockWeather(condition: WeatherCondition, temperature: Double) {
        currentWeather = WeatherData(
            condition: condition,
            temperature: temperature,
            humidity: 50.0,
            windSpeed: 2.0,
            location: nil,
            fetchTime: Date()
        )
    }
    #endif
}
