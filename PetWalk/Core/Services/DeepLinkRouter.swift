//
//  DeepLinkRouter.swift
//  PetWalk
//
//  Deep Link URL 路由 — 解析 petwalk:// URL 并导航到对应页面
//

import Foundation
import SwiftUI

/// Deep Link 目标
enum DeepLinkDestination: Equatable {
    case home
    case walkActive
    case walkSummary(recordId: String)
    case history
    case historyToday
    case historyRecord(recordId: String)
    case achievement(achievementId: String)
    case achievementList
    case diary(recordId: String?)
    case diaryToday
    case shop
    case settings
}

/// 全局 Deep Link 路由器
@MainActor
class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()
    
    @Published var pendingDestination: DeepLinkDestination?
    @Published var selectedTab: Tab = .home
    
    /// 显示成就详情的目标 ID
    @Published var targetAchievementId: String?
    
    /// 显示遛狗记录详情的目标 ID
    @Published var targetRecordId: String?
    
    private init() {}
    
    // MARK: - URL 解析
    
    /// 解析 petwalk:// URL 并返回目标
    /// - Parameter url: Deep Link URL
    /// - Returns: 解析出的目标，nil 表示 URL 不合法
    func parse(url: URL) -> DeepLinkDestination? {
        guard url.scheme == "petwalk" else { return nil }
        
        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch host {
        case "home":
            return .home
            
        case "walk":
            if pathComponents.isEmpty { return .walkActive }
            switch pathComponents[0] {
            case "active": return .walkActive
            case "summary":
                let id = pathComponents.count > 1 ? pathComponents[1] : ""
                return .walkSummary(recordId: id)
            default: return .walkActive
            }
            
        case "history":
            if pathComponents.isEmpty { return .history }
            switch pathComponents[0] {
            case "today": return .historyToday
            default: return .historyRecord(recordId: pathComponents[0])
            }
            
        case "achievement":
            if pathComponents.isEmpty { return .achievementList }
            return .achievement(achievementId: pathComponents[0])
            
        case "diary":
            if pathComponents.isEmpty { return .diary(recordId: nil) }
            switch pathComponents[0] {
            case "today": return .diaryToday
            default: return .diary(recordId: pathComponents[0])
            }
            
        case "shop":
            return .shop
            
        case "settings":
            return .settings
            
        default:
            return nil
        }
    }
    
    // MARK: - 导航执行
    
    /// 处理传入的 URL 并导航
    func handleURL(_ url: URL) {
        guard let destination = parse(url: url) else { return }
        navigate(to: destination)
    }
    
    /// 导航到指定目标
    func navigate(to destination: DeepLinkDestination) {
        switch destination {
        case .home, .walkActive:
            selectedTab = .home
            
        case .walkSummary, .history, .historyToday, .historyRecord:
            selectedTab = .history
            if case .historyRecord(let id) = destination {
                targetRecordId = id
            }
            
        case .achievement(let id):
            selectedTab = .achievement
            targetAchievementId = id
            
        case .achievementList:
            selectedTab = .achievement
            
        case .diary, .diaryToday:
            selectedTab = .history
            
        case .shop:
            selectedTab = .home
            
        case .settings:
            selectedTab = .history
        }
        
        pendingDestination = destination
    }
    
    /// 消费（清除）当前待处理的 destination
    func consumeDestination() {
        pendingDestination = nil
        targetAchievementId = nil
        targetRecordId = nil
    }
}
