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
    
    // MARK: - Ready Player Me 配置
    // 可以在这里配置你的 Ready Player Me subdomain
    static let rpmSubdomain = "demo" // TODO: 替换为你的 subdomain
    
    /// Ready Player Me 头像创建器 URL
    var avatarCreatorURL: URL {
        URL(string: "https://\(AvatarManager.rpmSubdomain).readyplayer.me/avatar?frameApi")!
    }
    
    // MARK: - 私有属性
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    private init() {
        // 从 UserData 加载头像
        loadAvatarFromCache()
    }
    
    // MARK: - 头像 URL 处理
    
    /// 从 Ready Player Me 的 GLB URL 转换为 2D 渲染图 URL
    /// - Parameter glbURL: GLB 模型 URL (如 https://models.readyplayer.me/{id}.glb)
    /// - Returns: 2D 渲染图 URL
    func getRenderURL(from glbURL: String) -> URL? {
        // GLB URL 格式: https://models.readyplayer.me/{avatar_id}.glb
        // 渲染 URL 格式: https://models.readyplayer.me/{avatar_id}.png?scene=fullbody-portrait-v1
        
        guard let url = URL(string: glbURL) else { return nil }
        
        // 提取 avatar_id
        let pathWithoutExtension = url.deletingPathExtension().lastPathComponent
        
        // 构建渲染 URL
        let renderURLString = "https://models.readyplayer.me/\(pathWithoutExtension).png?scene=fullbody-portrait-v1&quality=high"
        return URL(string: renderURLString)
    }
    
    /// 保存头像 URL 并下载图片
    /// - Parameter url: Ready Player Me 返回的头像 URL
    func saveAvatarURL(_ url: String) {
        var userData = DataManager.shared.userData
        userData.avatarURL = url
        DataManager.shared.updateUserData(userData)
        
        hasAvatar = true
        
        // 下载并缓存头像图片
        downloadAndCacheAvatar(from: url)
    }
    
    /// 下载并缓存头像图片
    private func downloadAndCacheAvatar(from urlString: String) {
        guard let renderURL = getRenderURL(from: urlString) else {
            print("AvatarManager: 无法生成渲染 URL")
            return
        }
        
        isLoading = true
        
        URLSession.shared.dataTaskPublisher(for: renderURL)
            .map { UIImage(data: $0.data) }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("AvatarManager: 下载头像失败 - \(error)")
                }
            }, receiveValue: { [weak self] image in
                self?.avatarImage = image
                
                // 保存到本地
                if let image = image {
                    self?.saveImageToCache(image)
                }
            })
            .store(in: &cancellables)
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
        
        // 检查是否有头像 URL
        hasAvatar = userData.avatarURL != nil
        
        // 尝试从缓存加载
        if let cachePath = userData.avatarImageCachePath {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(cachePath)
            
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                avatarImage = image
                print("AvatarManager: 从缓存加载头像成功")
                return
            }
        }
        
        // 如果缓存不存在但有 URL，重新下载
        if let avatarURL = userData.avatarURL {
            downloadAndCacheAvatar(from: avatarURL)
        }
    }
    
    /// 刷新头像（重新下载）
    func refreshAvatar() {
        guard let avatarURL = DataManager.shared.userData.avatarURL else { return }
        downloadAndCacheAvatar(from: avatarURL)
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
