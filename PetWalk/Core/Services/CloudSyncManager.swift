//
//  CloudSyncManager.swift
//  PetWalk
//
//  Created by Cursor AI Assistant on 2026/02/02.
//
//  云同步管理器：将成就和用户数据同步至 Supabase
//

import Foundation
import Supabase
import GameKit

// MARK: - 云端数据模型

/// 云端用户数据结构（对应 Supabase 表结构）
struct CloudUserData: Codable {
    let userId: String                      // Game Center Player ID
    var unlockedAchievements: [String]      // 已解锁成就 ID 数组
    var revealedHints: [String]             // 已揭示线索的成就 ID 数组
    var totalBones: Int                     // 骨头币
    var totalWalks: Int                     // 总遛狗次数
    var totalDistance: Double               // 总里程
    var currentStreak: Int                  // 当前连续打卡
    var maxStreak: Int                      // 历史最高连续打卡
    var ownedTitleIds: [String]             // 已拥有称号
    var ownedThemeIds: [String]             // 已拥有主题
    var equippedTitleId: String             // 当前装备称号
    var equippedThemeId: String             // 当前装备主题
    var updatedAt: String                   // 最后更新时间 (ISO8601)
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case unlockedAchievements = "unlocked_achievements"
        case revealedHints = "revealed_hints"
        case totalBones = "total_bones"
        case totalWalks = "total_walks"
        case totalDistance = "total_distance"
        case currentStreak = "current_streak"
        case maxStreak = "max_streak"
        case ownedTitleIds = "owned_title_ids"
        case ownedThemeIds = "owned_theme_ids"
        case equippedTitleId = "equipped_title_id"
        case equippedThemeId = "equipped_theme_id"
        case updatedAt = "updated_at"
    }
}

// MARK: - 同步状态

enum SyncStatus: Equatable {
    case idle
    case syncing
    case success
    case failed(String)
}

// MARK: - Cloud Sync Manager

@MainActor
class CloudSyncManager: ObservableObject {
    // MARK: - 单例
    static let shared = CloudSyncManager()
    
    // MARK: - 发布属性
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var isEnabled: Bool = true
    
    // MARK: - 私有属性
    private var client: SupabaseClient?
    private let tableName = "user_achievements"
    
    // 防止频繁同步的节流
    private var lastSyncAttempt: Date?
    private let minSyncInterval: TimeInterval = 5.0 // 最小同步间隔（秒）
    
    // MARK: - 初始化
    
    private init() {
        setupClient()
    }
    
    private func setupClient() {
        guard SupabaseConfig.isValid else {
            print("⚠️ CloudSyncManager: Supabase 配置无效，云同步已禁用")
            isEnabled = false
            return
        }
        
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.apiKey
        )
    }
    
    // MARK: - 获取用户 ID
    
    /// 获取 Game Center Player ID 作为用户标识
    private func getUserId() -> String? {
        let localPlayer = GKLocalPlayer.local
        guard localPlayer.isAuthenticated else {
            print("⚠️ CloudSyncManager: Game Center 未认证，无法同步")
            return nil
        }
        return localPlayer.gamePlayerID
    }
    
    // MARK: - 公开方法
    
    /// 上传本地数据到云端
    func uploadToCloud() async {
        guard isEnabled, let client = client else { return }
        guard let userId = getUserId() else {
            syncStatus = .failed("请先登录 Game Center")
            return
        }
        
        // 节流检查
        if let lastAttempt = lastSyncAttempt,
           Date().timeIntervalSince(lastAttempt) < minSyncInterval {
            return
        }
        lastSyncAttempt = Date()
        
        syncStatus = .syncing
        
        let userData = DataManager.shared.userData
        let cloudData = CloudUserData(
            userId: userId,
            unlockedAchievements: Array(userData.unlockedAchievements),
            revealedHints: Array(userData.revealedAchievementHints),
            totalBones: userData.totalBones,
            totalWalks: userData.totalWalks,
            totalDistance: userData.totalDistance,
            currentStreak: userData.currentStreak,
            maxStreak: userData.maxStreak,
            ownedTitleIds: Array(userData.ownedTitleIds),
            ownedThemeIds: Array(userData.ownedThemeIds),
            equippedTitleId: userData.equippedTitleId,
            equippedThemeId: userData.equippedThemeId,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            // Upsert: 存在则更新，不存在则插入
            try await client
                .from(tableName)
                .upsert(cloudData, onConflict: "user_id")
                .execute()
            
            lastSyncTime = Date()
            syncStatus = .success
            print("☁️ CloudSyncManager: 数据上传成功")
        } catch {
            syncStatus = .failed(error.localizedDescription)
            print("❌ CloudSyncManager: 上传失败 - \(error)")
        }
    }
    
    /// 从云端下载数据并合并到本地
    func downloadFromCloud() async {
        guard isEnabled, let client = client else { return }
        guard let userId = getUserId() else {
            syncStatus = .failed("请先登录 Game Center")
            return
        }
        
        syncStatus = .syncing
        
        do {
            let response: [CloudUserData] = try await client
                .from(tableName)
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            guard let cloudData = response.first else {
                // 云端没有数据，上传本地数据
                print("☁️ CloudSyncManager: 云端无数据，将上传本地数据")
                await uploadToCloud()
                return
            }
            
            // 合并数据（采用"并集"策略：保留更多的成就）
            await mergeCloudData(cloudData)
            
            lastSyncTime = Date()
            syncStatus = .success
            print("☁️ CloudSyncManager: 数据下载并合并成功")
        } catch {
            syncStatus = .failed(error.localizedDescription)
            print("❌ CloudSyncManager: 下载失败 - \(error)")
        }
    }
    
    /// 双向同步（先拉取合并，再上传）
    func sync() async {
        guard isEnabled else { return }
        
        // 先下载合并
        await downloadFromCloud()
        
        // 如果下载成功，再上传最新状态
        if case .success = syncStatus {
            await uploadToCloud()
        }
    }
    
    /// 当成就解锁时触发同步
    func onAchievementUnlocked(_ achievementId: String) {
        Task {
            await uploadToCloud()
        }
    }
    
    // MARK: - 私有方法
    
    /// 合并云端数据到本地（并集策略）
    private func mergeCloudData(_ cloudData: CloudUserData) async {
        var userData = DataManager.shared.userData
        
        // 成就：取并集（本地 + 云端）
        let mergedAchievements = userData.unlockedAchievements.union(Set(cloudData.unlockedAchievements))
        userData.unlockedAchievements = mergedAchievements
        
        // 揭示的线索：取并集
        let mergedHints = userData.revealedAchievementHints.union(Set(cloudData.revealedHints))
        userData.revealedAchievementHints = mergedHints
        
        // 拥有的称号/主题：取并集
        userData.ownedTitleIds = userData.ownedTitleIds.union(Set(cloudData.ownedTitleIds))
        userData.ownedThemeIds = userData.ownedThemeIds.union(Set(cloudData.ownedThemeIds))
        
        // 数值类：取最大值
        userData.totalBones = max(userData.totalBones, cloudData.totalBones)
        userData.totalWalks = max(userData.totalWalks, cloudData.totalWalks)
        userData.totalDistance = max(userData.totalDistance, cloudData.totalDistance)
        userData.currentStreak = max(userData.currentStreak, cloudData.currentStreak)
        userData.maxStreak = max(userData.maxStreak, cloudData.maxStreak)
        
        // 装备类：如果本地是默认值而云端不是，使用云端的
        if userData.equippedTitleId == "title_default" && cloudData.equippedTitleId != "title_default" {
            userData.equippedTitleId = cloudData.equippedTitleId
        }
        if userData.equippedThemeId == "theme_default" && cloudData.equippedThemeId != "theme_default" {
            userData.equippedThemeId = cloudData.equippedThemeId
        }
        
        // 保存合并后的数据
        DataManager.shared.updateUserData(userData)
        
        print("☁️ CloudSyncManager: 合并完成 - 成就 \(mergedAchievements.count) 个, 骨头币 \(userData.totalBones)")
    }
}
