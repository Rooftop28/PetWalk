//
//  SupabaseLeaderboardManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/2/2.
//

import Foundation
import Supabase
import GameKit

// MARK: - 排行榜条目（Supabase 版）
struct SupabaseLeaderboardEntry: Identifiable, Codable {
    let id: String
    let userId: String
    let nickname: String?
    let avatarUrl: String?
    let region: String?
    let totalDistance: Double
    let totalWalks: Int
    var rank: Int
    var isCurrentPlayer: Bool = false
    
    // 用于从 Supabase 解码
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname
        case avatarUrl = "avatar_url"
        case region
        case totalDistance = "total_distance"
        case totalWalks = "total_walks"
        case rank = "global_rank"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        self.avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        self.region = try container.decodeIfPresent(String.self, forKey: .region)
        self.totalDistance = try container.decodeIfPresent(Double.self, forKey: .totalDistance) ?? 0
        self.totalWalks = try container.decodeIfPresent(Int.self, forKey: .totalWalks) ?? 0
        self.rank = try container.decodeIfPresent(Int.self, forKey: .rank) ?? 0
        self.id = userId
    }
    
    init(userId: String, nickname: String?, avatarUrl: String?, region: String?, totalDistance: Double, totalWalks: Int, rank: Int, isCurrentPlayer: Bool = false) {
        self.id = userId
        self.userId = userId
        self.nickname = nickname
        self.avatarUrl = avatarUrl
        self.region = region
        self.totalDistance = totalDistance
        self.totalWalks = totalWalks
        self.rank = rank
        self.isCurrentPlayer = isCurrentPlayer
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(nickname, forKey: .nickname)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try container.encodeIfPresent(region, forKey: .region)
        try container.encode(totalDistance, forKey: .totalDistance)
        try container.encode(totalWalks, forKey: .totalWalks)
    }
    
    // 显示名称
    var displayName: String {
        nickname ?? "匿名遛狗人"
    }
    
    // 格式化距离
    var formattedDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.1fk km", totalDistance / 1000)
        } else if totalDistance >= 100 {
            return String(format: "%.0f km", totalDistance)
        } else {
            return String(format: "%.1f km", totalDistance)
        }
    }
}

// MARK: - 同城区域数据
struct RegionLeaderboardEntry: Codable {
    let userId: String
    let nickname: String?
    let avatarUrl: String?
    let region: String?
    let totalDistance: Double
    let totalWalks: Int
    let regionalRank: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname
        case avatarUrl = "avatar_url"
        case region
        case totalDistance = "total_distance"
        case totalWalks = "total_walks"
        case regionalRank = "regional_rank"
    }
}

// MARK: - 排行榜类型
enum SupabaseLeaderboardType: String, CaseIterable {
    case global = "global"
    case city = "city"
    case friends = "friends"
    
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
}

// MARK: - Supabase 排行榜管理器
@MainActor
class SupabaseLeaderboardManager: ObservableObject {
    // MARK: - 单例
    static let shared = SupabaseLeaderboardManager()
    
    // MARK: - Supabase 客户端
    private let supabase: SupabaseClient
    
    // MARK: - 发布的属性
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var globalLeaderboard: [SupabaseLeaderboardEntry] = []
    @Published var cityLeaderboard: [SupabaseLeaderboardEntry] = []
    @Published var friendsLeaderboard: [SupabaseLeaderboardEntry] = []
    
    @Published var currentPlayerGlobalRank: Int?
    @Published var currentPlayerCityRank: Int?
    @Published var currentUserRegion: String?
    
    // MARK: - 初始化
    private init() {
        self.supabase = SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.apiKey
        )
    }
    
    // MARK: - 获取当前用户 ID
    private var currentUserId: String? {
        GKLocalPlayer.local.isAuthenticated ? GKLocalPlayer.local.gamePlayerID : nil
    }
    
    // MARK: - 加载所有排行榜
    func loadAllLeaderboards() async {
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadGlobalLeaderboard() }
            group.addTask { await self.loadCityLeaderboard() }
        }
        
        isLoading = false
    }
    
    // MARK: - 加载全球排行榜
    func loadGlobalLeaderboard() async {
        do {
            let entries: [SupabaseLeaderboardEntry] = try await supabase
                .from("leaderboard_distance")
                .select()
                .order("global_rank", ascending: true)
                .limit(100)
                .execute()
                .value
            
            // 标记当前玩家
            var updatedEntries = entries
            if let userId = currentUserId {
                for i in 0..<updatedEntries.count {
                    if updatedEntries[i].userId == userId {
                        updatedEntries[i].isCurrentPlayer = true
                        currentPlayerGlobalRank = updatedEntries[i].rank
                    }
                }
            }
            
            globalLeaderboard = updatedEntries
            print("SupabaseLeaderboard: 加载全球榜成功 - \(entries.count) 条")
        } catch {
            print("SupabaseLeaderboard: 加载全球榜失败 - \(error)")
            errorMessage = "加载排行榜失败"
        }
    }
    
    // MARK: - 加载同城排行榜
    func loadCityLeaderboard() async {
        // 首先获取当前用户的地区
        guard let userId = currentUserId else {
            print("SupabaseLeaderboard: 未登录，无法加载同城榜")
            return
        }
        
        do {
            // 获取当前用户的 region
            let profile: [ProfileRegion] = try await supabase
                .from("profiles")
                .select("region")
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value
            
            guard let region = profile.first?.region, !region.isEmpty else {
                print("SupabaseLeaderboard: 用户未设置地区")
                // 加载所有有地区的用户（按地区分组显示前几名）
                await loadAllRegionsLeaderboard()
                return
            }
            
            currentUserRegion = region
            
            // 加载同城排行榜
            let entries: [RegionLeaderboardEntry] = try await supabase
                .from("leaderboard_by_region")
                .select()
                .eq("region", value: region)
                .order("regional_rank", ascending: true)
                .limit(100)
                .execute()
                .value
            
            // 转换为通用格式
            var leaderboard: [SupabaseLeaderboardEntry] = []
            for entry in entries {
                var item = SupabaseLeaderboardEntry(
                    userId: entry.userId,
                    nickname: entry.nickname,
                    avatarUrl: entry.avatarUrl,
                    region: entry.region,
                    totalDistance: entry.totalDistance,
                    totalWalks: entry.totalWalks,
                    rank: entry.regionalRank
                )
                if entry.userId == userId {
                    item.isCurrentPlayer = true
                    currentPlayerCityRank = entry.regionalRank
                }
                leaderboard.append(item)
            }
            
            cityLeaderboard = leaderboard
            print("SupabaseLeaderboard: 加载同城榜成功 (\(region)) - \(entries.count) 条")
        } catch {
            print("SupabaseLeaderboard: 加载同城榜失败 - \(error)")
        }
    }
    
    // MARK: - 加载所有地区的排行榜（当用户未设置地区时）
    private func loadAllRegionsLeaderboard() async {
        do {
            let entries: [RegionLeaderboardEntry] = try await supabase
                .from("leaderboard_by_region")
                .select()
                .order("total_distance", ascending: false)
                .limit(100)
                .execute()
                .value
            
            var leaderboard: [SupabaseLeaderboardEntry] = []
            var rank = 1
            for entry in entries {
                var item = SupabaseLeaderboardEntry(
                    userId: entry.userId,
                    nickname: entry.nickname,
                    avatarUrl: entry.avatarUrl,
                    region: entry.region,
                    totalDistance: entry.totalDistance,
                    totalWalks: entry.totalWalks,
                    rank: rank
                )
                if entry.userId == currentUserId {
                    item.isCurrentPlayer = true
                }
                leaderboard.append(item)
                rank += 1
            }
            
            cityLeaderboard = leaderboard
        } catch {
            print("SupabaseLeaderboard: 加载地区榜失败 - \(error)")
        }
    }
    
    // MARK: - 加载好友排行榜
    /// 注意：真正的好友功能需要 Game Center 好友列表或自建好友系统
    /// 这里暂时显示为空或显示提示
    func loadFriendsLeaderboard() async {
        // Game Center 好友功能需要额外权限
        // 暂时使用模拟数据或显示为空
        friendsLeaderboard = []
        print("SupabaseLeaderboard: 好友榜需要 Game Center 好友功能支持")
    }
    
    // MARK: - 提交/更新用户数据
    func submitUserData(totalDistance: Double, totalWalks: Int, region: String? = nil) async {
        guard let userId = currentUserId else {
            print("SupabaseLeaderboard: 未登录，无法提交数据")
            return
        }
        
        do {
            // 更新 user_achievements
            let achievementData = UserAchievementUpsert(
                userId: userId,
                totalDistance: totalDistance,
                totalWalks: totalWalks
            )
            try await supabase
                .from("user_achievements")
                .upsert(achievementData)
                .execute()
            
            // 更新 profiles
            let displayName = GKLocalPlayer.local.displayName
            let profileData = ProfileUpsert(
                userId: userId,
                nickname: displayName,
                totalDistance: totalDistance,
                totalWalks: totalWalks,
                region: region
            )
            try await supabase
                .from("profiles")
                .upsert(profileData)
                .execute()
            
            print("SupabaseLeaderboard: 提交数据成功 - \(totalDistance) km, \(totalWalks) 次")
            
            // 刷新排行榜
            await loadAllLeaderboards()
        } catch {
            print("SupabaseLeaderboard: 提交数据失败 - \(error)")
        }
    }
    
    // MARK: - 更新用户地区
    func updateUserRegion(_ region: String) async {
        guard let userId = currentUserId else { return }
        
        do {
            let updateData = RegionUpdate(region: region)
            try await supabase
                .from("profiles")
                .update(updateData)
                .eq("user_id", value: userId)
                .execute()
            
            currentUserRegion = region
            print("SupabaseLeaderboard: 更新地区成功 - \(region)")
            
            // 刷新同城榜
            await loadCityLeaderboard()
        } catch {
            print("SupabaseLeaderboard: 更新地区失败 - \(error)")
        }
    }
    
    // MARK: - 初始化用户 Profile
    func initializeUserProfile() async {
        guard let userId = currentUserId else { return }
        
        let displayName = GKLocalPlayer.local.displayName
        let userData = DataManager.shared.userData
        
        do {
            // 先确保 user_achievements 存在
            let achievementData = UserAchievementUpsertFull(
                userId: userId,
                totalDistance: userData.totalDistance,
                totalWalks: userData.totalWalks,
                totalBones: userData.totalBones
            )
            try await supabase
                .from("user_achievements")
                .upsert(achievementData)
                .execute()
            
            // 然后更新 profile
            let profileData = ProfileUpsert(
                userId: userId,
                nickname: displayName,
                totalDistance: userData.totalDistance,
                totalWalks: userData.totalWalks,
                region: nil
            )
            try await supabase
                .from("profiles")
                .upsert(profileData)
                .execute()
            
            print("SupabaseLeaderboard: 用户 Profile 初始化成功")
        } catch {
            print("SupabaseLeaderboard: 用户 Profile 初始化失败 - \(error)")
        }
    }
}

// MARK: - 辅助结构体（用于 Supabase upsert/update）
private struct ProfileRegion: Codable {
    let region: String?
}

private struct UserAchievementUpsert: Encodable {
    let userId: String
    let totalDistance: Double
    let totalWalks: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case totalDistance = "total_distance"
        case totalWalks = "total_walks"
    }
}

private struct UserAchievementUpsertFull: Encodable {
    let userId: String
    let totalDistance: Double
    let totalWalks: Int
    let totalBones: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case totalDistance = "total_distance"
        case totalWalks = "total_walks"
        case totalBones = "total_bones"
    }
}

private struct ProfileUpsert: Encodable {
    let userId: String
    let nickname: String
    let totalDistance: Double
    let totalWalks: Int
    let region: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname
        case totalDistance = "total_distance"
        case totalWalks = "total_walks"
        case region
    }
}

private struct RegionUpdate: Encodable {
    let region: String
}
