//
//  HomeView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//
import SwiftUI
import PhotosUI

struct HomeView: View {
    // 引入 ViewModel
    @StateObject private var viewModel = PetViewModel()
    
    // 引入健康数据管理器 (全天数据)
    @StateObject private var healthManager = HealthManager()
    
    // 引入遛狗会话管理器 (单次数据)
    @ObservedObject private var walkManager = WalkSessionManager.shared
    
    // 引入数据管理器 (用于获取上次遛狗时间)
    @ObservedObject private var dataManager = DataManager.shared
    
    // 相册选择器的状态
    @State private var selectedItem: PhotosPickerItem? // 宠物
    @State private var selectedAvatarItem: PhotosPickerItem? // 人物头像
    
    // 动画状态
    @State private var isDogVisible = false
    @State private var isAnimating = false // 统一控制循环动画
    
    // 计算当前心情
    var currentMood: PetMood {
        PetStatusManager.shared.calculateMood(lastWalkDate: dataManager.userData.lastWalkDate)
    }
    
    // 设定一个每日目标
    let dailyTarget: Double = 3.0
    
    // 计算今日遛狗总距离（只统计 App 内记录的遛狗数据）
    var todayWalkDistance: Double {
        let calendar = Calendar.current
        let today = Date()
        let todayDay = calendar.component(.day, from: today)
        
        return dataManager.records
            .filter { $0.day == todayDay }  // 使用 day 字段比较
            .reduce(0.0) { $0 + $1.distance }
    }
    
    // Debug 辅助函数
    #if DEBUG
    func updateMood(_ mood: PetMood) {
        PetStatusManager.shared.debugUpdateMood(mood, dataManager: dataManager)
        
        // 更新跳动状态
        isAnimating = false // 先重置
        withAnimation {
            isAnimating = true // 触发新动画
        }
    }
    
    // 设置模拟天气（用于测试天气成就）
    func setTestWeather(_ condition: WeatherCondition, temperature: Double) {
        WeatherManager.shared.setMockWeather(condition: condition, temperature: temperature)
        walkManager.currentWeather = WeatherManager.shared.currentWeather
        print("🐛 Debug: 设置天气为 \(condition.displayName), \(Int(temperature))°C")
    }
    #endif
    
    // 处理头像选择
    func processAvatarSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            // 1. 加载图片
            if let data = try? await item.loadTransferable(type: Data.self),
               let originalImage = UIImage(data: data) {
                 
                 // 2. 直接保存原图 (无需抠图)
                 await MainActor.run {
                     AvatarManager.shared.saveUserAvatar(originalImage)
                 }
            }
        }
    }
    
    // 是否显示结算页
    @State private var showSummary = false
    
    // 是否显示奖励商店页
    @State private var showShop = false
    
    // 是否显示头像编辑器
    @State private var showAvatarCreator = false
    
    // 遛狗开始时间（用于成就检测）
    @State private var walkStartTime: Date = Date()
    
    // 遛狗会话数据（用于传递给结算页）
    @State private var walkSessionData: WalkSessionData?
    
    // 头像管理器
    @ObservedObject private var avatarManager = AvatarManager.shared
    
    // 直播管理器 (新增)
    @StateObject private var liveManager = LiveSessionManager.shared
    @State private var showLiveMonitor = false
    
    var body: some View {
        ZStack {
            // 背景色 (仅在非地图模式下显示)
            if !walkManager.isWalking {
                Color.appBackground.ignoresSafeArea()
            }
            
            // --- 状态分支 ---
            if walkManager.isWalking {
                // A. 遛狗中：全屏地图 + 悬浮控制板
                walkingModeView
            } else {
                // B. 待机中：原来的主页
                idleModeView
            }
        }
        // 监听 App 回到前台，刷新健康数据
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await healthManager.fetchTodayStats()
            }
        }
        // 弹出结算页
        .sheet(isPresented: $showSummary) {
            if let sessionData = walkSessionData {
                WalkSummaryView(
                    sessionData: sessionData,
                    // 将 CoreLocation 坐标转换为我们的 Codable 结构体
                    routeCoordinates: walkManager.locationService.routeCoordinates.map { 
                        RoutePoint(lat: $0.latitude, lon: $0.longitude) 
                    },
                    onFinish: {
                        showSummary = false
                        walkSessionData = nil
                    }
                )
            }
        }
        // 弹出奖励商店页
        .sheet(isPresented: $showShop) {
            RewardShopView()  // 替换为奖励商店
        }
        // 弹出云遛狗监控页
        .sheet(isPresented: $showLiveMonitor) {
            LiveMonitorView()
                .presentationDragIndicator(.visible) // 显示下拉指示条
        }

    }
    
    // MARK: - 待机模式视图 (原来的 UI)
    var idleModeView: some View {
        VStack(spacing: 0) {
            // Header
            ZStack(alignment: .leading) {
                // 1. 左侧标题 (位置绝对独立，确保与其他页面高度一致)
                #if DEBUG
                Menu {
                    ForEach(PetMood.allCases, id: \.self) { mood in
                        Button(mood.debugTitle) { updateMood(mood) }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("PetWalk")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(.appBrown)
                        Image(systemName: "ladybug.fill") // Debug icon
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.6))
                    }
                }
                #else
                Text("PetWalk")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.appBrown)
                #endif
                
                // 2. 右侧骨头币按钮
                HStack {
                    Spacer()
                    Button(action: { showShop = true }) {
                        HStack(spacing: 5) {
                            Text("🦴")
                                .font(.title2)
                            Text("\(dataManager.userData.totalBones)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.appBrown)
                                .contentTransition(.numericText(value: Double(dataManager.userData.totalBones)))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.05), radius: 5)
                    }
                }
            }
            .padding(.top, 10) // 添加小的顶部间距，与其他页面保持一致
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 中间核心交互区
            ZStack {
                // 1. 背景光晕
                BlobBackgroundView()
                    .frame(height: 350)
                    .offset(y: -20)
                
                // 2. 狗狗贴纸 (中间层) - 向左偏移给用户头像留空间
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack {
                        if viewModel.isProcessing {
                            ProgressView()
                                .scaleEffect(2)
                                .tint(.appBrown)
                        } else {
                            if let image = viewModel.currentPetImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                // ⚠️ 确保 Assets 里有一张叫 "tongtong" 的图
                                Image("tongtong")
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                    }
                    .frame(height: 280)
                    .shadow(color: .white, radius: 0, x: 2, y: 0)
                    .shadow(color: .white, radius: 0, x: -2, y: 0)
                    .shadow(color: .white, radius: 0, x: 0, y: 2)
                    .shadow(color: .white, radius: 0, x: 0, y: -2)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
                    // 状态动画：兴奋/开心时跳动，期待时歪头，郁闷时压扁
                    .rotationEffect(.degrees(currentMood.anim.rotationAngle))
                    .scaleEffect(x: 1.0, y: currentMood.anim.scaleY)
                    .offset(y: (isAnimating ? currentMood.anim.bounceHeight : 0) + currentMood.anim.offsetY)
                    .animation(currentMood.anim.timing, value: isAnimating)
                    .scaleEffect(isDogVisible ? 1.0 : 0.8)
                    .opacity(isDogVisible ? 1.0 : 0)
                }
                .offset(x: -30) // 向左偏移，给用户头像留空间
                .onChange(of: selectedItem) { _, newItem in
                    viewModel.selectAndProcessImage(from: newItem)
                }
                
                // 2.5 状态贴纸 (Overlay) - 跟随宠物偏移
                if let emoji = currentMood.overlay.emoji {
                    let config = currentMood.overlay
                    Text(emoji)
                        .font(.system(size: 40))
                        // 基础位置 + 动画位移
                        .offset(x: config.offset.width - 30, // 跟随宠物偏移
                                y: config.offset.height + (isAnimating ? config.offsetYTarget : 0))
                        // 动画缩放
                        .scaleEffect(isAnimating ? config.scaleTarget : 1.0)
                        // 动画透明度 (叠加: isDogVisible控制显示, opacityTarget控制闪烁/渐隐)
                        .opacity(isDogVisible ? (isAnimating ? config.opacityTarget : 1.0) : 0)
                        .animation(config.animation, value: isAnimating)
                        .id(currentMood) // 强制刷新
                }
                
                // 2.6 用户头像 + 称号 - 右下角
                PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                    UserAvatarView(
                        onTap: nil, // 禁用内部点击，交由 PhotosPicker 处理
                        avatarSize: 70,
                        showTitle: true
                    )
                    .contentShape(Rectangle()) // 扩大点击区域，确保点击响应灵敏
                }
                .offset(x: 120, y: 80) // 右下方位置 (向右微调)
                .onChange(of: selectedAvatarItem) { _, newItem in
                    processAvatarSelection(newItem)
                }
                .opacity(isDogVisible ? 1 : 0)
                .animation(.easeIn.delay(0.8), value: isDogVisible)
                
                // 3. 气泡 (最上层) - 调整位置
                SpeechBubbleView(text: currentMood.dialogue.text)
                    .offset(x: 50, y: -140) // 调整气泡位置
                    .opacity(isDogVisible ? 1 : 0)
                    .animation(.easeIn.delay(0.6), value: isDogVisible)
            }
            .onAppear {
                // 入场动画 (只执行一次)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0)) {
                    isDogVisible = true
                }
                
                // 启动状态动画
                isAnimating = true
            }
            
            Spacer()
            
            // 仪表盘
            dashboardSection
            
            // 底部留白给 TabBar (因为现在 TabBar 是悬浮在上面的)
            Spacer().frame(height: 80)
        }
    }
    
    // MARK: - 遛狗模式视图 (新功能)
    var walkingModeView: some View {
        ZStack(alignment: .bottom) {
            // 1. 地图背景
            WalkMapView(
                locationManager: walkManager.locationService,
                petImage: viewModel.currentPetImage ?? UIImage(named: "tongtong")
            )
            .ignoresSafeArea()
            
            // DEBUG: 天气调试按钮 (左上角)
            #if DEBUG
            VStack {
                HStack {
                    Menu {
                        Section("设置天气条件") {
                            Button("☀️ 晴天 25°C") { setTestWeather(.sunny, temperature: 25) }
                            Button("☁️ 多云 20°C") { setTestWeather(.cloudy, temperature: 20) }
                            Button("🌧 雨天 18°C") { setTestWeather(.rainy, temperature: 18) }
                            Button("❄️ 雪天 -5°C") { setTestWeather(.snowy, temperature: -5) }
                            Button("🌫 雾天 10°C") { setTestWeather(.foggy, temperature: 10) }
                        }
                        Section("极端温度测试") {
                            Button("🥶 零下 -3°C") { setTestWeather(.cloudy, temperature: -3) }
                            Button("🥵 高温 36°C") { setTestWeather(.sunny, temperature: 36) }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: walkManager.currentWeather?.condition.iconSymbol ?? "cloud.fill")
                            if let weather = walkManager.currentWeather {
                                Text("\(Int(weather.temperature))°C")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            } else {
                                Text("天气")
                                    .font(.caption)
                            }
                            Image(systemName: "ladybug.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                        }
                        .foregroundColor(.appBrown)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(radius: 3)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                Spacer()
            }
            #endif
            
            // 2. 悬浮数据面板
            VStack(spacing: 20) {
                // 直播控制栏 (新增)
                if !liveManager.isBroadcasting {
                    Button(action: {
                        liveManager.startBroadcast()
                    }) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("开启直播")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 2)
                    }
                    .padding(.top, -10) // 调整位置
                } else {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .opacity(isAnimating ? 1 : 0.5)
                            .animation(.easeInOut(duration: 0.8).repeatForever(), value: isAnimating)
                        
                        Text("直播中: \(liveManager.currentRoomCode ?? "Error")")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        // 复制按钮
                        Button(action: {
                            if let code = liveManager.currentRoomCode {
                                UIPasteboard.general.string = code
                            }
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            liveManager.stopBroadcast()
                        }) {
                            Image(systemName: "powersleep")
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.appGreenMain.opacity(0.9))
                    .cornerRadius(20)
                    .padding(.top, -20)
                }
                
                HStack(spacing: 40) {
                    // 计时
                    VStack(spacing: 5) {
                        Text("时长")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(walkManager.formattedDuration)
                            .font(.system(size: 32, weight: .heavy, design: .monospaced))
                            .foregroundColor(.appBrown)
                    }
                    
                    // 距离
                    VStack(spacing: 5) {
                        Text("距离(km)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "%.2f", walkManager.distance))
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.appBrown)
                    }
                }
                
                // 结束按钮
                Button(action: {
                    withAnimation {
                        // 结束遛狗并获取会话数据
                        walkSessionData = walkManager.stopWalk()
                        showSummary = true
                    }
                }) {
                    Text("结束遛狗")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.red.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(radius: 5)
                }
            }
            .padding(24)
            .background(
                Color.white
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 40) // 避开 Home Indicator
        }
        .transition(.move(edge: .bottom)) // 进场动画
    }
    
    // 把 dashboardSection 拆出来让代码更整洁
    var dashboardSection: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle().stroke(Color.appGreenMain.opacity(0.2), lineWidth: 15)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(todayWalkDistance / dailyTarget, 1.0)))
                    .stroke(
                        LinearGradient(colors: [.appGreenMain, .appGreenDark], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: todayWalkDistance)
                
                VStack(spacing: 5) {
                    Text("今日目标").font(.system(size: 14, weight: .medium)).foregroundColor(.appBrown.opacity(0.6))
                    
                    Text(String(format: "%.1fkm", todayWalkDistance))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.appBrown)
                        .contentTransition(.numericText(value: todayWalkDistance))
                    
                    Text("/ \(Int(dailyTarget))km").font(.system(size: 14, weight: .medium)).foregroundColor(.appBrown.opacity(0.6))
                }
            }
            .frame(width: 160, height: 160)
            
            Button(action: {
                // 点击开始遛狗
                walkStartTime = Date()  // 记录开始时间
                withAnimation {
                    walkManager.startWalk()
                }
            }) {
                HStack {
                    Image(systemName: "pawprint.fill")
                    Text("GO! 出发遛弯")
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(LinearGradient(colors: [.appGreenMain, .appGreenDark], startPoint: .leading, endPoint: .trailing))
                .clipShape(Capsule())
                .shadow(color: .appGreenDark.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 50)
            
            // 云遛狗入口 (新增)
            Button(action: { showLiveMonitor = true }) {
                HStack {
                    Image(systemName: "cloud.fill")
                    Text("加入云遛狗")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appBrown.opacity(0.6))
            }
        }
        .padding(.bottom, 30)
    }
}

// 预览视图
#Preview {
    HomeView()
}
