//
//  KeychainManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/2/4.
//

import Foundation
import Security

/// Keychain 管理器
/// 用于安全存储用户 UUID，卸载 App 后仍然保留
class KeychainManager {
    // MARK: - 单例
    static let shared = KeychainManager()
    
    // MARK: - Keychain 键名
    private let userIdKey = "com.petwalk.userId"
    private let serviceName = "PetWalk"
    
    private init() {}
    
    // MARK: - 存储 UUID
    
    /// 保存用户 UUID 到 Keychain
    func saveUserId(_ userId: String) -> Bool {
        // 先删除旧值
        deleteUserId()
        
        guard let data = userId.data(using: .utf8) else {
            print("KeychainManager: 无法编码 userId")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userIdKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("KeychainManager: UUID 保存成功")
            return true
        } else {
            print("KeychainManager: UUID 保存失败 - \(status)")
            return false
        }
    }
    
    // MARK: - 读取 UUID
    
    /// 从 Keychain 读取用户 UUID
    func getUserId() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userIdKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let userId = String(data: data, encoding: .utf8) {
            print("KeychainManager: 从 Keychain 读取到 UUID - \(userId)")
            return userId
        } else if status == errSecItemNotFound {
            print("KeychainManager: Keychain 中无 UUID")
            return nil
        } else {
            print("KeychainManager: 读取失败 - \(status)")
            return nil
        }
    }
    
    // MARK: - 删除 UUID
    
    /// 从 Keychain 删除用户 UUID
    @discardableResult
    func deleteUserId() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userIdKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("KeychainManager: UUID 已删除")
            return true
        } else {
            print("KeychainManager: 删除失败 - \(status)")
            return false
        }
    }
    
    // MARK: - 检查是否存在
    
    /// 检查 Keychain 中是否存在 UUID
    var hasUserId: Bool {
        return getUserId() != nil
    }
}
