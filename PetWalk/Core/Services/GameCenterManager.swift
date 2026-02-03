//
//  GameCenterManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import GameKit
import SwiftUI

// MARK: - 排行榜类型
enum LeaderboardType: String, CaseIterable {
    case global = "petwalk.leaderboard.global"         // 全球榜
    case city = "petwalk.leaderboard.city"             // 同城榜
    case friends = "petwalk.leaderboard.friends"       // 好友榜
    
    var displayName: String {
        switch self {
        case .global: return "全球排行"
        case .city: return "同城排行"
        case .friends: return "好友排行"
        }
    }
    
    var iconSymbol: String {
        switch self {
        case .global: return "globe"
        case .city: return "building.2.fill"
        case .friends: return "person.3.fill"
        }
    }
    
    // Game Center 排行榜范围
    var playerScope: GKLeaderboard.PlayerScope {
        switch self {
        case .global: return .global
        case .city: return .global  // 城市需要特殊处理
        case .friends: return .friendsOnly
        }
    }
}

// MARK: - 排行榜条目
struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let playerName: String
    let score: Int
    let isCurrentPlayer: Bool
    let avatarImage: UIImage?
    let gameCenterID: String?
    
    // 城市信息（用于同城榜）
    var city: String?
}

// MARK: - 成就统计
struct AchievementStats {
    let achievementID: String
    let unlockPercentage: Double  // 全球解锁百分比
    let firstUnlockDate: Date?    // 首杀时间
    let firstUnlockPlayer: String? // 首杀玩家
    let totalUnlocks: Int         // 总解锁人数
}

// MARK: - Game Center 管理器
@MainActor
class GameCenterManager: NSObject, ObservableObject {
    // MARK: - 单例
    static let shared = GameCenterManager()
    
    // MARK: - 发布的属性
    @Published var isAuthenticated: Bool = false
    @Published var localPlayer: GKLocalPlayer?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var needsSystemLogin: Bool = false  // 需要去系统设置登录
    
    // 缓存的排行榜数据
    @Published var globalLeaderboard: [LeaderboardEntry] = []
    @Published var friendsLeaderboard: [LeaderboardEntry] = []
    @Published var cityLeaderboard: [LeaderboardEntry] = []
    
    // 成就稀有度缓存
    @Published var achievementRarities: [String: Double] = [:]  // achievementID -> unlockPercentage
    
    // 当前玩家排名
    @Published var currentPlayerGlobalRank: Int?
    @Published var currentPlayerFriendsRank: Int?
    
    // MARK: - 初始化
    private override init() {
        super.init()
    }
    
    // MARK: - 认证
    
    private var hasSetupAuthHandler = false
    
    /// 认证 Game Center
    func authenticate() {
        let player = GKLocalPlayer.local
        
        // 如果已经认证，直接返回
        if player.isAuthenticated {
            print("GameCenter: 已经认证 - \(player.displayName)")
            self.isAuthenticated = true
            self.localPlayer = player
            self.needsSystemLogin = false
            self.errorMessage = nil
            
            Task {
                await self.loadLeaderboards()
                await self.loadAchievementRarities()
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        needsSystemLogin = false
        
        // authenticateHandler 只能设置一次，之后会自动触发
        // 如果已经设置过，需要检查当前状态
        if hasSetupAuthHandler {
            print("GameCenter: Handler 已设置，检查当前状态")
            isLoading = false
            
            if !player.isAuthenticated {
                // 玩家未认证，需要引导去设置
                needsSystemLogin = true
                print("GameCenter: 用户需要在系统设置中登录")
            }
            return
        }
        
        hasSetupAuthHandler = true
        print("GameCenter: 设置认证 Handler")
        
        player.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                self?.isLoading = false
                
                if let error = error {
                    let nsError = error as NSError
                    self?.isAuthenticated = false
                    
                    print("GameCenter: 认证失败 - domain: \(nsError.domain), code: \(nsError.code), \(error.localizedDescription)")
                    
                    if nsError.domain == GKErrorDomain {
                        switch nsError.code {
                        case 2:
                            self?.errorMessage = "登录已取消"
                            print("GameCenter: 用户取消了登录")
                        case 3, 6:
                            self?.needsSystemLogin = true
                            self?.errorMessage = nil
                            print("GameCenter: 需要在系统设置中登录 Game Center")
                        default:
                            self?.errorMessage = error.localizedDescription
                        }
                    } else {
                        if error.localizedDescription.contains("not been authenticated") ||
                           error.localizedDescription.contains("未认证") {
                            self?.needsSystemLogin = true
                            self?.errorMessage = nil
                        } else {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                    return
                }
                
                if let viewController = viewController {
                    print("GameCenter: 显示登录界面")
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        var topVC = rootVC
                        while let presented = topVC.presentedViewController {
                            topVC = presented
                        }
                        topVC.present(viewController, animated: true)
                    }
                    return
                }
                
                // 检查认证状态
                self?.isAuthenticated = player.isAuthenticated
                self?.localPlayer = player
                
                if player.isAuthenticated {
                    print("GameCenter: 认证成功 - \(player.displayName)")
                    self?.needsSystemLogin = false
                    self?.errorMessage = nil
                    
                    await self?.loadLeaderboards()
                    await self?.loadAchievementRarities()
                } else {
                    self?.needsSystemLogin = true
                    print("GameCenter: 用户未登录，需要在系统设置中登录")
                }
            }
        }
    }
    
    /// 打开系统设置
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - 排行榜
    
    /// 加载所有排行榜
    func loadLeaderboards() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadLeaderboard(type: .global)
            }
            group.addTask {
                await self.loadLeaderboard(type: .friends)
            }
        }
        
        isLoading = false
    }
    
    /// 加载指定类型的排行榜
    func loadLeaderboard(type: LeaderboardType) async {
        guard isAuthenticated else { return }
        
        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [type.rawValue])
            guard let leaderboard = leaderboards.first else { return }
            
            let (localPlayerEntry, entries, _) = try await leaderboard.loadEntries(
                for: type.playerScope,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 100)
            )
            
            var leaderboardEntries: [LeaderboardEntry] = []
            
            for entry in entries {
                let avatarImage = try? await entry.player.loadPhoto(for: .small)
                
                let leaderboardEntry = LeaderboardEntry(
                    rank: entry.rank,
                    playerName: entry.player.displayName,
                    score: entry.score,
                    isCurrentPlayer: entry.player == GKLocalPlayer.local,
                    avatarImage: avatarImage,
                    gameCenterID: entry.player.gamePlayerID
                )
                leaderboardEntries.append(leaderboardEntry)
            }
            
            // 更新对应的排行榜
            switch type {
            case .global:
                self.globalLeaderboard = leaderboardEntries
                if let localEntry = localPlayerEntry {
                    self.currentPlayerGlobalRank = localEntry.rank
                }
            case .friends:
                self.friendsLeaderboard = leaderboardEntries
                if let localEntry = localPlayerEntry {
                    self.currentPlayerFriendsRank = localEntry.rank
                }
            case .city:
                // 城市排行需要特殊处理（基于位置过滤）
                self.cityLeaderboard = leaderboardEntries
            }
            
        } catch {
            print("GameCenter: 加载排行榜失败 (\(type.displayName)) - \(error)")
        }
    }
    
    /// 提交分数到排行榜
    func submitScore(_ score: Int, leaderboardID: String = LeaderboardType.global.rawValue) async {
        guard isAuthenticated else {
            print("GameCenter: 未认证，无法提交分数")
            return
        }
        
        do {
            try await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
            print("GameCenter: 分数提交成功 - \(score)")
            
            // 刷新排行榜
            await loadLeaderboards()
        } catch {
            print("GameCenter: 提交分数失败 - \(error)")
        }
    }
    
    /// 提交遛狗数据到排行榜
    func submitWalkData(totalDistance: Double, totalWalks: Int) async {
        // 全球榜：累计里程（米）
        let distanceScore = Int(totalDistance * 1000)
        await submitScore(distanceScore, leaderboardID: LeaderboardType.global.rawValue)
    }
    
    // MARK: - 成就
    
    /// 报告成就
    func reportAchievement(_ achievementID: String, percentComplete: Double = 100.0) async {
        guard isAuthenticated else { return }
        
        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        
        do {
            try await GKAchievement.report([achievement])
            print("GameCenter: 成就报告成功 - \(achievementID)")
        } catch {
            print("GameCenter: 成就报告失败 - \(error)")
        }
    }
    
    /// 加载成就稀有度（全球解锁百分比）
    func loadAchievementRarities() async {
        guard isAuthenticated else { return }
        
        do {
            let descriptions = try await GKAchievementDescription.loadAchievementDescriptions()
            let achievements = try await GKAchievement.loadAchievements()
            
            // 这里 Game Center 不直接提供稀有度数据
            // 我们需要通过自己的后端或估算来实现
            // 暂时使用固定值作为示例
            for desc in descriptions {
                // 根据成就难度预估稀有度
                let rarity = estimateRarity(for: desc.identifier)
                achievementRarities[desc.identifier] = rarity
            }
            
            print("GameCenter: 加载成就稀有度完成 - \(achievementRarities.count) 个")
        } catch {
            print("GameCenter: 加载成就稀有度失败 - \(error)")
        }
    }
    
    /// 估算成就稀有度
    private func estimateRarity(for achievementID: String) -> Double {
        // 根据成就 ID 估算稀有度
        // 实际应用中应该从服务器获取真实数据
        
        if achievementID.contains("1000") || achievementID.contains("legendary") {
            return 0.5  // 0.5% - 传说级
        } else if achievementID.contains("100") || achievementID.contains("epic") {
            return 5.0  // 5% - 史诗级
        } else if achievementID.contains("50") || achievementID.contains("rare") {
            return 15.0 // 15% - 稀有
        } else {
            return 50.0 // 50% - 普通
        }
    }
    
    /// 获取成就稀有度
    func getAchievementRarity(_ achievementID: String) -> AchievementRarity {
        let percentage = achievementRarities[achievementID] ?? 50.0
        
        if percentage < 1 {
            return .legendary
        } else if percentage < 10 {
            return .epic
        } else if percentage < 50 {
            return .rare
        } else {
            return .common
        }
    }
    
    // MARK: - 显示 Game Center UI
    
    /// 显示 Game Center 排行榜 UI
    func showLeaderboard() {
        guard isAuthenticated else {
            authenticate()
            return
        }
        
        let viewController = GKGameCenterViewController(state: .leaderboards)
        viewController.gameCenterDelegate = self
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(viewController, animated: true)
        }
    }
    
    /// 显示 Game Center 成就 UI
    func showAchievements() {
        guard isAuthenticated else {
            authenticate()
            return
        }
        
        let viewController = GKGameCenterViewController(state: .achievements)
        viewController.gameCenterDelegate = self
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(viewController, animated: true)
        }
    }
    
    /// 显示 Game Center 主界面
    func showGameCenter() {
        guard isAuthenticated else {
            authenticate()
            return
        }
        
        let viewController = GKGameCenterViewController(state: .default)
        viewController.gameCenterDelegate = self
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(viewController, animated: true)
        }
    }
}

// MARK: - GKGameCenterControllerDelegate
extension GameCenterManager: GKGameCenterControllerDelegate {
    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }
}

// MARK: - 首杀榜（Hall of Fame）
extension GameCenterManager {
    /// 首杀榜条目
    struct HallOfFameEntry: Identifiable {
        let id = UUID()
        let achievementID: String
        let achievementName: String
        let playerName: String
        let unlockDate: Date
    }
    
    /// 获取首杀榜数据
    /// 注意：这需要后端支持，Game Center 不直接提供此功能
    func getHallOfFame() async -> [HallOfFameEntry] {
        // 这里需要连接到自己的后端服务获取首杀数据
        // 暂时返回空数组，后续可扩展
        return []
    }
    
    /// 报告首杀（当用户解锁成就时调用）
    func reportFirstUnlock(achievementID: String, playerName: String) async {
        // 这里需要连接到自己的后端服务记录首杀
        // 暂时只打印日志
        print("GameCenter: 首杀报告 - \(achievementID) by \(playerName)")
    }
}
