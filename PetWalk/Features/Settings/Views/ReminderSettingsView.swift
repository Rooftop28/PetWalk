//
//  ReminderSettingsView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI

/// 提醒时间项（用于列表展示与增删）
private struct ReminderTimeRow: Identifiable {
    let id = UUID()
    var time: Date
}

/// 提醒设置视图
struct ReminderSettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var reminderEnabled: Bool = false
    @State private var reminderTimeRows: [ReminderTimeRow] = []
    @State private var showPermissionAlert = false
    @State private var isSaving = false
    
    private let maxReminderCount = 8
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        permissionCard
                        dailyReminderCard
                        if reminderEnabled && !reminderTimeRows.isEmpty {
                            notificationPreviewCard
                        }
                        infoSection
                    }
                    .padding()
                }
            }
            .navigationTitle("遛狗提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveAndDismiss()
                    }
                    .foregroundColor(.appGreenMain)
                    .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("保存中…")
                        .tint(.white)
                }
            }
            .onAppear { loadSettings() }
            .alert("需要通知权限", isPresented: $showPermissionAlert) {
                Button("去设置") { notificationManager.openSettings() }
                Button("取消", role: .cancel) { reminderEnabled = false }
            } message: {
                Text("请在设置中开启通知权限，以便接收遛狗提醒。")
            }
        }
    }
    
    // MARK: - 权限状态卡片
    
    private var permissionCard: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(notificationManager.isAuthorized ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: notificationManager.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                    .font(.system(size: 22))
                    .foregroundColor(notificationManager.isAuthorized ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("通知权限")
                    .font(.headline)
                    .foregroundColor(.appBrown)
                
                Text(notificationManager.isAuthorized ? "已开启" : "未开启")
                    .font(.caption)
                    .foregroundColor(notificationManager.isAuthorized ? .green : .orange)
            }
            
            Spacer()
            
            if !notificationManager.isAuthorized {
                Button("开启") {
                    Task {
                        let granted = await notificationManager.requestAuthorization()
                        if !granted {
                            showPermissionAlert = true
                        }
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.appGreenMain)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 每日提醒卡片
    
    private var dailyReminderCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("每日遛狗提醒")
                        .font(.headline)
                        .foregroundColor(.appBrown)
                    Text("每天在设定时间提醒你遛狗，可添加多个")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Toggle("", isOn: $reminderEnabled)
                    .labelsHidden()
                    .tint(.appGreenMain)
                    .onChange(of: reminderEnabled) { oldValue, newValue in
                        if newValue {
                            if !notificationManager.isAuthorized {
                                Task {
                                    let granted = await notificationManager.requestAuthorization()
                                    if !granted {
                                        reminderEnabled = false
                                        showPermissionAlert = true
                                    }
                                }
                            }
                            if reminderTimeRows.isEmpty {
                                reminderTimeRows = [ReminderTimeRow(time: defaultTime())]
                            }
                        }
                    }
            }
            .padding()
            
            if reminderEnabled {
                Divider()
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("提醒时间")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.appBrown)
                        Spacer()
                        if reminderTimeRows.count < maxReminderCount {
                            Button {
                                reminderTimeRows.append(ReminderTimeRow(time: defaultTime()))
                            } label: {
                                Label("添加", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.appGreenMain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    ForEach($reminderTimeRows) { $row in
                        HStack(spacing: 12) {
                            DatePicker(
                                "",
                                selection: $row.time,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            
                            if reminderTimeRows.count > 1 {
                                Button(role: .destructive) {
                                    reminderTimeRows.removeAll { $0.id == row.id }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.body)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 通知预览卡片
    
    private var notificationPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通知预览")
                .font(.headline)
                .foregroundColor(.appBrown)
            
            Text("每天将在以下 \(reminderTimeRows.count) 个时间收到提醒：")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(spacing: 8) {
                ForEach(reminderTimeRows.prefix(5)) { row in
                    Text(formatTime(row.time))
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appGreenMain.opacity(0.15))
                        .foregroundColor(.appGreenMain)
                        .clipShape(Capsule())
                }
                if reminderTimeRows.count > 5 {
                    Text("+\(reminderTimeRows.count - 5)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 10) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.appGreenMain)
                VStack(alignment: .leading, spacing: 2) {
                    Text("PetWalk 遛狗提醒")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("汪！该带我出去遛弯啦～ 🐕")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 说明文字
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("关于提醒")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            Text("• 可添加多个提醒时间，每天在这些时间收到通知\n• 通知文案会随机变化\n• 最多添加 \(maxReminderCount) 个提醒时间\n• 可随时关闭或删减")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 辅助方法
    
    private func defaultTime() -> Date {
        var c = DateComponents()
        c.hour = 18
        c.minute = 0
        return Calendar.current.date(from: c) ?? Date()
    }
    
    private func loadSettings() {
        reminderEnabled = dataManager.userData.dailyReminderEnabled
        let times = dataManager.userData.dailyReminderTimes
        if !times.isEmpty {
            reminderTimeRows = times.map { ReminderTimeRow(time: $0) }
        } else if dataManager.userData.dailyReminderEnabled {
            reminderTimeRows = [ReminderTimeRow(time: dataManager.userData.dailyReminderTime)]
        } else {
            reminderTimeRows = []
        }
    }
    
    private func saveSettings() async {
        let times = reminderTimeRows.map { $0.time }
        await notificationManager.updateDailyReminder(
            enabled: reminderEnabled,
            times: times
        )
    }
    
    private func saveAndDismiss() {
        isSaving = true
        Task {
            await saveSettings()
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 设置主页面（包含所有设置项入口）
struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showReminderSettings = false
    @State private var showEditProfile = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                List {
                    // 通知设置
                    Section {
                        Button {
                            showReminderSettings = true
                        } label: {
                            SettingsRow(
                                icon: "bell.fill",
                                iconColor: .orange,
                                title: "遛狗提醒",
                                subtitle: dataManager.userData.dailyReminderEnabled
                                    ? (dataManager.userData.dailyReminderTimes.count > 1
                                        ? "已开启 (\(dataManager.userData.dailyReminderTimes.count) 个)"
                                        : "已开启")
                                    : "未开启"
                            )
                        }
                    } header: {
                        Text("通知")
                    }
                    
                    // 个人资料
                    Section {
                        Button {
                            // 由于使用了 sheet，这里需要一个新的 state 变量，或者重用现有的机制
                            // 为了简单起见，我们在当前 View 增加一个状态变量
                            showEditProfile = true
                        } label: {
                            SettingsRow(
                                icon: "person.crop.circle.fill",
                                iconColor: .purple,
                                title: "修改称呼",
                                subtitle: "\(dataManager.userData.petName) & \(dataManager.userData.ownerNickname)"
                            )
                        }
                    } header: {
                        Text("个人资料")
                    }
                    
                    // 数据管理
                    Section {
                        SettingsRow(
                            icon: "icloud.fill",
                            iconColor: .blue,
                            title: "数据同步",
                            subtitle: "iCloud"
                        )
                        
                        SettingsRow(
                            icon: "square.and.arrow.up.fill",
                            iconColor: .green,
                            title: "导出数据",
                            subtitle: ""
                        )
                    } header: {
                        Text("数据")
                    }
                    
                    // 关于
                    Section {
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .gray,
                            title: "关于 PetWalk",
                            subtitle: "版本 1.0.0"
                        )
                        
                        SettingsRow(
                            icon: "star.fill",
                            iconColor: .yellow,
                            title: "给我们评分",
                            subtitle: ""
                        )
                    } header: {
                        Text("关于")
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(.appGreenMain)
                }
            }
            .sheet(isPresented: $showReminderSettings) {
                ReminderSettingsView()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
        }
    }
}

// MARK: - 设置行组件
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    ReminderSettingsView()
}
