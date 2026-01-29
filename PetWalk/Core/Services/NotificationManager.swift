//
//  NotificationManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import UserNotifications
import UIKit

/// 通知管理器 - 负责每日遛狗提醒和好友催促通知
@MainActor
class NotificationManager: NSObject, ObservableObject {
    // MARK: - 单例
    static let shared = NotificationManager()
    
    // MARK: - 发布的属性
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - 通知标识符
    private let dailyReminderIdentifierPrefix = "petwalk.daily.reminder."
    private let friendNudgeIdentifier = "petwalk.friend.nudge"
    private let maxDailyReminders = 16
    
    // MARK: - 通知文案
    private var dailyReminderMessages: [String] {
        let petName = DataManager.shared.userData.petName
        let ownerName = DataManager.shared.userData.ownerNickname
        return [
            "汪！该带我出去遛弯啦～ 🐕",
            "今天的骨头币还没赚呢，快出发！",
            "连续打卡中，别断签哦！🔥",
            "外面天气不错，一起去散步吧！☀️",
            "\(petName)已经在门口等你了！🐾",
            "今天的步数还是0，该动一动啦！",
            "遛狗时间到！让我们一起探索世界～",
            "\(petName)说：\(ownerName)，我想出去玩！",
            "成就等你来解锁，出发吧！🏆",
            "健康生活从遛狗开始！💪"
        ]
    }
    
    private let friendNudgeMessages: [String] = [
        "你的好友 %@ 提醒你：该遛狗啦！🐕",
        "%@ 催你出门遛狗了，快行动吧！",
        "%@ 说：别偷懒，带狗狗出去转转～",
        "叮！%@ 给你发来了遛狗提醒！",
        "%@ 问你：今天遛狗了吗？"
    ]
    
    // MARK: - 初始化
    private override init() {
        super.init()
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - 权限管理
    
    /// 检查通知权限状态
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    /// 请求通知权限
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            isAuthorized = granted
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("NotificationManager: 请求权限失败 - \(error)")
            return false
        }
    }
    
    // MARK: - 每日提醒
    
    /// 设置多个每日遛狗提醒
    func scheduleDailyReminders(at times: [Date]) async {
        // 确保有权限
        if !isAuthorized {
            let granted = await requestAuthorization()
            guard granted else { return }
        }
        
        // 拷贝需要的数据，以便在后台任务中使用
        let reminderTimes = Array(times.prefix(maxDailyReminders))
        let messages = self.dailyReminderMessages
        let prefix = self.dailyReminderIdentifierPrefix
        let maxCount = self.maxDailyReminders
        
        // 在后台任务中执行通知设置，避免阻塞主线程
        await Task.detached(priority: .userInitiated) {
            // 先取消旧的
            let identifiers = (0..<maxCount).map { "\(prefix)\($0)" }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            
            let calendar = Calendar.current
            
            // 批量添加新的
            for (index, time) in reminderTimes.enumerated() {
                let content = UNMutableNotificationContent()
                content.title = "PetWalk 遛狗提醒"
                // 注意：这里访问 `messages` 可能会有问题，因为它现在是计算属性
                // 但由于我们在 Task 开始前拷贝了 `messages`，所以上面的 `let messages = self.dailyReminderMessages` 其实已经捕获了当时的值
                // 只要 DataManager 在 MainActor 上是线程安全的（它是），那么在非 MainActor 访问它可能需要注意
                // 实际上 `dailyReminderMessages` 现在访问 DataManager，而 DataManager 是 @MainActor
                // 所以我们需要在这一行之前（在 MainActor 上）就获取好 messages
                content.body = messages.randomElement() ?? "该遛狗啦！"
                content.sound = .default
                content.badge = 1
                
                let components = calendar.dateComponents([.hour, .minute], from: time)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let identifier = "\(prefix)\(index)"
                
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    print("NotificationManager: 每日提醒已设置 [\(index)] - \(components.hour ?? 0):\(components.minute ?? 0)")
                } catch {
                    print("NotificationManager: 设置每日提醒失败 [\(index)] - \(error)")
                }
            }
        }.value
    }
    
    /// 取消所有每日提醒
    func cancelDailyReminders() {
        let prefix = self.dailyReminderIdentifierPrefix
        let maxCount = self.maxDailyReminders
        
        Task.detached {
            let identifiers = (0..<maxCount).map { "\(prefix)\($0)" }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            print("NotificationManager: 每日提醒已全部取消")
        }
    }
    
    /// 更新每日提醒设置（支持多个时间）
    func updateDailyReminder(enabled: Bool, times: [Date]) async {
        if enabled && !times.isEmpty {
            await scheduleDailyReminders(at: times)
        } else {
            cancelDailyReminders()
        }
        
        var userData = DataManager.shared.userData
        userData.dailyReminderEnabled = enabled
        userData.dailyReminderTimes = times
        if let first = times.first {
            userData.dailyReminderTime = first
        }
        DataManager.shared.updateUserData(userData)
    }
    
    // MARK: - 好友催促
    
    /// 发送好友催促通知
    /// 注意：这需要远程推送支持，目前仅模拟本地通知
    func sendFriendNudge(to friendId: String, friendName: String) async -> Bool {
        // 检查是否可以催促（每天限制一次）
        guard DataManager.shared.userData.canNudgeFriend(friendId) else {
            print("NotificationManager: 今天已经催促过该好友了")
            return false
        }
        
        // 更新催促记录
        var userData = DataManager.shared.userData
        userData.lastNudgedFriends[friendId] = Date()
        DataManager.shared.updateUserData(userData)
        
        // TODO: 这里应该调用后端 API 发送远程推送
        // 目前仅模拟成功
        print("NotificationManager: 已向好友 \(friendName) 发送催促通知")
        
        return true
    }
    
    /// 处理收到的好友催促通知（本地模拟）
    func handleFriendNudgeReceived(from friendName: String) {
        let content = UNMutableNotificationContent()
        content.title = "好友催促"
        let message = friendNudgeMessages.randomElement() ?? "%@ 提醒你遛狗了！"
        content.body = String(format: message, friendName)
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(friendNudgeIdentifier).\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        Task {
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
    
    // MARK: - 通知管理
    
    /// 清除所有通知角标
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    /// 获取待发送的通知列表
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    /// 打开系统设置
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 应用在前台时也显示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 处理通知点击
        let identifier = response.notification.request.identifier
        
        if identifier.hasPrefix("petwalk.daily.reminder") {
            // 点击每日提醒，可以跳转到首页开始遛狗
            print("NotificationManager: 用户点击了每日提醒")
        } else if identifier.hasPrefix("petwalk.friend.nudge") {
            // 点击好友催促
            print("NotificationManager: 用户点击了好友催促")
        }
        
        completionHandler()
    }
}
