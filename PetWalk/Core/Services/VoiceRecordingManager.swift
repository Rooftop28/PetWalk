//
//  VoiceRecordingManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/2/2.
//

import Foundation
import AVFoundation

/// 狗叫声录音管理器
/// 负责录制、存储、播放自定义狗叫声
@MainActor
class VoiceRecordingManager: NSObject, ObservableObject {
    // MARK: - 单例
    static let shared = VoiceRecordingManager()
    
    // MARK: - 发布的属性
    @Published var isRecording: Bool = false
    @Published var isPlaying: Bool = false
    @Published var recordingProgress: Double = 0  // 0.0 - 1.0
    @Published var hasRecordedVoice: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var errorMessage: String?
    
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
        super.init()
        checkExistingRecording()
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
