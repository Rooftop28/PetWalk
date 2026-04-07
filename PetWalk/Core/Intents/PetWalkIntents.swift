//
//  PetWalkIntents.swift
//  PetWalk
//
//  App Intents — Siri / Shortcuts / AI Agent 调用入口
//

import AppIntents
import Foundation

// MARK: - 开始遛狗 Intent

struct StartWalkIntent: AppIntent {
    static var title: LocalizedStringResource = "开始遛狗"
    static var description = IntentDescription(
        "启动 PetWalk 的遛狗追踪功能，开启 GPS 定位和计时。",
        categoryName: "遛狗"
    )
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let walkingService = WalkingService.shared
        
        let status = walkingService.getWalkStatus()
        if status.isWalking {
            return .result(
                value: status.aiSummary,
                dialog: "\(status.aiSummary)"
            )
        }
        
        let response = walkingService.startWalk()
        return .result(
            value: WalkingService.toJSON(response) ?? response.aiSummary,
            dialog: "\(response.aiSummary)"
        )
    }
}

// MARK: - 结束遛狗 Intent

struct StopWalkIntent: AppIntent {
    static var title: LocalizedStringResource = "结束遛狗"
    static var description = IntentDescription(
        "结束当前遛狗会话，保存记录并计算奖励。",
        categoryName: "遛狗"
    )
    
    @Parameter(title: "心情")
    var mood: String?
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let walkingService = WalkingService.shared
        
        let status = walkingService.getWalkStatus()
        if !status.isWalking {
            let msg = "当前没有在遛狗，无需结束。"
            return .result(value: msg, dialog: "当前没有在遛狗，无需结束。")
        }
        
        let request = StopWalkRequest(mood: mood ?? "happy")
        let response = walkingService.stopWalk(request: request)
        return .result(
            value: WalkingService.toJSON(response) ?? response.aiSummary,
            dialog: "\(response.aiSummary)"
        )
    }
}

// MARK: - 查看遛狗状态 Intent

struct GetWalkStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "遛狗状态"
    static var description = IntentDescription(
        "查询当前是否在遛狗，以及实时距离和时长。",
        categoryName: "遛狗"
    )
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let response = WalkingService.shared.getWalkStatus()
        return .result(
            value: WalkingService.toJSON(response) ?? response.aiSummary,
            dialog: "\(response.aiSummary)"
        )
    }
}

// MARK: - 今日统计 Intent

struct GetTodayStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "今日遛狗统计"
    static var description = IntentDescription(
        "获取今天的遛狗总距离、次数和目标完成进度。",
        categoryName: "遛狗"
    )
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let response = WalkingService.shared.getTodayStats()
        return .result(
            value: WalkingService.toJSON(response) ?? response.aiSummary,
            dialog: "\(response.aiSummary)"
        )
    }
}

// MARK: - 查看今日日记 Intent

struct GetTodayDiaryIntent: AppIntent {
    static var title: LocalizedStringResource = "查看今日日记"
    static var description = IntentDescription(
        "查看今天的遛狗日记，由 AI 以宠物第一人称视角生成。",
        categoryName: "日记"
    )
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let response = DiaryService.shared.getTodayDiaries()
        
        var dialogText = response.aiSummary
        if let firstDiary = response.diaries.first, response.hasDiary {
            dialogText = firstDiary.diaryText
        }
        
        return .result(
            value: WalkingService.toJSON(response) ?? response.aiSummary,
            dialog: "\(dialogText)"
        )
    }
}

// MARK: - 生成 AI 日记 Intent

struct GenerateDiaryIntent: AppIntent {
    static var title: LocalizedStringResource = "生成遛狗日记"
    static var description = IntentDescription(
        "调用 AI 以宠物视角为最近一次遛狗生成日记。",
        categoryName: "日记"
    )
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let dataManager = DataManager.shared
        
        // 找到今天最近一条没有日记的记录
        let calendar = Calendar.current
        let today = Date()
        let recentRecord = dataManager.records.first { record in
            guard let ts = record.timestamp else { return false }
            return calendar.isDate(ts, inSameDayAs: today) && record.aiDiary == nil
        }
        
        let request = GenerateDiaryRequest(
            walkRecordId: recentRecord?.id.uuidString,
            distanceKm: recentRecord?.distance,
            durationMinutes: recentRecord?.duration,
            weatherCondition: nil,
            weatherTemperature: nil,
            specialEvents: nil
        )
        
        let response = await DiaryService.shared.generateDiary(request: request)
        
        let dialogText = response.success ? response.diaryText : response.aiSummary
        return .result(
            value: WalkingService.toJSON(response) ?? response.aiSummary,
            dialog: "\(String(dialogText.prefix(300)))"
        )
    }
}

// MARK: - 成就总览 Intent

struct GetAchievementOverviewIntent: AppIntent {
    static var title: LocalizedStringResource = "成就完成度"
    static var description = IntentDescription(
        "查看成就系统的整体进度、各类别完成度和骨头币余额。",
        categoryName: "成就"
    )
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let response = AchievementService.shared.getOverview()
        return .result(
            value: WalkingService.toJSON(response) ?? response.aiSummary,
            dialog: "\(response.aiSummary)"
        )
    }
}

// MARK: - 最近完成的成就 Intent

struct GetRecentAchievementsIntent: AppIntent {
    static var title: LocalizedStringResource = "最近完成的成就"
    static var description = IntentDescription(
        "查看最近解锁的成就列表。AI Agent 应在用户问'最近完成了什么成就'时调用。",
        categoryName: "成就"
    )
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let response = AchievementService.shared.getRecentlyUnlocked()
        return .result(
            value: WalkingService.toJSON(response) ?? response.aiSummary,
            dialog: "\(response.aiSummary)"
        )
    }
}

// MARK: - 成就建议 Intent

struct GetAchievementSuggestionsIntent: AppIntent {
    static var title: LocalizedStringResource = "今天可能完成的成就"
    static var description = IntentDescription(
        "根据当前天气、时间和用户进度，推荐最可能完成的成就。",
        categoryName: "成就"
    )
    
    @Parameter(title: "天气状况")
    var weatherCondition: String?
    
    @Parameter(title: "温度(°C)")
    var temperature: Double?
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let weather: WeatherSuggestionRequest?
        if weatherCondition != nil || temperature != nil {
            weather = WeatherSuggestionRequest(condition: weatherCondition, temperature: temperature)
        } else {
            weather = nil
        }
        
        let response = AchievementService.shared.getSuggestions(weather: weather)
        return .result(
            value: WalkingService.toJSON(response) ?? response.aiSummary,
            dialog: "\(response.aiSummary)"
        )
    }
}

// MARK: - App Shortcuts Provider

struct PetWalkShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: StartWalkIntent(),
                phrases: [
                    "用 \(.applicationName) 开始遛狗",
                    "用 \(.applicationName) 带狗狗出门",
                    "在 \(.applicationName) 开始散步"
                ],
                shortTitle: "开始遛狗",
                systemImageName: "pawprint.fill"
            ),
            AppShortcut(
                intent: GetTodayDiaryIntent(),
                phrases: [
                    "用 \(.applicationName) 看今天的日记",
                    "用 \(.applicationName) 看狗狗今天说了什么",
                    "在 \(.applicationName) 查看遛狗日记"
                ],
                shortTitle: "查看日记",
                systemImageName: "text.book.closed.fill"
            ),
            AppShortcut(
                intent: GetTodayStatsIntent(),
                phrases: [
                    "用 \(.applicationName) 看今天的遛狗数据",
                    "用 \(.applicationName) 看今天遛了多远"
                ],
                shortTitle: "今日统计",
                systemImageName: "chart.bar.fill"
            ),
            AppShortcut(
                intent: GetAchievementOverviewIntent(),
                phrases: [
                    "用 \(.applicationName) 看成就进度",
                    "用 \(.applicationName) 查看成就完成度"
                ],
                shortTitle: "成就进度",
                systemImageName: "trophy.fill"
            ),
            AppShortcut(
                intent: GetAchievementSuggestionsIntent(),
                phrases: [
                    "用 \(.applicationName) 今天能完成什么成就",
                    "用 \(.applicationName) 推荐成就"
                ],
                shortTitle: "成就建议",
                systemImageName: "lightbulb.fill"
            )
        ]
    }
}
