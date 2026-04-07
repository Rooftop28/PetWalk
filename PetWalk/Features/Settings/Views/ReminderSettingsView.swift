//
//  ReminderSettingsView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI
import PhotosUI

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
        .glassCard(cornerRadius: 18)
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
        .glassCard(cornerRadius: 18)
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
        .glassCard(cornerRadius: 18)
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
    @ObservedObject var voiceManager = VoiceRecordingManager.shared
    @ObservedObject var authService = AuthService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showReminderSettings = false
    @State private var showEditProfile = false
    @State private var showPetProfileSetup = false
    @State private var showVoiceRecording = false
    @State private var showAbout = false
    @State private var showCopiedToast = false
    @State private var showRestoreSheet = false
    @State private var selectedPetPhotoItem: PhotosPickerItem?
    @State private var isPetPhotoProcessing = false
    @ObservedObject private var petViewModel = PetViewModel.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                List {
                    // 账号信息 (V2: enableCloudSync)
                    if FeatureFlags.enableCloudSync {
                        Section {
                            HStack {
                                Image(systemName: "person.badge.key.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                    .frame(width: 30, height: 30)
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                
                                Text("用户 ID")
                                
                                Spacer()
                                
                                if let userId = authService.currentUserId {
                                    Text(userId.prefix(8) + "...")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.gray)
                                    
                                    Button {
                                        UIPasteboard.general.string = userId
                                        showCopiedToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            showCopiedToast = false
                                        }
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                            .foregroundColor(.appGreenMain)
                                    }
                                } else {
                                    Text("未登录")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            Button {
                                showRestoreSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.green)
                                        .frame(width: 30, height: 30)
                                        .background(Color.green.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    
                                    Text("从其他设备恢复账号")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                        } header: {
                            Text("账号")
                        } footer: {
                            Text("用户 ID 用于数据同步。跨设备（包括安卓）恢复数据时，请复制 ID 并在新设备上输入。")
                        }
                    }
                    
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
                    
                    // 个人资料 & 宠物档案
                    Section {
                        // 更换宠物照片
                        PhotosPicker(selection: $selectedPetPhotoItem, matching: .images) {
                            HStack(spacing: 15) {
                                ZStack {
                                    if let petImage = petViewModel.currentPetImage {
                                        Image(uiImage: petImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 30, height: 30)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } else {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.appGreenMain)
                                            .frame(width: 30, height: 30)
                                            .background(Color.appGreenMain.opacity(0.15))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("更换宠物照片")
                                        .foregroundColor(.primary)
                                    if isPetPhotoProcessing {
                                        Text("抠图处理中…")
                                            .font(.caption)
                                            .foregroundColor(.appGreenMain)
                                    } else {
                                        Text(petViewModel.currentPetImage != nil ? "已设置" : "选择照片自动抠图")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                if isPetPhotoProcessing {
                                    ProgressView()
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .onChange(of: selectedPetPhotoItem) { _, newItem in
                            guard let item = newItem else { return }
                            isPetPhotoProcessing = true
                            petViewModel.selectAndProcessImage(from: item)
                        }
                        .onChange(of: petViewModel.isProcessing) { _, isProcessing in
                            if !isProcessing {
                                isPetPhotoProcessing = false
                            }
                        }
                        
                        // 基础称呼 (EditProfileView)
                        Button {
                            showEditProfile = true
                        } label: {
                            SettingsRow(
                                icon: "person.crop.circle.fill",
                                iconColor: .purple,
                                title: "修改称呼",
                                subtitle: "\(dataManager.userData.petName) & \(dataManager.userData.ownerNickname)"
                            )
                        }
                        
                        // 宠物档案 (PetProfileSetupView)
                        NavigationLink(
                            destination: PetProfileSetupView(onComplete: {
                                showPetProfileSetup = false
                            }),
                            isActive: $showPetProfileSetup
                        ) {
                            SettingsRow(
                                icon: "doc.text.fill",
                                iconColor: .appBrown,
                                title: "宠物档案 (AI 狗设)",
                                subtitle: dataManager.userData.petProfile.breed.isEmpty ? "未设置" : dataManager.userData.petProfile.breed,
                                showChevron: false // NavigationLink adds its own chevron
                            )
                        }
                        
                        // 狗叫声录制 (V2: enableVoiceRecording)
                        if FeatureFlags.enableVoiceRecording {
                            Button {
                                showVoiceRecording = true
                            } label: {
                                SettingsRow(
                                    icon: "waveform.circle.fill",
                                    iconColor: .pink,
                                    title: "录制叫声",
                                    subtitle: voiceManager.hasRecordedVoice ? "已录制" : "未录制"
                                )
                            }
                        }
                    } header: {
                        Text("档案管理")
                    }
                    
                    // 日记设置
                    Section {
                        Toggle(isOn: Binding(
                            get: { dataManager.userData.aiDiaryEnabled },
                            set: { newValue in
                                var userData = dataManager.userData
                                userData.aiDiaryEnabled = newValue
                                dataManager.updateUserData(userData)
                            }
                        )) {
                            HStack(spacing: 15) {
                                Image(systemName: "text.book.closed.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.appGreenMain)
                                    .frame(width: 30, height: 30)
                                    .background(Color.appGreenMain.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI 狗狗日记")
                                        .foregroundColor(.primary)
                                    Text("遛狗结束后自动生成狗狗视角日记")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .tint(.appGreenMain)
                    } header: {
                        Text("日记功能")
                    } footer: {
                        Text("关闭后，遛狗结束时可以手动写日志记录")
                    }
                    
                    // 数据管理 (V2: enableCloudSync)
                    if FeatureFlags.enableCloudSync {
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
            .sheet(isPresented: $showVoiceRecording) {
                VoiceRecordingView()
            }
            .sheet(isPresented: $showRestoreSheet) {
                RestoreAccountSheet()
            }
            .sheet(isPresented: $petViewModel.showConfirmation) {
                PetPhotoConfirmView()
                    .interactiveDismissDisabled()
            }
            .overlay {
                if showCopiedToast {
                    VStack {
                        Spacer()
                        Text("已复制到剪贴板")
                            .font(.caption)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .padding(.bottom, 50)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: showCopiedToast)
                }
            }
        }
    }
}

// MARK: - 恢复账号 Sheet
struct RestoreAccountSheet: View {
    @ObservedObject var authService = AuthService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var inputUUID: String = ""
    @State private var isRestoring = false
    @State private var restoreError: String?
    @State private var showRestoreConfirm = false
    @State private var showRestoreSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 说明
                VStack(alignment: .leading, spacing: 12) {
                    Label("跨设备恢复", systemImage: "iphone.and.arrow.forward")
                        .font(.headline)
                    
                    Text("如果你在其他设备（iOS/Android）上已有账号，可以输入该设备的用户 ID 来恢复数据。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("⚠️ 恢复后，当前设备的数据将被覆盖。")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 输入框
                VStack(alignment: .leading, spacing: 8) {
                    Text("用户 ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("输入完整的用户 ID", text: $inputUUID)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // 粘贴按钮
                    Button {
                        if let clipboardString = UIPasteboard.general.string {
                            inputUUID = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    } label: {
                        Label("从剪贴板粘贴", systemImage: "doc.on.clipboard")
                            .font(.caption)
                    }
                }
                
                // 错误提示
                if let error = restoreError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // 恢复按钮
                Button {
                    showRestoreConfirm = true
                } label: {
                    HStack {
                        if isRestoring {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(isRestoring ? "恢复中..." : "恢复账号")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidUUID ? Color.appGreenMain : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isValidUUID || isRestoring)
            }
            .padding()
            .navigationTitle("恢复账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("确认恢复", isPresented: $showRestoreConfirm) {
                Button("恢复", role: .destructive) {
                    Task {
                        await performRestore()
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("恢复后，当前设备的本地数据将被覆盖。确定要继续吗？")
            }
            .alert("恢复成功", isPresented: $showRestoreSuccess) {
                Button("好的") {
                    dismiss()
                }
            } message: {
                Text("账号数据已恢复，请重启 App 以加载完整数据。")
            }
        }
    }
    
    // MARK: - UUID 验证
    private var isValidUUID: Bool {
        let trimmed = inputUUID.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count == 36 {
            return UUID(uuidString: trimmed) != nil
        } else if trimmed.count == 32 {
            let formatted = formatUUID(trimmed)
            return UUID(uuidString: formatted) != nil
        }
        return false
    }
    
    private func formatUUID(_ input: String) -> String {
        var result = input.uppercased()
        result.insert("-", at: result.index(result.startIndex, offsetBy: 8))
        result.insert("-", at: result.index(result.startIndex, offsetBy: 13))
        result.insert("-", at: result.index(result.startIndex, offsetBy: 18))
        result.insert("-", at: result.index(result.startIndex, offsetBy: 23))
        return result
    }
    
    // MARK: - 执行恢复
    private func performRestore() async {
        isRestoring = true
        restoreError = nil
        
        let trimmed = inputUUID.trimmingCharacters(in: .whitespacesAndNewlines)
        var uuidString = trimmed
        
        if trimmed.count == 32 {
            uuidString = formatUUID(trimmed)
        }
        
        do {
            try await authService.restoreAccount(withUUID: uuidString)
            await CloudSyncManager.shared.sync()
            
            isRestoring = false
            showRestoreSuccess = true
            inputUUID = ""
            
        } catch {
            isRestoring = false
            restoreError = error.localizedDescription
        }
    }
}

// MARK: - 设置行组件
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var showChevron: Bool = true // Default to true for backward compatibility
    
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
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    ReminderSettingsView()
}
