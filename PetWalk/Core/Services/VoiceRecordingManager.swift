//
//  VoiceRecordingManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/2/2.
//

import Foundation
import AVFoundation
import Supabase

/// 狗叫声录音管理器
/// 负责录制、存储、播放自定义狗叫声
/// Phase 2: 支持上传到 Supabase Storage
@MainActor
class VoiceRecordingManager: NSObject, ObservableObject {
    // MARK: - 单例
    static let shared = VoiceRecordingManager()
    
    // MARK: - Supabase 客户端
    private let supabase: SupabaseClient
    private let storageBucket = "pet-voices"
    
    // MARK: - 发布的属性
    @Published var isRecording: Bool = false
    @Published var isPlaying: Bool = false
    @Published var recordingProgress: Double = 0  // 0.0 - 1.0
    @Published var hasRecordedVoice: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var errorMessage: String?
    
    // Phase 2: 云同步状态
    @Published var isUploading: Bool = false
    @Published var isDownloading: Bool = false
    @Published var cloudVoiceUrl: String?  // 云端 URL
    @Published var isSyncedToCloud: Bool = false  // 是否已同步到云端
    
    // MARK: - 私有属性
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?
    
    // 录音配置
    private let maxRecordingDuration: TimeInterval = 2.0  // 最大录音时长 2 秒
    private let sampleRate: Double = 44100.0
    
    // MARK: - 文件路径
    
    /// 原始录音文件路径 (m4a)
    private var recordingURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("pet_voice_recording.m4a")
    }
    
    /// 处理后的最终文件路径 (用于通知铃声的 caf 格式)
    private var processedVoiceURL: URL {
        let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let soundsPath = libraryPath.appendingPathComponent("Sounds")
        
        // 确保 Sounds 目录存在
        try? FileManager.default.createDirectory(at: soundsPath, withIntermediateDirectories: true)
        
        return soundsPath.appendingPathComponent("pet_bark.caf")
    }
    
    /// 备份的 m4a 文件（用于 App 内播放）
    var voiceFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("pet_bark.m4a")
    }
    
    // MARK: - 初始化
    
    private override init() {
        self.supabase = SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.apiKey
        )
        super.init()
        checkExistingRecording()
        
        // 检查云端同步状态
        Task {
            await checkCloudSyncStatus()
        }
    }
    
    // MARK: - 用户 ID
    private var currentUserId: String? {
        AuthService.shared.currentUserId
    }
    
    // MARK: - 权限检查
    
    /// 检查并请求麦克风权限
    func requestPermission() async -> Bool {
        let status = AVAudioApplication.shared.recordPermission
        
        switch status {
        case .granted:
            permissionGranted = true
            return true
            
        case .denied:
            permissionGranted = false
            return false
            
        case .undetermined:
            let granted = await AVAudioApplication.requestRecordPermission()
            permissionGranted = granted
            return granted
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - 录音功能
    
    /// 开始录音
    func startRecording() async {
        // 检查权限
        guard await requestPermission() else {
            errorMessage = "请在设置中允许麦克风权限"
            return
        }
        
        // 配置音频会话
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            errorMessage = "音频配置失败: \(error.localizedDescription)"
            return
        }
        
        // 录音设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            recordingProgress = 0
            errorMessage = nil
            
            // 启动进度计时器
            startRecordingTimer()
            
            print("VoiceRecording: 开始录音")
        } catch {
            errorMessage = "录音失败: \(error.localizedDescription)"
            print("VoiceRecording: 录音失败 - \(error)")
        }
    }
    
    /// 停止录音
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        
        // 处理录音文件
        processRecording()
        
        print("VoiceRecording: 停止录音")
    }
    
    /// 录音计时器
    private func startRecordingTimer() {
        let startTime = Date()
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                let elapsed = Date().timeIntervalSince(startTime)
                self.recordingProgress = min(elapsed / self.maxRecordingDuration, 1.0)
                
                // 达到最大时长自动停止
                if elapsed >= self.maxRecordingDuration {
                    self.stopRecording()
                }
            }
        }
    }
    
    // MARK: - 音频处理
    
    /// 处理录音：降噪 + 音量均衡 + 格式转换
    private func processRecording() {
        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            errorMessage = "录音文件不存在"
            return
        }
        
        do {
            // 复制一份 m4a 用于 App 内播放
            if FileManager.default.fileExists(atPath: voiceFileURL.path) {
                try FileManager.default.removeItem(at: voiceFileURL)
            }
            try FileManager.default.copyItem(at: recordingURL, to: voiceFileURL)
            
            // 转换为 caf 格式用于通知铃声
            convertToCAF()
            
            hasRecordedVoice = true
            print("VoiceRecording: 处理完成")
        } catch {
            errorMessage = "文件处理失败: \(error.localizedDescription)"
            print("VoiceRecording: 处理失败 - \(error)")
        }
    }
    
    /// 转换为 CAF 格式（用于本地通知铃声）
    private func convertToCAF() {
        // 使用 AVAssetExportSession 转换格式
        let asset = AVAsset(url: recordingURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            print("VoiceRecording: 无法创建导出会话")
            return
        }
        
        // 删除旧文件
        if FileManager.default.fileExists(atPath: processedVoiceURL.path) {
            try? FileManager.default.removeItem(at: processedVoiceURL)
        }
        
        exportSession.outputURL = processedVoiceURL
        exportSession.outputFileType = .caf
        
        exportSession.exportAsynchronously { [weak self] in
            Task { @MainActor in
                switch exportSession.status {
                case .completed:
                    print("VoiceRecording: CAF 转换成功")
                case .failed:
                    print("VoiceRecording: CAF 转换失败 - \(exportSession.error?.localizedDescription ?? "")")
                    // 如果 CAF 转换失败，直接复制 m4a 文件（部分设备可能支持）
                    self?.fallbackCopyM4A()
                default:
                    break
                }
            }
        }
    }
    
    /// 备用方案：直接复制 m4a
    private func fallbackCopyM4A() {
        let soundsPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sounds")
        let fallbackURL = soundsPath.appendingPathComponent("pet_bark.m4a")
        
        do {
            if FileManager.default.fileExists(atPath: fallbackURL.path) {
                try FileManager.default.removeItem(at: fallbackURL)
            }
            try FileManager.default.copyItem(at: voiceFileURL, to: fallbackURL)
            print("VoiceRecording: 使用 m4a 作为通知铃声")
        } catch {
            print("VoiceRecording: 备用复制失败 - \(error)")
        }
    }
    
    // MARK: - 播放功能
    
    /// 播放录制的狗叫声
    func playVoice() {
        guard hasRecordedVoice else {
            errorMessage = "还没有录制叫声"
            return
        }
        
        guard FileManager.default.fileExists(atPath: voiceFileURL.path) else {
            errorMessage = "录音文件丢失"
            hasRecordedVoice = false
            return
        }
        
        do {
            // 配置音频会话
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: voiceFileURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            isPlaying = true
            print("VoiceRecording: 开始播放")
        } catch {
            errorMessage = "播放失败: \(error.localizedDescription)"
            print("VoiceRecording: 播放失败 - \(error)")
        }
    }
    
    /// 停止播放
    func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    /// 播放用于结算提示的叫声（静默失败）
    func playForNotification() {
        guard hasRecordedVoice,
              FileManager.default.fileExists(atPath: voiceFileURL.path) else {
            return
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: voiceFileURL)
            audioPlayer?.volume = 0.8
            audioPlayer?.play()
        } catch {
            print("VoiceRecording: 提示音播放失败 - \(error)")
        }
    }
    
    // MARK: - 删除录音
    
    /// 删除已录制的狗叫声
    func deleteRecording() {
        let filesToDelete = [recordingURL, voiceFileURL, processedVoiceURL]
        
        for url in filesToDelete {
            try? FileManager.default.removeItem(at: url)
        }
        
        // 删除 Library/Sounds 中的备用文件
        let soundsPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sounds")
            .appendingPathComponent("pet_bark.m4a")
        try? FileManager.default.removeItem(at: soundsPath)
        
        hasRecordedVoice = false
        print("VoiceRecording: 录音已删除")
    }
    
    // MARK: - 辅助方法
    
    /// 检查是否已有录音
    private func checkExistingRecording() {
        hasRecordedVoice = FileManager.default.fileExists(atPath: voiceFileURL.path)
    }
    
    /// 获取通知铃声文件名（用于 UNNotificationSound）
    var notificationSoundName: String {
        // 优先使用 caf，否则使用 m4a
        if FileManager.default.fileExists(atPath: processedVoiceURL.path) {
            return "pet_bark.caf"
        } else {
            return "pet_bark.m4a"
        }
    }
    
    // MARK: - Phase 2: 云端同步功能
    
    /// 上传录音到 Supabase Storage
    func uploadToCloud() async -> Bool {
        print("VoiceRecording: ========== 开始上传 ==========")
        
        guard hasRecordedVoice else {
            errorMessage = "没有可上传的录音"
            print("VoiceRecording: 错误 - 没有录音")
            return false
        }
        
        guard let userId = currentUserId else {
            errorMessage = "请先登录"
            print("VoiceRecording: 错误 - 未登录 Game Center")
            return false
        }
        print("VoiceRecording: userId = \(userId)")
        
        guard FileManager.default.fileExists(atPath: voiceFileURL.path) else {
            errorMessage = "录音文件不存在"
            print("VoiceRecording: 错误 - 文件不存在: \(voiceFileURL.path)")
            return false
        }
        
        isUploading = true
        errorMessage = nil
        
        do {
            // 读取文件数据
            let fileData = try Data(contentsOf: voiceFileURL)
            print("VoiceRecording: 文件大小 = \(fileData.count) bytes")
            
            // 文件路径: {userId}/voice.m4a
            let filePath = "\(userId)/voice.m4a"
            print("VoiceRecording: 上传路径 = \(filePath)")
            print("VoiceRecording: Storage bucket = \(storageBucket)")
            
            // 先尝试删除旧文件（如果存在）
            print("VoiceRecording: 尝试删除旧文件...")
            do {
                try await supabase.storage
                    .from(storageBucket)
                    .remove(paths: [filePath])
                print("VoiceRecording: 旧文件已删除")
            } catch {
                // 删除失败不影响上传（可能文件本来就不存在）
                print("VoiceRecording: 无旧文件或删除跳过")
            }
            
            // 上传到 Supabase Storage
            print("VoiceRecording: 正在上传到 Storage...")
            let uploadResult = try await supabase.storage
                .from(storageBucket)
                .upload(
                    filePath,
                    data: fileData,
                    options: FileOptions(
                        contentType: "audio/mp4",
                        upsert: true  // 覆盖已存在的文件
                    )
                )
            print("VoiceRecording: Storage 上传成功, result = \(uploadResult)")
            
            // 获取公开 URL
            let publicUrl = try supabase.storage
                .from(storageBucket)
                .getPublicURL(path: filePath)
            print("VoiceRecording: 公开 URL = \(publicUrl)")
            
            cloudVoiceUrl = publicUrl.absoluteString
            
            // 更新 pets 表的 voice_url 字段
            await updatePetVoiceUrl(publicUrl.absoluteString)
            
            isSyncedToCloud = true
            isUploading = false
            print("VoiceRecording: ========== 上传完成 ==========")
            return true
            
        } catch {
            isUploading = false
            errorMessage = "上传失败: \(error.localizedDescription)"
            print("VoiceRecording: ❌ 上传失败 - \(error)")
            print("VoiceRecording: ❌ 详细错误 - \(String(describing: error))")
            return false
        }
    }
    
    /// 更新 pets 表的 voice_url
    private func updatePetVoiceUrl(_ url: String) async {
        guard let userId = currentUserId else { return }
        
        do {
            // 先检查 pets 表中是否有该用户的宠物记录
            let existingPets: [PetIdData] = try await supabase
                .from("pets")
                .select("id")
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value
            
            if existingPets.isEmpty {
                // 没有宠物记录，创建一条新记录
                let petName = DataManager.shared.userData.petName
                let newPet = NewPetWithVoice(userId: userId, name: petName, voiceUrl: url)
                try await supabase
                    .from("pets")
                    .insert(newPet)
                    .execute()
                print("VoiceRecording: 创建 pet 并设置 voice_url 成功")
            } else {
                // 已有宠物记录，更新 voice_url
                let updateData = VoiceUrlUpdate(voiceUrl: url)
                try await supabase
                    .from("pets")
                    .update(updateData)
                    .eq("user_id", value: userId)
                    .execute()
                print("VoiceRecording: 更新 pets.voice_url 成功")
            }
        } catch {
            print("VoiceRecording: 更新 pets.voice_url 失败 - \(error)")
        }
    }
    
    /// 从云端下载录音（用于恢复或在新设备上同步）
    func downloadFromCloud() async -> Bool {
        guard let userId = currentUserId else {
            errorMessage = "请先登录"
            return false
        }
        
        isDownloading = true
        errorMessage = nil
        
        do {
            // 先检查 pets 表是否有 voice_url
            let pets: [PetVoiceData] = try await supabase
                .from("pets")
                .select("voice_url")
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value
            
            guard let voiceUrl = pets.first?.voiceUrl, !voiceUrl.isEmpty else {
                isDownloading = false
                print("VoiceRecording: 云端没有录音")
                return false
            }
            
            cloudVoiceUrl = voiceUrl
            
            // 下载文件
            let filePath = "\(userId)/voice.m4a"
            let data = try await supabase.storage
                .from(storageBucket)
                .download(path: filePath)
            
            // 保存到本地
            try data.write(to: voiceFileURL)
            
            // 处理文件（生成 caf 格式用于通知）
            processRecording()
            
            hasRecordedVoice = true
            isSyncedToCloud = true
            isDownloading = false
            print("VoiceRecording: 下载成功")
            return true
            
        } catch {
            isDownloading = false
            errorMessage = "下载失败: \(error.localizedDescription)"
            print("VoiceRecording: 下载失败 - \(error)")
            return false
        }
    }
    
    /// 从云端删除录音
    func deleteFromCloud() async -> Bool {
        guard let userId = currentUserId else {
            errorMessage = "请先登录"
            return false
        }
        
        do {
            // 删除 Storage 中的文件
            let filePath = "\(userId)/voice.m4a"
            try await supabase.storage
                .from(storageBucket)
                .remove(paths: [filePath])
            
            // 清空 pets 表的 voice_url (使用 update 而非 upsert)
            let updateData = VoiceUrlUpdate(voiceUrl: nil)
            try await supabase
                .from("pets")
                .update(updateData)
                .eq("user_id", value: userId)
                .execute()
            
            cloudVoiceUrl = nil
            isSyncedToCloud = false
            print("VoiceRecording: 云端删除成功")
            return true
            
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
            print("VoiceRecording: 云端删除失败 - \(error)")
            return false
        }
    }
    
    /// 检查云端同步状态
    func checkCloudSyncStatus() async {
        guard let userId = currentUserId else { return }
        
        do {
            let pets: [PetVoiceData] = try await supabase
                .from("pets")
                .select("voice_url")
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value
            
            if let voiceUrl = pets.first?.voiceUrl, !voiceUrl.isEmpty {
                cloudVoiceUrl = voiceUrl
                isSyncedToCloud = hasRecordedVoice  // 如果本地有文件且云端有 URL，认为已同步
            } else {
                cloudVoiceUrl = nil
                isSyncedToCloud = false
            }
        } catch {
            print("VoiceRecording: 检查云端状态失败 - \(error)")
        }
    }
    
    /// 同步录音（上传本地 -> 云端，或下载云端 -> 本地）
    func syncVoice() async {
        guard currentUserId != nil else { return }
        
        if hasRecordedVoice && !isSyncedToCloud {
            // 本地有录音但未同步 -> 上传
            _ = await uploadToCloud()
        } else if !hasRecordedVoice && cloudVoiceUrl != nil {
            // 本地无录音但云端有 -> 下载
            _ = await downloadFromCloud()
        }
    }
}

// MARK: - Supabase 辅助结构体

private struct PetIdData: Decodable {
    let id: String
}

private struct NewPetWithVoice: Encodable {
    let userId: String
    let name: String
    let voiceUrl: String
    let isPrimary: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case voiceUrl = "voice_url"
        case isPrimary = "is_primary"
    }
}

private struct VoiceUrlUpdate: Encodable {
    let voiceUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case voiceUrl = "voice_url"
    }
}

private struct PetVoiceData: Decodable {
    let voiceUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case voiceUrl = "voice_url"
    }
}

// MARK: - AVAudioRecorderDelegate
extension VoiceRecordingManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                errorMessage = "录音未成功完成"
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            errorMessage = "录音编码错误: \(error?.localizedDescription ?? "未知错误")"
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension VoiceRecordingManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            isPlaying = false
            errorMessage = "播放解码错误"
        }
    }
}
