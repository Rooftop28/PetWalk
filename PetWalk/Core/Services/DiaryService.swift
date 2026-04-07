//
//  DiaryService.swift
//  PetWalk
//
//  AI Agent API 层 — 日记生成与查询的可序列化接口
//

import Foundation

// MARK: - API 请求 / 响应模型 (JSON Codable)

/// 生成日记的请求
struct GenerateDiaryRequest: Codable {
    let walkRecordId: String?
    let distanceKm: Double?
    let durationMinutes: Int?
    let weatherCondition: String?
    let weatherTemperature: Double?
    let specialEvents: [String]?
    
    enum CodingKeys: String, CodingKey {
        case walkRecordId = "walk_record_id"
        case distanceKm = "distance_km"
        case durationMinutes = "duration_minutes"
        case weatherCondition = "weather_condition"
        case weatherTemperature = "weather_temperature"
        case specialEvents = "special_events"
    }
}

/// 生成日记的响应
struct GenerateDiaryResponse: Codable {
    let success: Bool
    let walkRecordId: String?
    let diaryText: String
    let moodScore: Int
    let weatherContext: String?
    let generatedAt: String
    let aiSummary: String
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case walkRecordId = "walk_record_id"
        case diaryText = "diary_text"
        case moodScore = "mood_score"
        case weatherContext = "weather_context"
        case generatedAt = "generated_at"
        case aiSummary = "ai_summary"
        case deepLinkURL = "deep_link_url"
    }
}

/// 今日日记查询响应
struct TodayDiaryResponse: Codable {
    let hasDiary: Bool
    let diaries: [DiaryEntry]
    let aiSummary: String
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case hasDiary = "has_diary"
        case diaries
        case aiSummary = "ai_summary"
        case deepLinkURL = "deep_link_url"
    }
}

/// 单条日记条目
struct DiaryEntry: Codable {
    let walkRecordId: String
    let date: String
    let time: String
    let diaryText: String
    let distanceKm: Double
    let durationMinutes: Int
    let mood: String
    let deepLinkURL: String
    
    enum CodingKeys: String, CodingKey {
        case walkRecordId = "walk_record_id"
        case date, time
        case diaryText = "diary_text"
        case distanceKm = "distance_km"
        case durationMinutes = "duration_minutes"
        case mood
        case deepLinkURL = "deep_link_url"
    }
}

// MARK: - DiaryService

@MainActor
class DiaryService {
    static let shared = DiaryService()
    
    private let dataManager = DataManager.shared
    
    private init() {}
    
    // MARK: - 生成 AI 日记
    
    /// 为指定遛狗记录生成 AI 日记
    /// - Parameter request: 遛狗数据（可指定 walkRecordId 或直接传入数据）
    /// - Returns: `GenerateDiaryResponse` 包含日记文本和元数据
    func generateDiary(request: GenerateDiaryRequest) async -> GenerateDiaryResponse {
        let profile = dataManager.userData.petProfile
        let petName = dataManager.userData.petName
        let ownerName = dataManager.userData.ownerNickname
        
        // 构建 WalkSessionData 给 DiaryPromptBuilder
        let weather: WeatherInfo?
        if let cond = request.weatherCondition, let temp = request.weatherTemperature {
            weather = WeatherInfo(condition: cond, temperature: temp)
        } else {
            weather = nil
        }
        
        let sessionData = WalkSessionData(
            distance: request.distanceKm ?? 0,
            duration: TimeInterval((request.durationMinutes ?? 0) * 60),
            startTime: Date(),
            averageSpeed: 0,
            startLocation: nil,
            weather: weather,
            passedRestaurantCount: 0,
            homeLoopCount: 0
        )
        
        let systemPrompt = DiaryPromptBuilder.buildSystemPrompt(
            profile: profile,
            name: petName,
            ownerName: ownerName
        )
        let userPrompt = DiaryPromptBuilder.buildUserPrompt(sessionData: sessionData)
        
        do {
            let content = try await LLMService.shared.generateDiary(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt
            )
            
            let formatter = ISO8601DateFormatter()
            let weatherDesc = weather.map { "\($0.condition), \(Int($0.temperature))°C" }
            
            // 如果提供了 recordId，绑定到对应记录
            if let recordId = request.walkRecordId,
               let uuid = UUID(uuidString: recordId),
               let index = dataManager.records.firstIndex(where: { $0.id == uuid }) {
                dataManager.records[index].aiDiary = content
                dataManager.records[index].aiDiaryGeneratedAt = Date()
                dataManager.saveData()
            }
            
            return GenerateDiaryResponse(
                success: true,
                walkRecordId: request.walkRecordId,
                diaryText: content,
                moodScore: 8,
                weatherContext: weatherDesc,
                generatedAt: formatter.string(from: Date()),
                aiSummary: "\(petName)的日记已生成：\(String(content.prefix(50)))…",
                deepLinkURL: request.walkRecordId.map { "petwalk://diary/\($0)" } ?? "petwalk://diary"
            )
        } catch {
            return GenerateDiaryResponse(
                success: false,
                walkRecordId: request.walkRecordId,
                diaryText: "",
                moodScore: 0,
                weatherContext: nil,
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                aiSummary: "日记生成失败：\(error.localizedDescription)",
                deepLinkURL: "petwalk://diary"
            )
        }
    }
    
    // MARK: - 查看今日日记
    
    /// 获取今天的所有遛狗日记
    /// - Returns: `TodayDiaryResponse`
    func getTodayDiaries() -> TodayDiaryResponse {
        let calendar = Calendar.current
        let today = Date()
        
        let todayRecords = dataManager.records.filter { record in
            guard let ts = record.timestamp else { return false }
            return calendar.isDate(ts, inSameDayAs: today)
        }
        
        let diariesWithContent = todayRecords.filter { $0.aiDiary != nil }
        let petName = dataManager.userData.petName
        
        let entries = todayRecords.map { record in
            DiaryEntry(
                walkRecordId: record.id.uuidString,
                date: record.date,
                time: record.time,
                diaryText: record.aiDiary ?? "（暂无日记）",
                distanceKm: record.distance,
                durationMinutes: record.duration,
                mood: record.mood,
                deepLinkURL: "petwalk://diary/\(record.id.uuidString)"
            )
        }
        
        let summary: String
        if todayRecords.isEmpty {
            summary = "今天还没有带\(petName)出门，出门遛弯后才有日记哦。"
        } else if diariesWithContent.isEmpty {
            summary = "\(petName)今天遛了\(todayRecords.count)次弯，但还没有生成日记。"
        } else {
            summary = "\(petName)今天有\(diariesWithContent.count)篇日记，快来看看狗狗的内心世界吧！"
        }
        
        return TodayDiaryResponse(
            hasDiary: !diariesWithContent.isEmpty,
            diaries: entries,
            aiSummary: summary,
            deepLinkURL: "petwalk://diary/today"
        )
    }
    
    // MARK: - 获取指定日期的日记
    
    /// 获取指定日期的遛狗日记
    /// - Parameter date: 目标日期
    /// - Returns: `TodayDiaryResponse`
    func getDiaries(for date: Date) -> TodayDiaryResponse {
        let calendar = Calendar.current
        let petName = dataManager.userData.petName
        
        let records = dataManager.records.filter { record in
            guard let ts = record.timestamp else { return false }
            return calendar.isDate(ts, inSameDayAs: date)
        }
        
        let diariesWithContent = records.filter { $0.aiDiary != nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        let dateStr = formatter.string(from: date)
        
        let entries = records.map { record in
            DiaryEntry(
                walkRecordId: record.id.uuidString,
                date: record.date,
                time: record.time,
                diaryText: record.aiDiary ?? "（暂无日记）",
                distanceKm: record.distance,
                durationMinutes: record.duration,
                mood: record.mood,
                deepLinkURL: "petwalk://diary/\(record.id.uuidString)"
            )
        }
        
        let summary: String
        if records.isEmpty {
            summary = "\(dateStr)\(petName)没有遛弯记录。"
        } else {
            summary = "\(dateStr)\(petName)遛了\(records.count)次弯，有\(diariesWithContent.count)篇日记。"
        }
        
        return TodayDiaryResponse(
            hasDiary: !diariesWithContent.isEmpty,
            diaries: entries,
            aiSummary: summary,
            deepLinkURL: "petwalk://diary/\(formatter.string(from: date))"
        )
    }
}
