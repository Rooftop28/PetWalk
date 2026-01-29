//
//  LiveSessionManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/29.
//

import Foundation
import CoreLocation
import Supabase

// 定义广播的数据结构
struct WalkPayload: Codable {
    let lat: Double
    let lon: Double
    let speed: Double // m/s
    let timestamp: TimeInterval
}

// 统计数据指令
struct StatsPayload: Codable {
    let type: String // "final_stats"
    let distance: Double
    let duration: TimeInterval
}

@MainActor
class LiveSessionManager: ObservableObject {
    static let shared = LiveSessionManager()
    
    // Supabase 客户端
    private var client: SupabaseClient?
    
    // 当前频道的引用
    private var channel: RealtimeChannelV2?
    
    // 当前房间号
    @Published var currentRoomCode: String?
    
    // 是否正在直播
    @Published var isBroadcasting = false
    
    // 是否正在观看
    @Published var isWatching = false
    
    // 观看时的对方位置
    @Published var remoteLocation: WalkPayload?
    
    // 观看时的连接状态
    @Published var connectionStatus: String = "未连接"
    
    // 直播结束标志
    @Published var sessionEnded = false
    
    // 最终统计数据 (Owner用)
    @Published var finalSessionStats: (distance: Double, duration: TimeInterval)?
    
    // 收到的赞数
    @Published var likesReceived = 0
    
    private init() {
        setupClient()
    }
    
    private func setupClient() {
        guard SupabaseConfig.isValid else {
            print("⚠️ Supabase 配置未完成，LiveSessionManager 无法工作")
            return
        }
        
        // 初始化客户端
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.apiKey
        )
    }
    
    // MARK: - Walker (主播) 方法
    
    /// 开始直播：生成房间号并订阅频道
    func startBroadcast() {
        guard let client = client else { return }
        
        // 重置状态
        self.sessionEnded = false
        self.likesReceived = 0
        
        // 1. 生成 6 位随机数字码
        let code = String(format: "%06d", Int.random(in: 0...999999))
        self.currentRoomCode = code
        
        // 2. 创建频道 "room_123456"
        let channelName = "room_\(code)"
        self.channel = client.channel(channelName) { config in 
            config.broadcast.receiveOwnBroadcasts = true 
            config.broadcast.acknowledgeBroadcasts = false
        }
        
        // 3. 订阅频道 (放入后台任务防止阻塞 UI)
        Task {
            await self.channel?.subscribe()
            await MainActor.run {
                self.isBroadcasting = true
                self.connectionStatus = "直播中"
                print("🎙️ 直播开始，房间号: \(code)")
            }
            
            // 监听指令 (例如点赞)
            if let channel = self.channel {
                let cmdChanges = channel.broadcastStream(event: "cmd")
                for await message in cmdChanges {
                    // 解析指令
                    if let dict = message["payload"] as? [String: Any] ?? message as? [String: Any],
                       let type = dict["type"] as? String {
                        if type == "like" {
                            await MainActor.run {
                                self.likesReceived += 1
                                print("❤️ 收到赞! 当前: \(self.likesReceived)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// 发送位置更新 (Broadcast)
    func broadcastLocation(_ location: CLLocation) {
        guard isBroadcasting, let channel = channel else { return }
        
        let payload = WalkPayload(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            speed: max(0, location.speed),
            timestamp: Date().timeIntervalSince1970
        )
        
        Task {
            do {
                try await channel.broadcast(event: "loc", message: payload)
                await MainActor.run {
                    self.connectionStatus = "发送中 🟢 \(Date().formatted(date: .omitted, time: .standard))"
                }
            } catch {
                print("❌ 发送失败: \(error)")
                await MainActor.run {
                    self.connectionStatus = "发送失败 🔴 \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// 发送结束信号
    private func broadcastStopSignal() async {
        guard let channel = channel else { return }
        do {
            let cmd = CommandPayload(type: "stop")
            try await channel.broadcast(event: "cmd", message: cmd)
            print("🛑 发送结束信号成功: \(cmd)")
        } catch {
            print("❌ 发送结束信号失败: \(error)")
        }
    }
    
    /// 停止直播
    func stopBroadcast() {
        Task {
            // 先发送结束信号
            await broadcastStopSignal()
            
            // 延长等待时间，确保信号发出
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            
            if let channel = channel {
                await client?.removeChannel(channel)
            }
            
            await MainActor.run {
                self.channel = nil
                self.currentRoomCode = nil
                self.isBroadcasting = false
                self.connectionStatus = "直播结束"
                print("🛑 直播停止")
            }
        }
    }
    
    // ...
    
    /// 发送最终统计数据
    func broadcastFinalStats(distance: Double, duration: TimeInterval) async {
        guard let channel = channel else { return }
        do {
            let stats = ["distance": distance, "duration": duration]
            let statsData = try JSONEncoder().encode(stats)
            // 将 statsData 转为 JSON 对象以便发送
             if let dict = try JSONSerialization.jsonObject(with: statsData) as? [String: Any] {
                 let cmd = CommandPayload(type: "final_stats", data: dict)
                 try await channel.broadcast(event: "cmd", message: cmd)
                 print("📊 发送最终统计: \(stats)")
             }
        } catch {
            print("❌ 发送最终统计失败: \(error)")
        }
    }
    
    // ...
    
    // 内部结构体用于通用指令
    struct CommandPayload: Codable {
        let type: String
        var data: [String: Any]? // 支持附加数据
        
        enum CodingKeys: String, CodingKey {
            case type, data
        }
        
        init(type: String, data: [String: Any]? = nil) {
            self.type = type
            self.data = data
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(String.self, forKey: .type)
            // Any 不能直接 decode，需要根据实际情况手动处理或者忽略
            // 这里为了让 Codable 编译通过，我们暂不 decode data
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            // Skip encoding data for now as it requires manual Any handling
        }
    }
    
    // MARK: - Owner (观众) 方法
    
    /// 加入房间 (观看直播)
    func joinSession(code: String) {
        guard let client = client else { return }
        
        // 重置状态
        self.remoteLocation = nil
        self.currentRoomCode = code
        self.isWatching = true
        self.sessionEnded = false
        self.finalSessionStats = nil
        self.connectionStatus = "正在连接..."
        
        let channelName = "room_\(code)"
        self.channel = client.channel(channelName) { config in 
            config.broadcast.receiveOwnBroadcasts = true 
            config.broadcast.acknowledgeBroadcasts = false
        }
        
        let myChannel = self.channel
        
        // 监听 "loc" 事件
        Task {
            guard let myChannel = myChannel else { return }
            
            // 订阅并监听广播消息 (位置)
            let locChanges = myChannel.broadcastStream(event: "loc")
            // 订阅并监听广播消息 (指令)
            let cmdChanges = myChannel.broadcastStream(event: "cmd")
            
            // 只要订阅成功就开始接收
            await myChannel.subscribe()
            self.connectionStatus = "已连接"
            print("👀 已加入房间: \(code)")
            
            // 启动指令监听
            Task {
                for await message in cmdChanges {
                    do {
                        // 同样的信封解包逻辑
                        let actualData: Data
                        if let nestedPayload = message["payload"] {
                            actualData = try JSONEncoder().encode(nestedPayload)
                        } else {
                            actualData = try JSONEncoder().encode(message)
                        }
                        
                        let cmd = try JSONDecoder().decode(CommandPayload.self, from: actualData)
                        
                            
                            if cmd.type == "stop" {
                                print("🛑 收到结束指令")
                                await MainActor.run {
                                    self.sessionEnded = true
                                    self.connectionStatus = "直播已结束"
                                }
                            } else if cmd.type == "final_stats" {
                                 let stats = try JSONDecoder().decode(StatsPayload.self, from: actualData)
                                 await MainActor.run {
                                     self.finalSessionStats = (stats.distance, stats.duration)
                                 }
                            }
                    } catch {
                        print("⚠️ 解析指令失败: \(error)")
                    }
                }
            }
            
            // 处理位置消息流
            for await message in locChanges {
                // message 是 Envelope, 实际数据在 "payload" 字段里 (如果是 JSONObject)
                do {
                    // 1. 尝试获取 nested payload
                    let actualData: Data
                    if let nestedPayload = message["payload"] {
                        actualData = try JSONEncoder().encode(nestedPayload)
                    } else {
                        // 如果没有 payload 字段，尝试直接解析 (兼容性)
                        actualData = try JSONEncoder().encode(message)
                    }
                    
                    let payload = try JSONDecoder().decode(WalkPayload.self, from: actualData)
                    
                    await MainActor.run {
                        self.remoteLocation = payload
                        self.connectionStatus = "收到数据 🟢 \(Date().formatted(date: .omitted, time: .standard))"
                    }
                } catch {
                    print("解析广播数据失败: \(error)")
                    // 尝试打印原始数据以便调试
                    await MainActor.run {
                         self.connectionStatus = "解析失败 ⚠️ \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    /// 发送点赞
    func sendLike() {
        guard let channel = channel else { return }
        Task {
            do {
                let cmd = CommandPayload(type: "like")
                try await channel.broadcast(event: "cmd", message: cmd)
                print("👍 发送赞")
            } catch {
                print("❌ 发送赞失败: \(error)")
            }
        }
    }

    /// 退出房间
    func leaveSession() {
        let channelToRemove = self.channel
        
        // 立即清理本地状态
        self.channel = nil
        self.currentRoomCode = nil
        self.isWatching = false
        self.remoteLocation = nil
        self.connectionStatus = "未连接"
        print("👋 退出房间")
        
        Task {
            if let channel = channelToRemove {
                await client?.removeChannel(channel)
            }
        }
    }
}
