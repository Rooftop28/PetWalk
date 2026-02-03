//
//  VoiceRecordingView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/2/2.
//

import SwiftUI
import AVFoundation

/// 狗叫声录制视图
struct VoiceRecordingView: View {
    @ObservedObject var voiceManager = VoiceRecordingManager.shared
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showDeleteConfirmation = false
    @State private var pulseAnimation = false
    
    var petName: String {
        dataManager.userData.petName
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 标题说明
                        headerSection
                        
                        // 录音控制区
                        recordingSection
                        
                        // 已录制的预览
                        if voiceManager.hasRecordedVoice {
                            recordedPreviewSection
                        }
                        
                        // 使用说明
                        usageInfoSection
                        
                        // 错误提示
                        if let error = voiceManager.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("录制叫声")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.appGreenMain)
                }
            }
            .alert("删除录音", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    voiceManager.deleteRecording()
                }
            } message: {
                Text("确定要删除已录制的叫声吗？")
            }
        }
    }
    
    // MARK: - 标题说明
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color.appGreenMain.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.appGreenMain)
            }
            
            Text("录制 \(petName) 的叫声")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appBrown)
            
            Text("录制一段独特的叫声，作为专属提示音")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - 录音控制区
    
    private var recordingSection: some View {
        VStack(spacing: 20) {
            // 录音按钮
            ZStack {
                // 外圈进度
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .trim(from: 0, to: voiceManager.recordingProgress)
                    .stroke(Color.appGreenMain, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: voiceManager.recordingProgress)
                
                // 录音按钮
                Button {
                    if voiceManager.isRecording {
                        voiceManager.stopRecording()
                    } else {
                        Task {
                            await voiceManager.startRecording()
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(voiceManager.isRecording ? Color.red : Color.appGreenMain)
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulseAnimation && voiceManager.isRecording ? 1.1 : 1.0)
                            .animation(
                                voiceManager.isRecording ?
                                    Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) :
                                    .default,
                                value: pulseAnimation
                            )
                        
                        Image(systemName: voiceManager.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }
                }
                .onChange(of: voiceManager.isRecording) { _, isRecording in
                    pulseAnimation = isRecording
                }
            }
            
            // 状态文字
            Text(recordingStatusText)
                .font(.headline)
                .foregroundColor(voiceManager.isRecording ? .red : .appBrown)
            
            // 提示
            Text("最长 2 秒，点击开始录音")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    private var recordingStatusText: String {
        if voiceManager.isRecording {
            let seconds = voiceManager.recordingProgress * 2.0
            return String(format: "录音中... %.1f 秒", seconds)
        } else {
            return "点击录音"
        }
    }
    
    // MARK: - 已录制预览
    
    private var recordedPreviewSection: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("已录制叫声")
                    .font(.headline)
                    .foregroundColor(.appBrown)
                Spacer()
            }
            
            HStack(spacing: 20) {
                // 播放按钮
                Button {
                    if voiceManager.isPlaying {
                        voiceManager.stopPlaying()
                    } else {
                        voiceManager.playVoice()
                    }
                } label: {
                    HStack {
                        Image(systemName: voiceManager.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title)
                        Text(voiceManager.isPlaying ? "停止" : "试听")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.appGreenMain)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.appGreenMain.opacity(0.15))
                    .cornerRadius(12)
                }
                
                // 重新录制按钮
                Button {
                    Task {
                        await voiceManager.startRecording()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                        Text("重录")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(12)
                }
                
                // 删除按钮
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(.red)
                        .padding(12)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 使用说明
    
    private var usageInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("叫声将用于")
                .font(.headline)
                .foregroundColor(.appBrown)
            
            VStack(alignment: .leading, spacing: 12) {
                UsageRow(icon: "bell.badge.fill", color: .orange, title: "每日遛狗提醒", description: "推送通知时播放")
                UsageRow(icon: "trophy.fill", color: .yellow, title: "成就解锁", description: "完成遛狗获得奖励时播放")
                UsageRow(icon: "chart.bar.fill", color: .blue, title: "排行榜名片", description: "其他用户可以听到你的狗叫")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - 使用说明行
private struct UsageRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 35)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

#Preview {
    VoiceRecordingView()
}
