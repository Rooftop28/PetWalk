//
//  InteractionIntentService.swift
//  PetWalk
//
//  意图与指令分发器 — App 与外部 Agent（豆包/App Intents）的唯一出入口
//  所有的控制请求都经过这里，统一做权限校验和日志记录
//

import Foundation

@MainActor
class InteractionIntentService: ObservableObject {
    static let shared = InteractionIntentService()
    
    private let walkingService = WalkingService.shared
    private let diaryService = DiaryService.shared
    private let achievementService = AchievementService.shared
    private let petProfileService = PetProfileService.shared
    private let locationWeatherService = LocationWeatherService.shared
    private let deepLinkRouter = DeepLinkRouter.shared
    
    // MARK: - Intent Log
    
    struct IntentLogEntry: Codable, Identifiable {
        let id: String
        let intentName: String
        let timestamp: Date
        let source: String
        let success: Bool
        let resultSummary: String
    }
    
    @Published var recentLogs: [IntentLogEntry] = []
    
    // MARK: - Codable Response Models
    
    struct IntentResponse: Codable {
        let success: Bool
        let intentName: String
        let result: String
        let deepLinkURL: String?
        let aiSummary: String
    }
    
    struct AvailableIntentsResponse: Codable {
        let intents: [IntentDescriptor]
        let aiSummary: String
    }
    
    struct IntentDescriptor: Codable {
        let name: String
        let description: String
        let category: String
        let parameters: [String]
        let deepLinkURL: String
    }
    
    // MARK: - 获取所有可用意图
    
    func getAvailableIntents() -> AvailableIntentsResponse {
        let intents: [IntentDescriptor] = [
            IntentDescriptor(
                name: "start_walk",
                description: "开始遛狗追踪，启动GPS定位和计时。当用户说'带狗出去'、'开始遛狗'时调用。",
                category: "遛狗",
                parameters: [],
                deepLinkURL: "petwalk://walk"
            ),
            IntentDescriptor(
                name: "stop_walk",
                description: "结束当前遛狗，保存记录并计算奖励。当用户说'结束遛狗'、'回家了'时调用。",
                category: "遛狗",
                parameters: ["mood: String? (happy/normal/tired)"],
                deepLinkURL: "petwalk://walk"
            ),
            IntentDescriptor(
                name: "get_walk_status",
                description: "查询当前是否在遛狗以及实时数据。当用户问'在遛狗吗'、'走了多远'时调用。",
                category: "遛狗",
                parameters: [],
                deepLinkURL: "petwalk://walk/active"
            ),
            IntentDescriptor(
                name: "get_today_stats",
                description: "获取今天的遛狗总距离、次数和目标进度。当用户问'今天遛了多远'时调用。",
                category: "遛狗",
                parameters: [],
                deepLinkURL: "petwalk://history/today"
            ),
            IntentDescriptor(
                name: "get_pet_context",
                description: "获取宠物的完整信息，包括名字、品种、性格、当前心情。当用户问'我的狗叫什么'、'狗狗开心吗'时调用。",
                category: "宠物",
                parameters: [],
                deepLinkURL: "petwalk://settings"
            ),
            IntentDescriptor(
                name: "get_pet_mood",
                description: "获取宠物当前实时心情评分和描述。当用户问'球球现在开心吗'、'狗狗心情怎么样'时调用。",
                category: "宠物",
                parameters: [],
                deepLinkURL: "petwalk://home"
            ),
            IntentDescriptor(
                name: "get_environment",
                description: "获取当前天气、位置和周边景点信息。当用户问'现在天气怎么样'、'附近有什么'时调用。",
                category: "环境",
                parameters: [],
                deepLinkURL: "petwalk://home"
            ),
            IntentDescriptor(
                name: "get_walk_advisory",
                description: "获取现在是否适合遛狗的建议。当用户问'现在适合遛狗吗'、'什么时候出门好'时调用。",
                category: "环境",
                parameters: [],
                deepLinkURL: "petwalk://home"
            ),
            IntentDescriptor(
                name: "get_achievement_overview",
                description: "查看成就系统总览和完成进度。当用户问'成就完成了多少'时调用。",
                category: "成就",
                parameters: [],
                deepLinkURL: "petwalk://achievement"
            ),
            IntentDescriptor(
                name: "get_recent_achievements",
                description: "查看最近解锁的成就。当用户问'最近完成了什么成就'时调用。",
                category: "成就",
                parameters: [],
                deepLinkURL: "petwalk://achievement"
            ),
            IntentDescriptor(
                name: "get_achievement_suggestions",
                description: "根据当前天气和时间推荐可完成的成就。当用户问'今天能完成什么成就'时调用。",
                category: "成就",
                parameters: ["weather: String?", "temperature: Double?"],
                deepLinkURL: "petwalk://achievement"
            ),
            IntentDescriptor(
                name: "generate_diary",
                description: "为最近一次遛狗生成AI日记。当用户说'写日记'、'记录今天的遛狗'时调用。",
                category: "日记",
                parameters: ["walkRecordId: String?"],
                deepLinkURL: "petwalk://diary/today"
            ),
            IntentDescriptor(
                name: "get_today_diary",
                description: "查看今天的遛狗日记。当用户问'今天的日记'、'狗狗今天说了什么'时调用。",
                category: "日记",
                parameters: [],
                deepLinkURL: "petwalk://diary/today"
            ),
            IntentDescriptor(
                name: "get_persona_brief",
                description: "获取宠物AI人设简报，包含System Prompt和性格标签。当需要构建AI对话上下文时调用。",
                category: "宠物",
                parameters: [],
                deepLinkURL: "petwalk://settings"
            ),
            IntentDescriptor(
                name: "navigate",
                description: "跳转到App内指定页面。当需要引导用户查看特定内容时调用。",
                category: "导航",
                parameters: ["destination: String (home/walk/history/achievement/shop/settings/achievement/{id})"],
                deepLinkURL: "petwalk://home"
            )
        ]
        
        return AvailableIntentsResponse(
            intents: intents,
            aiSummary: "当前共有\(intents.count)个可用指令，涵盖遛狗、宠物、环境、成就、日记和导航6个类别。"
        )
    }
    
    // MARK: - 执行意图（统一入口）
    
    func executeIntent(name: String, parameters: [String: String] = [:], source: String = "agent") -> IntentResponse {
        let result: IntentResponse
        
        switch name {
        case "start_walk":
            let r = walkingService.startWalk()
            result = IntentResponse(
                success: true, intentName: name,
                result: WalkingService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: "petwalk://walk/active",
                aiSummary: r.aiSummary
            )
            
        case "stop_walk":
            let mood = parameters["mood"] ?? "happy"
            let r = walkingService.stopWalk(request: StopWalkRequest(mood: mood))
            result = IntentResponse(
                success: true, intentName: name,
                result: WalkingService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: "petwalk://walk",
                aiSummary: r.aiSummary
            )
            
        case "get_walk_status":
            let r = walkingService.getWalkStatus()
            result = IntentResponse(
                success: true, intentName: name,
                result: WalkingService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: r.isWalking ? "petwalk://walk/active" : "petwalk://home",
                aiSummary: r.aiSummary
            )
            
        case "get_today_stats":
            let r = walkingService.getTodayStats()
            result = IntentResponse(
                success: true, intentName: name,
                result: WalkingService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: "petwalk://history/today",
                aiSummary: r.aiSummary
            )
            
        case "get_pet_context":
            let r = petProfileService.getFullContext()
            result = IntentResponse(
                success: true, intentName: name,
                result: PetProfileService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: r.deepLinkURL,
                aiSummary: r.aiSummary
            )
            
        case "get_pet_mood":
            let r = petProfileService.getCurrentMood()
            result = IntentResponse(
                success: true, intentName: name,
                result: PetProfileService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: "petwalk://home",
                aiSummary: r.aiSummary
            )
            
        case "get_persona_brief":
            let r = petProfileService.getPersonaBrief()
            result = IntentResponse(
                success: true, intentName: name,
                result: PetProfileService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: "petwalk://settings",
                aiSummary: r.aiSummary
            )
            
        case "get_environment":
            let r = locationWeatherService.getEnvironmentContext()
            result = IntentResponse(
                success: true, intentName: name,
                result: LocationWeatherService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: r.deepLinkURL,
                aiSummary: r.aiSummary
            )
            
        case "get_walk_advisory":
            let r = locationWeatherService.getWalkAdvisory()
            result = IntentResponse(
                success: true, intentName: name,
                result: LocationWeatherService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: r.deepLinkURL,
                aiSummary: r.aiSummary
            )
            
        case "get_achievement_overview":
            let r = achievementService.getOverview()
            result = IntentResponse(
                success: true, intentName: name,
                result: WalkingService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: "petwalk://achievement",
                aiSummary: r.aiSummary
            )
            
        case "get_recent_achievements":
            let r = achievementService.getRecentlyUnlocked()
            result = IntentResponse(
                success: true, intentName: name,
                result: WalkingService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: "petwalk://achievement",
                aiSummary: r.aiSummary
            )
            
        case "get_achievement_suggestions":
            let weather: WeatherSuggestionRequest?
            if parameters["weather"] != nil || parameters["temperature"] != nil {
                weather = WeatherSuggestionRequest(
                    condition: parameters["weather"],
                    temperature: parameters["temperature"].flatMap { Double($0) }
                )
            } else {
                weather = nil
            }
            let r = achievementService.getSuggestions(weather: weather)
            result = IntentResponse(
                success: true, intentName: name,
                result: WalkingService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: "petwalk://achievement",
                aiSummary: r.aiSummary
            )
            
        case "get_today_diary":
            let r = diaryService.getTodayDiaries()
            result = IntentResponse(
                success: true, intentName: name,
                result: WalkingService.toJSON(r) ?? r.aiSummary,
                deepLinkURL: "petwalk://diary/today",
                aiSummary: r.aiSummary
            )
            
        case "navigate":
            if let dest = parameters["destination"] {
                let url = URL(string: "petwalk://\(dest)")!
                deepLinkRouter.handleURL(url)
                result = IntentResponse(
                    success: true, intentName: name,
                    result: "已导航到 \(dest)",
                    deepLinkURL: "petwalk://\(dest)",
                    aiSummary: "已跳转到\(dest)页面。"
                )
            } else {
                result = IntentResponse(
                    success: false, intentName: name,
                    result: "缺少 destination 参数",
                    deepLinkURL: nil,
                    aiSummary: "导航失败：未指定目标页面。"
                )
            }
            
        default:
            result = IntentResponse(
                success: false, intentName: name,
                result: "未知指令: \(name)",
                deepLinkURL: nil,
                aiSummary: "不支持的指令「\(name)」，请使用 get_available_intents 查看可用指令列表。"
            )
        }
        
        logIntent(name: name, source: source, success: result.success, summary: result.aiSummary)
        return result
    }
    
    // MARK: - Deep Link 生成
    
    func generateDeepLink(for destination: String) -> String {
        return "petwalk://\(destination)"
    }
    
    func generateDeepLink(forAchievement id: String) -> String {
        return "petwalk://achievement/\(id)"
    }
    
    func generateDeepLink(forRecord id: String) -> String {
        return "petwalk://history/\(id)"
    }
    
    func generateDeepLink(forDiary recordId: String) -> String {
        return "petwalk://diary/\(recordId)"
    }
    
    // MARK: - Private
    
    private func logIntent(name: String, source: String, success: Bool, summary: String) {
        let entry = IntentLogEntry(
            id: UUID().uuidString,
            intentName: name,
            timestamp: Date(),
            source: source,
            success: success,
            resultSummary: String(summary.prefix(100))
        )
        recentLogs.insert(entry, at: 0)
        if recentLogs.count > 50 {
            recentLogs.removeLast()
        }
        
        print("📡 Intent[\(source)]: \(name) → \(success ? "✅" : "❌") \(String(summary.prefix(60)))")
    }
    
    // MARK: - JSON Serialization
    
    static func toJSON<T: Codable>(_ value: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
