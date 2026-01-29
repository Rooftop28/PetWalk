//
//  AvatarManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import SwiftUI
import Combine

/// 头像管理器 - 负责 Ready Player Me 头像的管理和加载
@MainActor
class AvatarManager: ObservableObject {
    // MARK: - 单例
    static let shared = AvatarManager()
    
    // MARK: - 发布的属性
    @Published var avatarImage: UIImage?
    @Published var isLoading: Bool = false
    @Published var hasAvatar: Bool = false
    
    // MARK: - 初始化
    // ...
    
    // MARK: - 私有属性
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    private init() {
        // 从 UserData 加载头像
        loadAvatarFromCache()
    }
    
    // MARK: - 头像处理
    
    /// 保存从相册选择并处理过（已抠图）的头像
    @MainActor
    func saveUserAvatar(_ image: UIImage) {
        self.avatarImage = image
        self.hasAvatar = true
        self.saveImageToCache(image)
    }
    
    /// 保存图片到本地缓存
    private func saveImageToCache(_ image: UIImage) {
        guard let data = image.pngData() else { return }
        
        let fileName = "user_avatar.png"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        do {
            try data.write(to: url)
            
            // 更新 UserData 中的缓存路径
            var userData = DataManager.shared.userData
            userData.avatarImageCachePath = fileName
            DataManager.shared.updateUserData(userData)
            
            print("AvatarManager: 头像已缓存到 \(url)")
        } catch {
            print("AvatarManager: 保存头像失败 - \(error)")
        }
    }
    
    /// 从本地缓存加载头像
    private func loadAvatarFromCache() {
        let userData = DataManager.shared.userData
        
        // 尝试从缓存加载
        if let cachePath = userData.avatarImageCachePath {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(cachePath)
            
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                avatarImage = image
                hasAvatar = true
                print("AvatarManager: 从缓存加载头像成功")
                return
            }
        }
        
        hasAvatar = false
    }
    
    /// 刷新头像
    func refreshAvatar() {
        loadAvatarFromCache()
    }
    
    /// 删除头像
    func deleteAvatar() {
        avatarImage = nil
        hasAvatar = false
        
        // 删除本地缓存
        if let cachePath = DataManager.shared.userData.avatarImageCachePath {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(cachePath)
            try? FileManager.default.removeItem(at: url)
        }
        
        // 清除 UserData 中的头像数据
        var userData = DataManager.shared.userData
        userData.avatarURL = nil
        userData.avatarImageCachePath = nil
        DataManager.shared.updateUserData(userData)
    }
}
