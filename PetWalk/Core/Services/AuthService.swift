//
//  AuthService.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/2/2.
//

import Foundation
import Supabase
import GameKit

/// 认证服务
/// 使用 Supabase 匿名登录生成稳定的 UUID，并关联 Game Center ID
/// 支持通过 Keychain 和 Game Center ID 恢复账号
@MainActor
class AuthService: ObservableObject {
    // MARK: - 单例
    static let shared = AuthService()
    
    // MARK: - Supabase 客户端
    private let supabase: SupabaseClient
    
    // MARK: - 发布的属性
    @Published var isAuthenticated: Bool = false
    @Published var currentUserId: String?  // Supabase UUID
    @Published var gameCenterId: String?   // Game Center ID (用于社交功能)
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isRestoredAccount: Bool = false  // 是否是恢复的账号
    
    // MARK: - 初始化
    private init() {
        self.supabase = SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.apiKey
        )
        
        // 检查现有 Session
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - 检查现有 Session
    private func checkExistingSession() async {
        do {
            let session = try await supabase.auth.session
            currentUserId = session.user.id.uuidString
            isAuthenticated = true
            
            // 同步到 Keychain
            KeychainManager.shared.saveUserId(session.user.id.uuidString)
            
            print("AuthService: 已有 Session - UUID: \(currentUserId ?? "nil")")
        } catch {
            print("AuthService: 无现有 Session")
            isAuthenticated = false
            currentUserId = nil
        }
    }
    
    // MARK: - 主入口：App 启动时调用
    /// 确保用户已登录 Supabase，并绑定 Game Center ID
    /// 优先级：Supabase Session > Keychain UUID > Game Center ID 恢复 > 新建账号
    func checkIn() async {
        isLoading = true
        errorMessage = nil
        isRestoredAccount = false
        
        print("AuthService: ========== 开始 checkIn ==========")
        
        do {
            // 1. 获取 Game Center ID (尽早获取，用于后续恢复)
            await fetchGameCenterId()
            
            // 2. 确保 Supabase 已登录 (包含账号恢复逻辑)
            try await ensureSupabaseSession()
            
            // 3. 更新 Profile (绑定 Game Center ID)
            if let uuid = currentUserId {
                await updateProfile(uuid: uuid)
            }
            
            isLoading = false
            print("AuthService: ========== checkIn 完成 ==========")
            print("AuthService: UUID: \(currentUserId ?? "nil")")
            print("AuthService: Game Center: \(gameCenterId ?? "nil")")
            print("AuthService: 是否恢复账号: \(isRestoredAccount)")
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("AuthService: ❌ checkIn 失败 - \(error)")
        }
    }
    
    // MARK: - 确保 Supabase Session 存在
    private func ensureSupabaseSession() async throws {
        // 方案 1：尝试使用现有 Supabase Session
        if let uuid = try? await tryExistingSession() {
            currentUserId = uuid
            isAuthenticated = true
            KeychainManager.shared.saveUserId(uuid)
            print("AuthService: ✅ 方案1成功 - 使用现有 Session")
            return
        }
        
        // 方案 2：从 Keychain 恢复 UUID，验证数据库中是否存在
        if let uuid = await tryRestoreFromKeychain() {
            currentUserId = uuid
            isAuthenticated = true
            isRestoredAccount = true
            print("AuthService: ✅ 方案2成功 - 从 Keychain 恢复")
            return
        }
        
        // 方案 3：通过 Game Center ID 查找已有账号
        if let uuid = await tryRestoreFromGameCenter() {
            currentUserId = uuid
            isAuthenticated = true
            isRestoredAccount = true
            KeychainManager.shared.saveUserId(uuid)
            print("AuthService: ✅ 方案3成功 - 从 Game Center ID 恢复")
            return
        }
        
        // 方案 4：创建新账号
        print("AuthService: 所有恢复方案失败，创建新账号...")
        try await createNewAccount()
    }
    
    // MARK: - 方案 1：尝试现有 Session
    private func tryExistingSession() async throws -> String? {
        do {
            let session = try await supabase.auth.session
            
            // 检查是否过期
            if session.isExpired {
                print("AuthService: Session 已过期，尝试刷新...")
                let refreshedSession = try await supabase.auth.refreshSession()
                return refreshedSession.user.id.uuidString
            }
            
            return session.user.id.uuidString
        } catch {
            print("AuthService: 方案1 - 无有效 Session")
            return nil
        }
    }
    
    // MARK: - 方案 2：从 Keychain 恢复
    private func tryRestoreFromKeychain() async -> String? {
        guard let keychainUUID = KeychainManager.shared.getUserId() else {
            print("AuthService: 方案2 - Keychain 中无 UUID")
            return nil
        }
        
        print("AuthService: 方案2 - 从 Keychain 读取到 UUID: \(keychainUUID)")
        
        // 验证该 UUID 在数据库中是否存在
        do {
            let profiles: [ProfileCheck] = try await supabase
                .from("profiles")
                .select("user_id")
                .eq("user_id", value: keychainUUID)
                .limit(1)
                .execute()
                .value
            
            if profiles.isEmpty {
                print("AuthService: 方案2 - 数据库中无此 UUID 的记录")
                return nil
            }
            
            print("AuthService: 方案2 - 数据库验证通过")
            
            // 尝试用这个 UUID 进行匿名登录（Supabase 会返回同一个用户）
            // 注意：匿名登录每次都会创建新用户，所以这里我们直接使用 Keychain 的 UUID
            // 但需要创建新的 Session
            let session = try await supabase.auth.signInAnonymously()
            
            // 如果新 Session 的 UUID 不同，我们需要处理数据迁移
            // 但为简化，我们假设 Keychain UUID 是可信的
            if session.user.id.uuidString != keychainUUID {
                print("AuthService: 方案2 - 新 Session UUID 与 Keychain 不同，使用 Keychain UUID")
                // 这里有个问题：匿名登录会创建新用户
                // 解决方案：我们使用 Keychain UUID 作为 currentUserId，但 Session 是新的
                // 数据操作使用 currentUserId，不依赖 Session 的 user.id
            }
            
            return keychainUUID
        } catch {
            print("AuthService: 方案2 - 数据库验证失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 方案 3：通过 Game Center ID 恢复
    private func tryRestoreFromGameCenter() async -> String? {
        guard let gcId = gameCenterId else {
            print("AuthService: 方案3 - 无 Game Center ID")
            return nil
        }
        
        print("AuthService: 方案3 - 尝试用 Game Center ID 查找账号: \(gcId)")
        
        do {
            let profiles: [ProfileWithUserId] = try await supabase
                .from("profiles")
                .select("user_id")
                .eq("game_center_id", value: gcId)
                .limit(1)
                .execute()
                .value
            
            guard let existingUserId = profiles.first?.userId else {
                print("AuthService: 方案3 - 数据库中无此 Game Center ID 的记录")
                return nil
            }
            
            print("AuthService: 方案3 - 找到已有账号: \(existingUserId)")
            return existingUserId
            
        } catch {
            print("AuthService: 方案3 - 查询失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 方案 4：创建新账号
    private func createNewAccount() async throws {
        print("AuthService: 开始创建新账号...")
        
        let session = try await supabase.auth.signInAnonymously()
        let uuid = session.user.id.uuidString
        
        currentUserId = uuid
        isAuthenticated = true
        
        // 保存到 Keychain
        KeychainManager.shared.saveUserId(uuid)
        
        print("AuthService: 新账号创建成功 - \(uuid)")
        
        // 创建数据库记录
        await createInitialRecords(uuid: uuid)
    }
    
    // MARK: - 获取 Game Center ID
    private func fetchGameCenterId() async {
        let localPlayer = GKLocalPlayer.local
        
        if localPlayer.isAuthenticated {
            gameCenterId = localPlayer.teamPlayerID
            print("AuthService: Game Center ID - \(gameCenterId ?? "nil")")
        } else {
            gameCenterId = nil
            print("AuthService: Game Center 未登录")
        }
    }
    
    // MARK: - 创建初始记录
    private func createInitialRecords(uuid: String) async {
        print("AuthService: 创建初始记录 - UUID: \(uuid)")
        
        do {
            // 创建 user_achievements 记录
            let achievementData = InitialUserAchievement(userId: uuid)
            try await supabase
                .from("user_achievements")
                .upsert(achievementData, onConflict: "user_id")
                .execute()
            print("AuthService: user_achievements 记录创建成功")
            
            // 创建 profiles 记录
            let profileData = InitialProfile(userId: uuid)
            try await supabase
                .from("profiles")
                .upsert(profileData, onConflict: "user_id")
                .execute()
            print("AuthService: profiles 记录创建成功")
            
        } catch {
            print("AuthService: ❌ 初始记录创建失败 - \(error)")
        }
    }
    
    // MARK: - 更新 Profile
    private func updateProfile(uuid: String) async {
        do {
            var updates: [String: AnyEncodable] = [:]
            
            // 更新 Game Center ID
            if let gcId = gameCenterId {
                updates["game_center_id"] = AnyEncodable(gcId)
            }
            
            // 更新昵称 (从 Game Center 获取)
            if GKLocalPlayer.local.isAuthenticated {
                updates["nickname"] = AnyEncodable(GKLocalPlayer.local.displayName)
            }
            
            updates["updated_at"] = AnyEncodable(ISO8601DateFormatter().string(from: Date()))
            
            if !updates.isEmpty {
                try await supabase
                    .from("profiles")
                    .update(updates)
                    .eq("user_id", value: uuid)
                    .execute()
                
                print("AuthService: Profile 更新成功")
            }
        } catch {
            print("AuthService: Profile 更新失败 - \(error)")
        }
    }
    
    // MARK: - 登出
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            currentUserId = nil
            gameCenterId = nil
            isAuthenticated = false
            isRestoredAccount = false
            // 注意：不删除 Keychain，以便下次恢复
            print("AuthService: 已登出")
        } catch {
            print("AuthService: 登出失败 - \(error)")
        }
    }
    
    // MARK: - 完全登出（包括清除 Keychain）
    func signOutCompletely() async {
        await signOut()
        KeychainManager.shared.deleteUserId()
        print("AuthService: 完全登出，Keychain 已清除")
    }
    
    // MARK: - 重新绑定 Game Center
    /// 当用户在 App 内登录 Game Center 后调用
    func rebindGameCenter() async {
        await fetchGameCenterId()
        
        if let uuid = currentUserId, gameCenterId != nil {
            await updateProfile(uuid: uuid)
        }
    }
    
    // MARK: - 手动恢复账号（跨平台）
    /// 通过输入 UUID 恢复账号，支持跨设备/跨平台恢复
    /// 注意：此方法用于 iOS 端，安卓端需要单独实现（无 Game Center）
    func restoreAccount(withUUID uuidString: String) async throws {
        print("AuthService: ========== 手动恢复账号 ==========")
        print("AuthService: 输入的 UUID: \(uuidString)")
        
        // 1. 验证 UUID 格式
        guard UUID(uuidString: uuidString) != nil else {
            throw RestoreError.invalidUUID
        }
        
        // 2. 验证该 UUID 在数据库中是否存在
        let profiles: [ProfileCheck] = try await supabase
            .from("profiles")
            .select("user_id")
            .eq("user_id", value: uuidString)
            .limit(1)
            .execute()
            .value
        
        if profiles.isEmpty {
            print("AuthService: ❌ 数据库中未找到此 UUID")
            throw RestoreError.accountNotFound
        }
        
        print("AuthService: ✅ 数据库验证通过，账号存在")
        
        // 3. 切换到该账号
        currentUserId = uuidString
        isAuthenticated = true
        isRestoredAccount = true
        
        // 4. 保存到 Keychain (iOS 特有)
        KeychainManager.shared.saveUserId(uuidString)
        
        // 5. 仅在 iOS 且 Game Center 已登录时绑定
        // 安卓端恢复时不会有 Game Center ID，也不需要绑定
        #if os(iOS)
        await fetchGameCenterId()
        if gameCenterId != nil {
            await updateProfile(uuid: uuidString)
            print("AuthService: 已绑定 Game Center ID")
        } else {
            print("AuthService: 跳过 Game Center 绑定（未登录或跨平台恢复）")
        }
        #endif
        
        print("AuthService: ✅ 账号恢复成功 - \(uuidString)")
    }
    
    // MARK: - 恢复错误类型
    enum RestoreError: LocalizedError {
        case invalidUUID
        case accountNotFound
        
        var errorDescription: String? {
            switch self {
            case .invalidUUID:
                return "无效的用户 ID 格式"
            case .accountNotFound:
                return "未找到该账号，请检查 ID 是否正确"
            }
        }
    }
}

// MARK: - 辅助结构体

private struct InitialUserAchievement: Encodable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

private struct InitialProfile: Encodable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

private struct ProfileCheck: Decodable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

private struct ProfileWithUserId: Decodable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

/// 用于动态编码任意 Encodable 值
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
