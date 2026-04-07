//
//  FeatureFlags.swift
//  PetWalk
//
//  V1 上线功能开关 — 设为 true 即可恢复对应功能
//

import Foundation

enum FeatureFlags {
    /// Ready Player Me 用户形象
    static let enableAvatar = false
    
    /// 实时直播 / 云遛狗 (Supabase Realtime)
    static let enableLiveWalk = false
    
    /// 好友催促推送
    static let enableFriendNudge = false
    
    /// 叫声录制 / 上传 (Supabase Storage)
    static let enableVoiceRecording = false
    
    /// 排行榜 (Supabase + Game Center)
    static let enableLeaderboard = false
    
    /// 云同步 (Supabase)
    static let enableCloudSync = false
    
    /// Game Center 集成
    static let enableGameCenter = false
    
    /// 称号系统
    static let enableTitleSystem = false
}
