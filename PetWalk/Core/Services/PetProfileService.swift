//
//  PetProfileService.swift
//  PetWalk
//
//  性格与状态上下文中心 — AI Agent 的"大脑"
//  提供宠物身份、性格、实时心情的综合描述，供 DeepSeek/豆包生成个性化内容
//

import Foundation
import CoreLocation

@MainActor
class PetProfileService: ObservableObject {
    static let shared = PetProfileService()
    
    private let dataManager = DataManager.shared
    private let weatherManager = WeatherManager.shared
    private let statusManager = PetStatusManager.shared
    
    // MARK: - Codable Response Models
    
    struct PetContextResponse: Codable {
        let petName: String
        let ownerName: String
        let breed: String
        let gender: String
        let age: String
        let ageGroup: String
        let personalityTraits: String
        let voiceStyle: String
        let voiceInstruction: String
        let currentMood: String
        let moodDescription: String
        let totalWalks: Int
        let totalDistanceKm: Double
        let totalBones: Int
        let weatherContext: String?
        let aiSummary: String
        let deepLinkURL: String
    }
    
    struct MoodResponse: Codable {
        let mood: String
        let moodScore: Double
        let moodDescription: String
        let hoursSinceLastWalk: Double?
        let weatherInfluence: String?
        let aiSummary: String
    }
    
    struct PersonaBriefResponse: Codable {
        let systemPrompt: String
        let personalitySummary: String
        let voiceConstraint: String
        let contextTags: [String]
        let aiSummary: String
    }
    
    // MARK: - 获取完整宠物上下文
    
    func getFullContext() -> PetContextResponse {
        let userData = dataManager.userData
        let profile = userData.petProfile
        let mood = statusManager.calculateMood(lastWalkDate: userData.lastWalkDate)
        
        let weatherText: String?
        if let weather = weatherManager.currentWeather {
            weatherText = "\(weather.condition.displayName), \(Int(weather.temperature))°C"
        } else {
            weatherText = nil
        }
        
        let summary = buildContextSummary(
            name: userData.petName,
            breed: profile.breed,
            mood: mood,
            weather: weatherText
        )
        
        return PetContextResponse(
            petName: userData.petName,
            ownerName: userData.ownerNickname,
            breed: profile.breed.isEmpty ? "混血小可爱" : profile.breed,
            gender: profile.gender.rawValue,
            age: profile.ageDetails,
            ageGroup: profile.ageGroup.rawValue,
            personalityTraits: profile.personality.traitsDescription,
            voiceStyle: profile.voiceStyle.rawValue,
            voiceInstruction: profile.voiceStyle.promptInstruction,
            currentMood: moodName(for: mood),
            moodDescription: moodDescription(for: mood),
            totalWalks: userData.totalWalks,
            totalDistanceKm: userData.totalDistance,
            totalBones: userData.totalBones,
            weatherContext: weatherText,
            aiSummary: summary,
            deepLinkURL: "petwalk://settings"
        )
    }
    
    // MARK: - 获取实时心情
    
    func getCurrentMood() -> MoodResponse {
        let userData = dataManager.userData
        let mood = statusManager.calculateMood(lastWalkDate: userData.lastWalkDate)
        
        let hoursSince: Double?
        if let lastWalk = userData.lastWalkDate {
            hoursSince = Date().timeIntervalSince(lastWalk) / 3600.0
        } else {
            hoursSince = nil
        }
        
        let moodScore = moodToScore(mood)
        
        var weatherInfluence: String? = nil
        if let weather = weatherManager.currentWeather {
            if weather.condition == .rainy || weather.condition == .snowy {
                weatherInfluence = "外面\(weather.condition.displayName)，可能不太方便出门"
            } else if weather.temperature > 35 {
                weatherInfluence = "气温过高（\(Int(weather.temperature))°C），建议避开正午遛狗"
            } else if weather.temperature < 0 {
                weatherInfluence = "气温过低（\(Int(weather.temperature))°C），注意保暖"
            }
        }
        
        let summary = "\(userData.petName)现在的心情是\(moodDescription(for: mood))（\(String(format: "%.0f", moodScore * 100))分）。"
            + (hoursSince.map { "距离上次遛狗已经\(formatHours($0))了。" } ?? "还没有遛过狗哦。")
            + (weatherInfluence.map { " \($0)。" } ?? "")
        
        return MoodResponse(
            mood: moodName(for: mood),
            moodScore: moodScore,
            moodDescription: moodDescription(for: mood),
            hoursSinceLastWalk: hoursSince,
            weatherInfluence: weatherInfluence,
            aiSummary: summary
        )
    }
    
    // MARK: - 获取 AI 人设简报（用于注入 System Prompt）
    
    func getPersonaBrief() -> PersonaBriefResponse {
        let userData = dataManager.userData
        let profile = userData.petProfile
        let mood = statusManager.calculateMood(lastWalkDate: userData.lastWalkDate)
        
        let systemPrompt = DiaryPromptBuilder.buildSystemPrompt(
            profile: profile,
            name: userData.petName,
            ownerName: userData.ownerNickname
        )
        
        var tags: [String] = []
        tags.append("#\(profile.breed.isEmpty ? "混血" : profile.breed)")
        tags.append("#\(profile.ageGroup.rawValue)")
        tags.append("#\(profile.voiceStyle.rawValue)")
        tags.append("#心情\(moodName(for: mood))")
        
        if profile.personality.energyLevel > 0.7 { tags.append("#精力旺盛") }
        if profile.personality.socialLevel > 0.7 { tags.append("#社牛") }
        if profile.personality.foodieLevel > 0.7 { tags.append("#贪吃") }
        
        if let weather = weatherManager.currentWeather {
            tags.append("#\(weather.condition.displayName)")
        }
        
        let summary = "已为\(userData.petName)准备好AI人设：\(profile.voiceStyle.rawValue)风格的\(profile.breed.isEmpty ? "混血小可爱" : profile.breed)，当前\(moodDescription(for: mood))。"
        
        return PersonaBriefResponse(
            systemPrompt: systemPrompt,
            personalitySummary: profile.personality.traitsDescription,
            voiceConstraint: profile.voiceStyle.promptInstruction,
            contextTags: tags,
            aiSummary: summary
        )
    }
    
    // MARK: - Private Helpers
    
    private func moodName(for mood: PetMood) -> String {
        switch mood {
        case .excited: return "excited"
        case .happy: return "happy"
        case .expecting: return "expecting"
        case .depressed: return "depressed"
        }
    }
    
    private func moodDescription(for mood: PetMood) -> String {
        switch mood {
        case .excited: return "非常兴奋"
        case .happy: return "开心满足"
        case .expecting: return "期待出门"
        case .depressed: return "闷闷不乐"
        }
    }
    
    private func moodToScore(_ mood: PetMood) -> Double {
        switch mood {
        case .excited: return 1.0
        case .happy: return 0.8
        case .expecting: return 0.5
        case .depressed: return 0.2
        }
    }
    
    private func formatHours(_ hours: Double) -> String {
        if hours < 1 { return "不到1小时" }
        if hours < 24 { return "\(Int(hours))小时" }
        let days = Int(hours / 24)
        return "\(days)天"
    }
    
    private func buildContextSummary(name: String, breed: String, mood: PetMood, weather: String?) -> String {
        var parts: [String] = []
        parts.append("\(name)是一只\(breed.isEmpty ? "可爱的狗狗" : breed)")
        parts.append("现在\(moodDescription(for: mood))")
        if let w = weather { parts.append("外面天气\(w)") }
        return parts.joined(separator: "，") + "。"
    }
    
    // MARK: - JSON Serialization
    
    static func toJSON<T: Codable>(_ value: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
