//
//  RemoteVoicePlayer.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/2/2.
//

import Foundation
import AVFoundation

/// 远程狗叫声播放器
/// 用于在排行榜播放其他用户的狗叫声，支持缓存
@MainActor
class RemoteVoicePlayer: NSObject, ObservableObject {
    // MARK: - 单例
    static let shared = RemoteVoicePlayer()
    
    // MARK: - 发布的属性
    @Published var isPlaying: Bool = false
    @Published var currentPlayingUserId: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - 私有属性
    private var audioPlayer: AVAudioPlayer?
    private var downloadTask: URLSessionDataTask?
    
    // 缓存目录
    private var cacheDirectory: URL {
        let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let voiceCachePath = cachePath.appendingPathComponent("VoiceCache")
        try? FileManager.default.createDirectory(at: voiceCachePath, withIntermediateDirectories: true)
        return voiceCachePath
    }
    
    // MARK: - 初始化
    private override init() {
        super.init()
    }
    
    // MARK: - 播放远程音频
    
    /// 播放指定用户的狗叫声
    /// - Parameters:
    ///   - userId: 用户 ID（用于缓存标识）
    ///   - voiceUrl: 音频 URL
    func play(userId: String, voiceUrl: String) {
        // 如果正在播放同一个用户的声音，则停止
        if isPlaying && currentPlayingUserId == userId {
            stop()
            return
        }
        
        // 停止当前播放
        stop()
        
        currentPlayingUserId = userId
        
        // 检查本地缓存
        let cacheUrl = cacheDirectory.appendingPathComponent("\(userId).m4a")
        
        if FileManager.default.fileExists(atPath: cacheUrl.path) {
            // 使用缓存播放
            playFromLocal(url: cacheUrl)
        } else {
            // 下载并播放
            downloadAndPlay(userId: userId, remoteUrl: voiceUrl, cacheUrl: cacheUrl)
        }
    }
    
    /// 停止播放
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        downloadTask?.cancel()
        downloadTask = nil
        isPlaying = false
        isLoading = false
        currentPlayingUserId = nil
    }
    
    // MARK: - 私有方法
    
    /// 从本地缓存播放
    private func playFromLocal(url: URL) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            isPlaying = true
            print("RemoteVoicePlayer: 播放缓存音频")
        } catch {
            errorMessage = "播放失败"
            print("RemoteVoicePlayer: 播放失败 - \(error)")
            currentPlayingUserId = nil
        }
    }
    
    /// 下载并播放
    private func downloadAndPlay(userId: String, remoteUrl: String, cacheUrl: URL) {
        guard let url = URL(string: remoteUrl) else {
            errorMessage = "无效的音频链接"
            currentPlayingUserId = nil
            return
        }
        
        isLoading = true
        
        downloadTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.isLoading = false
                
                // 检查是否被取消（用户切换了）
                guard self.currentPlayingUserId == userId else { return }
                
                if let error = error {
                    if (error as NSError).code != NSURLErrorCancelled {
                        self.errorMessage = "下载失败"
                        print("RemoteVoicePlayer: 下载失败 - \(error)")
                    }
                    self.currentPlayingUserId = nil
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "无音频数据"
                    self.currentPlayingUserId = nil
                    return
                }
                
                // 保存到缓存
                do {
                    try data.write(to: cacheUrl)
                    print("RemoteVoicePlayer: 缓存音频 - \(userId)")
                } catch {
                    print("RemoteVoicePlayer: 缓存保存失败 - \(error)")
                }
                
                // 播放
                self.playFromLocal(url: cacheUrl)
            }
        }
        
        downloadTask?.resume()
    }
    
    // MARK: - 缓存管理
    
    /// 预加载排行榜前 N 名的狗叫声
    func preloadVoices(_ entries: [(userId: String, voiceUrl: String)], limit: Int = 10) {
        let toPreload = entries.prefix(limit)
        
        for entry in toPreload {
            let cacheUrl = cacheDirectory.appendingPathComponent("\(entry.userId).m4a")
            
            // 跳过已缓存的
            if FileManager.default.fileExists(atPath: cacheUrl.path) { continue }
            
            guard let url = URL(string: entry.voiceUrl) else { continue }
            
            // 后台下载
            Task.detached(priority: .background) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    try data.write(to: cacheUrl)
                    print("RemoteVoicePlayer: 预加载完成 - \(entry.userId)")
                } catch {
                    print("RemoteVoicePlayer: 预加载失败 - \(entry.userId)")
                }
            }
        }
    }
    
    /// 清理缓存（保留最近 50 个）
    func cleanCache() {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )
            
            // 按修改时间排序
            let sortedFiles = files.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                return date1 > date2
            }
            
            // 删除超过 50 个的旧文件
            if sortedFiles.count > 50 {
                for file in sortedFiles.dropFirst(50) {
                    try? FileManager.default.removeItem(at: file)
                }
                print("RemoteVoicePlayer: 清理了 \(sortedFiles.count - 50) 个缓存文件")
            }
        } catch {
            print("RemoteVoicePlayer: 缓存清理失败 - \(error)")
        }
    }
    
    /// 检查某用户的声音是否已缓存
    func isCached(userId: String) -> Bool {
        let cacheUrl = cacheDirectory.appendingPathComponent("\(userId).m4a")
        return FileManager.default.fileExists(atPath: cacheUrl.path)
    }
}

// MARK: - AVAudioPlayerDelegate
extension RemoteVoicePlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            currentPlayingUserId = nil
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            isPlaying = false
            currentPlayingUserId = nil
            errorMessage = "播放错误"
        }
    }
}
